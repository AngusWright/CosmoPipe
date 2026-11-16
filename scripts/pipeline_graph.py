#!/usr/bin/env python3
"""Build an offline pipeline viewer from metadata recorded during construction."""

import argparse
from dataclasses import dataclass
import html
import json
import os
from pathlib import Path
import re
import tempfile


@dataclass(frozen=True)
class Event:
    kind: str
    key: str
    token: str
    a: str
    b: str
    c: str
    d: str
    status: str


def read_events(path):
    fields = Path(path).read_bytes().split(b"\0")
    if fields[-1] != b"" or (len(fields) - 1) % 8:
        raise ValueError("Incomplete pipeline graph event record")
    fields = [field.decode("utf-8") for field in fields[:-1]]
    return [Event(*fields[i:i + 8]) for i in range(0, len(fields), 8)]


def token_parts(token):
    name, separator, number = token.rpartition("=")
    if not separator:
        raise ValueError(f"Unnumbered pipeline token: {token!r}")
    return name, number


def event_kind(token):
    return {
        "@": "select", "!": "store", "-": "delete", "%": "rename",
        "~": "export", "+": "variable",
    }.get(token[:1], "script")


def build_groups(events):
    roots = [event for event in events if event.kind == "root"]
    plans = [event for event in events if event.kind == "plan"]
    if len(roots) != 1 or len(plans) != 1:
        raise ValueError("Graph trace needs exactly one root and one expanded plan")
    expansions = {}
    for event in events:
        if event.kind == "group":
            if event.key in expansions:
                raise ValueError(f"Duplicate subroutine invocation {event.key}")
            expansions[event.key] = event
    groups = [{
        "id": "root", "label": roots[0].token, "number": "", "parent": None,
        "children": [], "variables": [], "actions": [], "start": 1, "end": 0,
    }]
    leaves = []
    visited = set()

    def walk(tokens, owner, depth=0):
        if depth > 100:
            raise ValueError("Pipeline graph subroutine nesting exceeds 100 levels")
        for token in tokens.split():
            if token == "RESUME":
                continue
            name, number = token_parts(token)
            if name.startswith("."):
                if number not in expansions or number in visited:
                    raise ValueError(f"Missing or recursive subroutine invocation {number}")
                visited.add(number)
                expansion = expansions[number]
                group = {
                    "id": f"g{number}", "label": expansion.token, "number": number,
                    "parent": owner["id"], "children": [], "variables": [],
                    "actions": [], "start": len(leaves) + 1, "end": len(leaves),
                }
                owner["children"].append(group["id"])
                groups.append(group)
                walk(expansion.a, group, depth + 1)
                group["end"] = len(leaves)
            else:
                leaves.append((token, owner["id"]))

    walk(roots[0].a, groups[0])
    groups[0]["end"] = len(leaves)
    if visited != set(expansions):
        raise ValueError("Graph trace contains unused subroutine expansions")
    plan = [token for token in plans[0].a.split() if token != "RESUME"]
    if len(plan) != len(leaves):
        raise ValueError("Expanded pipeline and subroutine trace have different lengths")
    for actual, (expected, _) in zip(plan, leaves):
        actual_name, actual_number = token_parts(actual)
        expected_name, expected_number = token_parts(expected)
        if (actual_number != expected_number or
                event_kind(actual_name) != event_kind(expected_name) or
                (event_kind(actual_name) == "script" and actual_name != expected_name)):
            raise ValueError(f"Subroutine trace does not match constructed step {actual}")
    return roots[0].token, groups, plan, [owner for _, owner in leaves], plans[0]


def product_name(parsed, symbolic=""):
    # Validation substitutes dummy values for names only known at runtime.
    if "validitytest" in parsed and "@BV:" in symbolic:
        return symbolic
    return parsed


def declarations(parsed, symbolic, expansions=None):
    values, originals = parsed.split(), symbolic.split()
    if expansions is not None:
        if ([original for original, _ in expansions] != originals or
                [value for _, expanded in expansions for value in expanded.split()] != values):
            raise ValueError("Declaration expansion metadata does not match the constructed products")
        return [(product_name(value, original), value)
                for original, expanded in expansions for value in expanded.split()]
    if len(values) != len(originals):
        if "validitytest" in parsed and "@BV:" in symbolic:
            raise ValueError("Runtime product lists need per-declaration expansion metadata")
        originals = values
    return [(product_name(value, original), value) for value, original in zip(values, originals)]


def build_model(events):
    pipeline, groups, plan, owners, plan_event = build_groups(events)
    actions = [event for event in events if event.kind not in ("root", "group", "plan", "declaration")]
    expansions = {}
    for event in events:
        if event.kind == "declaration":
            if event.token not in ("inputs", "outputs") or any((event.c, event.d, event.status)):
                raise ValueError("Invalid declaration expansion metadata")
            expansions.setdefault((event.key, event.token), []).append((event.a, event.b))
    script_keys = {(event.key, direction) for event in actions if event.kind == "script"
                   for direction in ("inputs", "outputs")}
    if set(expansions) - script_keys:
        raise ValueError("Declaration expansion metadata refers to an unknown processing step")
    if len(actions) != len(plan):
        raise ValueError("Construction trace is missing step metadata")
    group_index = {group["id"]: group for group in groups}
    nodes, edges = [], []
    node_index = {}
    edge_keys = set()
    bindings, versions, deleted = {}, {}, set()
    head = None
    previous_action = None

    def add_node(**attributes):
        node = {
            "id": f"n{len(nodes) + 1}", "head": False, "external": False,
            "final": False, "temporary": False, "retired": False,
            "retired_reason": "", "runtime_resolved": False, "version": 0,
            "created_by": None, **attributes,
        }
        nodes.append(node)
        node_index[node["id"]] = node
        return node["id"]

    def add_edge(source, target, kind="data"):
        key = (source, target, kind)
        if key not in edge_keys:
            edge_keys.add(key)
            edges.append({"id": f"e{len(edges) + 1}", "source": source,
                          "target": target, "kind": kind})

    def new_product(name, owner, order, creator=None, is_head=False, external=False,
                    exported=False, active=True):
        versions[name] = versions.get(name, 0) + 1
        return add_node(
            label=name, name=name, kind="product", operation="",
            group=owner, order=order, number="", active=active,
            head=is_head, external=external, version=versions[name],
            runtime_resolved=("@BV:" in name or "validitytest" in name),
            created_by=creator, exported=exported,
        )

    def read_product(name):
        if name not in bindings:
            if name in deleted:
                raise ValueError(f"Product {name!r} is used after deletion without a new producer")
            bindings[name] = new_product(name, "root", 0, external=True)
        return bindings[name]

    def read_head():
        nonlocal head
        if head is None:
            head = new_product("Initial DATAHEAD", "root", 0, is_head=True, external=True)
        return head

    def write_head(action, owner, order, active):
        nonlocal head
        if head:
            node_index[head]["retired"] = True
            node_index[head]["retired_reason"] = "DATAHEAD replaced"
        head = new_product("DATAHEAD", owner, order, action, is_head=True, active=active)
        add_edge(action, head)

    def write_product(name, action, owner, order, active):
        if name in bindings:
            node_index[bindings[name]]["retired"] = True
            node_index[bindings[name]]["retired_reason"] = "Superseded by a later version"
        deleted.discard(name)
        node = new_product(name, owner, order, action, active=active)
        bindings[name] = node
        add_edge(action, node)

    def retire(name, reason):
        node = read_product(name)
        node_index[node]["retired"] = True
        node_index[node]["retired_reason"] = reason
        node_index[node]["temporary"] = reason == "Deleted"
        del bindings[name]
        deleted.add(name)
        return node

    for sequence, (event, expected, owner) in enumerate(zip(actions, plan, owners), 1):
        if event.key != str(sequence) or event.token != expected:
            raise ValueError(f"Out-of-order metadata for constructed step {sequence}")
        raw_name, number = token_parts(event.token)
        if event.kind != event_kind(raw_name) or event.status not in ("active", "skipped"):
            raise ValueError(f"Invalid graph event for {event.token}")
        active = event.status == "active"
        if event.kind == "variable":
            group_index[owner]["variables"].append({
                "name": event.a, "value": event.b, "order": sequence, "active": active,
            })
            continue
        raw_target = raw_name[1:]
        target = product_name(event.a, raw_target)
        labels = {
            "select": f"Select DATAHEAD: {target}" if target else "Clear DATAHEAD",
            "store": f"Save DATAHEAD as {target}", "delete": f"Delete {target}",
            "rename": f"Rename {event.a} to {event.b}",
            "export": f"Export {event.a} to {event.b}",
            "script": raw_name,
        }
        action = add_node(
            label=labels[event.kind], name=raw_name, kind="action", operation=event.kind,
            group=owner, number=number, order=sequence, active=active,
            inputs=event.a.split() if event.kind == "script" else [],
            outputs=event.b.split() if event.kind == "script" else [],
            declared_inputs=event.c, declared_outputs=event.d,
        )
        ancestor = owner
        while ancestor is not None:
            group_index[ancestor]["actions"].append(action)
            ancestor = group_index[ancestor]["parent"]
        if previous_action:
            add_edge(previous_action, action, "order")
        previous_action = action
        if event.kind == "script":
            for name, _ in declarations(event.a, event.c, expansions.get((event.key, "inputs"))):
                if name.startswith("BV:"):
                    continue
                source = read_head() if name in ("DATAHEAD", "ALLHEAD") else read_product(name)
                add_edge(source, action)
            output_names = set()
            for name, _ in declarations(event.b, event.d, expansions.get((event.key, "outputs"))):
                if name.startswith("BV:"):
                    continue
                key = "DATAHEAD" if name in ("DATAHEAD", "ALLHEAD") else name
                if key in output_names:
                    continue
                output_names.add(key)
                if key == "DATAHEAD":
                    write_head(action, owner, sequence, active)
                else:
                    write_product(name, action, owner, sequence, active)
        elif event.kind == "select":
            if target:
                add_edge(read_product(target), action)
                write_head(action, owner, sequence, active)
            else:
                if head:
                    node_index[head]["retired"] = True
                    node_index[head]["retired_reason"] = "DATAHEAD cleared"
                head = None
        elif event.kind == "store":
            add_edge(read_head(), action)
            write_product(target, action, owner, sequence, active)
        elif event.kind == "delete":
            add_edge(retire(target, "Deleted"), action)
        elif event.kind in ("rename", "export"):
            old_raw, new_raw = raw_target.split("-")[0], raw_target.split("-")[-1]
            old, new = product_name(event.a, old_raw), product_name(event.b, new_raw)
            add_edge(read_product(old), action)
            if event.kind == "rename":
                retire(old, f"Renamed to {new}")
                write_product(new, action, owner, sequence, active)
            else:
                exported = new_product(new, owner, sequence, action, exported=True, active=active)
                node_index[exported]["final"] = True
                add_edge(action, exported)
    for node in bindings.values():
        node_index[node]["final"] = True
    if head:
        node_index[head]["final"] = True
    return {
        "version": 1, "pipeline": pipeline, "groups": groups, "nodes": nodes, "edges": edges,
        "resumed": plan_event.b == "TRUE", "resume_number": plan_event.c,
        "summary": {
            "subroutines": len(groups) - 1,
            "actions": sum(node["kind"] == "action" for node in nodes),
            "products": sum(node["kind"] == "product" for node in nodes),
            "runtime_names": sum(node["runtime_resolved"] for node in nodes),
        },
    }


def render_html(model, asset_directory=None):
    directory = Path(asset_directory) if asset_directory else Path(__file__).resolve().parent
    template = (directory / "graph_viewer.html").read_text(encoding="utf-8")
    replacements = {
        "__PIPELINE_NAME__": html.escape(model["pipeline"]),
        "__GRAPH_DATA__": json.dumps(model, ensure_ascii=True).replace("<", "\\u003c").replace("&", "\\u0026"),
        "__GRAPH_STYLE__": (directory / "graph_viewer.css").read_text(encoding="utf-8"),
        "__GRAPH_SCRIPT__": (directory / "graph_viewer.js").read_text(encoding="utf-8"),
    }
    for placeholder in replacements:
        if template.count(placeholder) != 1:
            raise ValueError(f"Viewer template needs exactly one {placeholder}")
    return re.sub("|".join(replacements), lambda match: replacements[match.group()], template)


def atomic_write(path, contents):
    path = Path(path)
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent,
                                     prefix=f".{path.name}.", delete=False) as output:
        temporary = Path(output.name)
        try:
            output.write(contents)
            output.flush()
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--events", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()
    model = build_model(read_events(args.events))
    page = render_html(model)
    if args.json_output:
        atomic_write(args.json_output, json.dumps(model, indent=2, ensure_ascii=True) + "\n")
    atomic_write(args.output, page)
    print(f"Pipeline viewer: {args.output}")


if __name__ == "__main__":
    main()

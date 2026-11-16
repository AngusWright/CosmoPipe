"""Offline Chromium checks for the data-centric standalone pipeline viewer."""

import argparse
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

from playwright.sync_api import sync_playwright

from test_pipeline_graph import configure_fixture, event, GRAPH


def projection(page, model, **options):
    return page.evaluate("""args => window.PipelineGraph.projectGraph(args.model, args.options)""",
                         {"model": model, "options": {
                             "mode": "products", "collapsed": [], "showHead": False,
                             "showOrder": False, "showSkipped": True, **options,
                         }})


def check_layouts(page, model):
    groups = model["groups"][1:]
    for mask in range(1 << len(groups)):
        collapsed = [group["id"] for bit, group in enumerate(groups) if mask & (1 << bit)]
        for mode in ("pipeline", "products"):
            for show_head in (False, True):
                for show_skipped in (False, True):
                    page.evaluate("""args => {
                      const graph = window.PipelineGraph.projectGraph(args.model, args.options);
                      const layout = window.PipelineGraph.layoutGraph(graph, args.model);
                      if (graph.nodes.some(node => !layout.positions.has(node.id))) throw Error("Missing node position");
                      if (args.options.mode === "products" && graph.nodes.some(node => node.kind !== "product")) {
                        throw Error("Data view contains a process or subroutine");
                      }
                    }""", {"model": model, "options": {
                        "collapsed": collapsed, "mode": mode, "showHead": show_head,
                        "showOrder": True, "showSkipped": show_skipped, "groupContext": True,
                    }})


def mixed_model():
    steps = [
        event("script", 1, "produce=1.1", a="imported", b="shared", c="imported", d="shared", status="active"),
        event("script", 2, "reuse=1.2", a="shared", b="intermediate",
              c="shared", d="intermediate", status="active"),
        event("rename", 3, "%intermediate-renamed=2.1", "intermediate", "renamed", status="active"),
        event("export", 4, "~renamed-output=2.2", "renamed", "output", status="active"),
        event("script", 5, "consume=3", a="shared renamed", b="final",
              c="shared renamed", d="final", status="active"),
        event("variable", 6, "+SETTING=value=_", "SETTING", "value", status="active"),
    ]
    return GRAPH.build_model([
        event("root", token="Mixed", a=".first=1 .second=2 consume=3 .variables=4 .empty=5"),
        event("group", "1", ".first", "produce=1.1 reuse=1.2"),
        event("group", "2", ".second", "%intermediate-renamed=2.1 ~renamed-output=2.2"),
        event("group", "4", ".variables", "+SETTING=value=_"),
        event("group", "5", ".empty", ""),
        event("plan", a=" ".join(step.token for step in steps)), *steps,
    ])


def check_grouping_invariance(page, directory, reference):
    flat_steps = "  seed\n  @seed\n  !match_base\n  match\n  -match_base\n" \
                 "  @seed\n  !match_base\n  match\n  -match_base\n  final\n"
    flat = configure_fixture(directory / "flat", pipeline="GraphExample:\n" + flat_steps, subroutines="")
    routines = "".join(f".stage{i}:\n  .stage{i + 1}\n" for i in range(1, 30))
    routines += ".stage30:\n" + flat_steps
    nested = configure_fixture(directory / "thirty-routines",
                               pipeline="GraphExample:\n  .stage1\n", subroutines=routines)
    assert len(flat["groups"]) == 1
    assert len(nested["groups"]) == 31
    for mode in ("products", "pipeline"):
        for show_head in (False, True):
            for scope in ("all", "output", "temporary", "retired", "input", "runtime"):
                fingerprints = []
                for model in (reference, flat, nested):
                    fingerprints.append(page.evaluate("""args => {
                      const graph = window.PipelineGraph.projectGraph(args.model, args.options);
                      const layout = window.PipelineGraph.layoutGraph(graph, args.model);
                      return {
                        nodes: graph.nodes.map(node => [node.id, node.name, node.kind, node.version]),
                        edges: graph.edges.map(edge => [edge.source, edge.target, edge.kind, edge.operations]),
                        positions: Array.from(layout.positions), columns: layout.columns,
                        width: layout.width, height: layout.height
                      };
                    }""", {"model": model, "options": {
                        "mode": mode, "showHead": show_head, "showOrder": False,
                        "showSkipped": True, "scope": scope,
                        "collapsed": [group["id"] for group in model["groups"][1:]],
                    }}))
                assert fingerprints[0] == fingerprints[1] == fingerprints[2], (mode, show_head, scope)


def check_provenance(page):
    # Both hidden routes to an output must contribute their operation identities.
    steps = [
        event("script", 1, "seed=1", b="source", d="source", status="active"),
        event("script", 2, "split=2", a="source", b="left right",
              c="source", d="left right", status="active"),
        event("script", 3, "left_step=3", a="left", b="left_done",
              c="left", d="left_done", status="active"),
        event("script", 4, "right_step=4", a="right", b="right_done",
              c="right", d="right_done", status="active"),
        event("script", 5, "merge=5", a="left_done right_done", b="out",
              c="left_done right_done", d="out", status="active"),
        event("delete", 6, "-left=6", a="left", status="active"),
        event("delete", 7, "-right=7", a="right", status="active"),
        event("delete", 8, "-left_done=8", a="left_done", status="active"),
        event("delete", 9, "-right_done=9", a="right_done", status="active"),
    ]
    tokens = " ".join(step.token for step in steps)
    model = GRAPH.build_model([event("root", token="Diamond", a=tokens),
                               event("plan", a=tokens), *steps])
    source = next(node for node in model["nodes"] if node["name"] == "source")
    target = next(node for node in model["nodes"] if node["name"] == "out")
    graph = projection(page, model, scope="output")
    edge = next(edge for edge in graph["edges"] if edge["source"] == source["id"] and edge["target"] == target["id"])
    assert {next(node["name"] for node in model["nodes"] if node["id"] == id)
            for id in edge["operations"]} == {"split", "left_step", "right_step", "merge"}


def contrast_on_white(colour):
    channels = [int(value) / 255 for value in re.findall(r"\d+", colour)[:3]]
    linear = [value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
              for value in channels]
    luminance = sum(value * weight for value, weight in zip(linear, (0.2126, 0.7152, 0.0722)))
    return 1.05 / (luminance + 0.05)


def check_page(page, path, model):
    page.goto(path.as_uri())
    assert page.locator("#error").is_hidden(), page.locator("#error").inner_text()
    assert page.locator("#tab-lineage").get_attribute("aria-selected") == "true"
    assert page.locator(".node.action, .node.group, .lane").count() == 0
    assert page.locator(".dependency-column").count() > 0
    assert page.locator("#routine-controls").is_hidden()
    assert page.locator(".node text").first.evaluate("node => node.getScreenCTM().a") >= 0.8
    fills = page.locator(".node .node-status").evaluate_all("nodes => nodes.map(node => getComputedStyle(node).fill)")
    assert len(set(fills)) >= 3, fills
    assert all(contrast_on_white(fill) >= 4.5 for fill in fills), fills
    assert page.locator("#count-temporary").inner_text() == "2"
    page.screenshot(path=str(path.parent / "pipeline-initial.png"), full_page=True)

    products = [node for node in model["nodes"] if node["kind"] == "product" and node["name"] == "match_base"]
    results = [node for node in model["nodes"] if node["kind"] == "product" and node["name"] == "result"]
    graph = projection(page, model, collapsed=[group["id"] for group in model["groups"][1:]])
    edges = {(edge["source"], edge["target"]) for edge in graph["edges"]}
    assert (products[0]["id"], results[0]["id"]) in edges
    assert (products[1]["id"], results[1]["id"]) in edges
    assert (products[0]["id"], results[1]["id"]) not in edges
    assert (products[1]["id"], results[0]["id"]) not in edges

    page.locator("#fit").click()
    page.locator(f'[data-node="{products[0]["id"]}"]').click(force=True)
    assert "Deleted" in page.locator("#details").inner_text()
    page.get_by_role("button", name="Full lineage", exact=True).click()
    assert page.locator("#focus-control").is_visible()
    assert page.locator(f'[data-node="{products[0]["id"]}"]').count() == 1
    assert page.locator(f'[data-node="{products[1]["id"]}"]').count() == 0, "Sibling branch entered the selected lineage"
    page.get_by_role("button", name="Trace descendants", exact=True).click()
    assert page.locator(f'[data-node="{results[0]["id"]}"]').count() == 1
    page.locator("#clear-focus").click()
    assert page.locator(f'[data-node="{products[1]["id"]}"]').count() == 1

    page.locator("#metric-temporary").click()
    assert page.locator("#tab-catalogue").get_attribute("aria-selected") == "true"
    assert page.locator("#product-rows tr").count() == 2
    assert page.locator("#download-svg").is_disabled()
    page.locator("#sort-products").select_option("name")
    page.locator(f'tr[data-product="{products[1]["id"]}"] .product-link').click()
    assert "Product version" in page.locator("#details").inner_text()
    assert page.locator("#details dd").filter(has_text="2").count() > 0
    page.locator("#product-scope").select_option("output")
    assert page.locator("#product-rows .badge").count() > 0
    assert page.locator("#product-rows .status-temporary").count() == 0
    page.locator("#product-scope").select_option("all")
    page.locator("#search").fill("match_base")
    assert page.locator("#product-rows tr").count() == 2
    assert page.locator("#search-results button").count() == 2
    page.locator("#search-results button").last.click()
    assert page.locator("#tab-lineage").get_attribute("aria-selected") == "true"
    assert page.locator(f'[data-node="{products[1]["id"]}"].selected').count() == 1

    page.locator("#tab-processes").click()
    assert page.locator(".node.action").count() > 0
    assert page.locator(".node.group, .lane").count() == 0
    page.locator("#show-order").check()
    assert page.locator(".edge.order").count() > 0
    page.locator("#group-context").check()
    assert page.locator("#routine-controls").is_visible()
    assert page.locator(".node.group").count() == 2
    page.locator('button.routine[data-group="g2.1"]').click()
    assert page.locator('button.routine[data-group="g2"]').get_attribute("aria-expanded") == "true"
    assert page.locator('button.routine[data-group="g3"]').get_attribute("aria-expanded") == "false"
    page.locator("#expand-all").click()
    assert page.locator(".node.group").count() == 0
    page.locator("#collapse-all").click()
    page.locator("#tab-lineage").click()
    assert page.locator(".node.action, .node.group, .lane, .edge.order").count() == 0
    assert page.locator(f'[data-node="{products[0]["id"]}"]').count() == 1
    page.locator("#show-head").check()
    assert page.locator("#error").is_hidden()
    page.locator("#show-head").uncheck()

    before = page.locator("#graph").get_attribute("viewBox")
    page.locator("#zoom-in").click()
    assert float(page.locator("#graph").get_attribute("viewBox").split()[2]) < float(before.split()[2])
    page.locator("#readable").click()
    assert page.locator(".node text").first.evaluate("node => node.getScreenCTM().a") >= 0.8
    mini = page.locator("#minimap").bounding_box()
    page.mouse.click(mini["x"] + mini["width"] * 0.8, mini["y"] + mini["height"] / 2)
    assert page.locator("#graph").get_attribute("viewBox") != before
    page.locator("#minimap").focus()
    page.keyboard.press("Enter")

    with page.expect_download() as saved:
        page.locator("#download-svg").click()
    svg_path = path.parent / "exported.svg"
    saved.value.save_as(svg_path)
    exported = ET.parse(svg_path).getroot()
    assert len(exported.findall(".//{http://www.w3.org/2000/svg}g[@data-node]")) == page.locator(".node").count()
    assert "system-ui" in exported.find("{http://www.w3.org/2000/svg}style").text
    with page.expect_download() as saved:
        page.locator("#download-json").click()
    json_path = path.parent / "exported.json"
    saved.value.save_as(json_path)
    assert json.loads(json_path.read_text()) == model
    page.locator("#tab-lineage").focus()
    page.keyboard.press("ArrowRight")
    assert page.locator("#tab-catalogue").get_attribute("aria-selected") == "true"
    page.keyboard.press("End")
    assert page.locator("#tab-processes").get_attribute("aria-selected") == "true"
    page.locator("#group-context").uncheck()
    page.locator("#tab-lineage").click()
    page.locator("#readable").click()
    page.screenshot(path=str(path.parent / "pipeline-overview.png"), full_page=True)
    page.locator("#tab-catalogue").click()
    page.screenshot(path=str(path.parent / "product-catalogue.png"), full_page=True)
    page.locator("#tab-lineage").click()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-directory", type=Path, required=True)
    directory = parser.parse_args().output_directory.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    model = configure_fixture(directory)
    errors, requests = [], []
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        try:
            context = browser.new_context(viewport={"width": 1600, "height": 1000}, offline=True)
            def monitor(page):
                page.on("pageerror", lambda error: errors.append(str(error)))
                page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
            context.on("page", monitor)
            context.on("request", lambda request: requests.append(request.url) if request.url.startswith(("http:", "https:")) else None)
            page = context.new_page()
            check_page(page, directory / "GraphExample_graph.html", model)
            check_layouts(page, model)
            check_layouts(page, mixed_model())
            check_grouping_invariance(page, directory, model)
            check_provenance(page)
            portable = directory / "portable" / "viewer.html"
            portable.parent.mkdir(exist_ok=True)
            portable.write_bytes((directory / "GraphExample_graph.html").read_bytes())
            assert list(portable.parent.iterdir()) == [portable]
            page.goto(portable.as_uri())
            assert page.locator("#error").is_hidden()
            page.locator("#tab-catalogue").click()
            assert page.locator("#product-rows tr").count() > 0
            page.locator("#tab-processes").click()
            assert page.locator(".node.action").count() > 0
            mixed = directory / "mixed.html"
            mixed.write_text(GRAPH.render_html(mixed_model()))
            page.goto(mixed.as_uri())
            assert page.locator(".node.status-input").count() == 1
            assert page.locator(".node.status-exported").count() == 1
            fills = page.locator(".node .node-status").evaluate_all("nodes => nodes.map(node => getComputedStyle(node).fill)")
            assert all(contrast_on_white(fill) >= 4.5 for fill in fills), fills
            page.locator("#product-scope").select_option("input")
            assert page.locator(".node").count() == 1
            resume_directory = directory / "resumed"
            resumed = configure_fixture(resume_directory, resume=True)
            check_layouts(page, resumed)
            page.goto((resume_directory / "GraphExample_graph.html").as_uri())
            assert page.locator("#resume-control").is_visible()
            assert page.locator(f'[data-node="{next(node["id"] for node in resumed["nodes"] if node["name"] == "match_base" and not node["active"])}"]').count() == 0
            page.locator("#show-skipped").check()
            assert page.locator(".node.skipped").count() > 0
            page.locator("#product-scope").select_option("runtime")
            assert page.locator("#empty").is_visible()
            assert page.locator("#error").is_hidden()
            large_steps = [
                event("script", index, f"process={index}", a=f"product{index - 1}",
                      b=f"product{index}", c=f"product{index - 1}", d=f"product{index}", status="active")
                for index in range(1, 101)
            ]
            tokens = " ".join(step.token for step in large_steps)
            large_model = GRAPH.build_model([event("root", token="Large", a=tokens), event("plan", a=tokens), *large_steps])
            large = directory / "large.html"
            large.write_text(GRAPH.render_html(large_model))
            page.goto(large.as_uri())
            assert page.locator(".node").count() == 101
            assert page.locator(".node text").first.evaluate("node => node.getScreenCTM().a") >= 0.8
            box = page.locator("#graph").bounding_box()
            before = page.locator("#graph").get_attribute("viewBox")
            page.mouse.move(box["x"] + box["width"] / 2, box["y"] + box["height"] / 2)
            page.mouse.wheel(150, 200)
            page.wait_for_function("before => document.getElementById('graph').getAttribute('viewBox') !== before", arg=before)
            malicious = GRAPH.build_model([event("root", token="</script><script>window.injected=true</script>"), event("plan")])
            injection = directory / "escaped.html"
            injection.write_text(GRAPH.render_html(malicious))
            page.goto(injection.as_uri())
            assert page.evaluate("window.injected === undefined")
            assert page.locator("#error").is_hidden()
            page.set_viewport_size({"width": 600, "height": 900})
            page.goto((directory / "GraphExample_graph.html").as_uri())
            assert page.locator("#graph").bounding_box()["height"] >= 400
            assert page.evaluate("document.documentElement.scrollWidth <= window.innerWidth")
            page.locator("#tab-catalogue").click()
            assert page.locator("#product-rows tr").count() > 0
            page.screenshot(path=str(directory / "mobile-catalogue.png"), full_page=True)
            assert not errors, errors
            assert not requests, requests
            context.close()
        finally:
            browser.close()
    print("Offline browser checks passed: data-first views, product catalogue, lifecycle filters, "
          "lineage focus, exact provenance, identical layouts for zero/four/thirty subroutines, "
          "384 projection combinations, optional source context, exports, readability, and mobile layout.")


if __name__ == "__main__":
    main()

"""Pipeline graph provenance tests, including the real construction script."""

import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("pipeline_graph", ROOT / "scripts" / "pipeline_graph.py")
GRAPH = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = GRAPH
SPEC.loader.exec_module(GRAPH)


def event(kind, key="", token="", a="", b="", c="", d="", status=""):
    return GRAPH.Event(kind, str(key), token, a, b, c, d, status)


def simple_trace(steps):
    tokens = " ".join(step.token for step in steps)
    return [event("root", token="Example", a=tokens), event("plan", a=tokens), *steps]


def configure_fixture(directory, resume=False, pipeline=None, subroutines=None, modes=None):
    """Run real construction against small, declared, non-executed fixture modes."""
    scripts = directory / "runtime" / "scripts"
    manuals = directory / "runtime" / "man"
    for folder in (scripts, manuals, directory / "runtime" / "config",
                   directory / "runtime" / "logs", directory / "work", directory / "INSTALL"):
        folder.mkdir(parents=True, exist_ok=True)
    variables = {
        "RUNROOT": str(directory), "PACKROOT": str(ROOT), "PIPELINE": "GraphExample",
        "SCRIPTPATH": "runtime/scripts", "MANUALPATH": "runtime/man",
        "CONFIGPATH": "runtime/config", "LOGPATH": "runtime/logs",
        "STORAGEPATH": "work", "DATABLOCK": "datablock", "RUNTIME": "runtime",
        "CONDAPIPENAME": "graph-test", "PYTHON3BIN": sys.executable,
        "P_SED_INPLACE": "sed -i ", "ALLPATCH": "ALL", "VERBOSE": "0",
        "BLU": "", "RED": "", "DEF": "", "USER": "graph-test", "DATE": "test",
    }
    (directory / "variables.sh").write_text(
        "\n".join(f'{key}="{value}"' for key, value in variables.items()) + "\n"
    )
    files = ["scripts/construct_pipeline.sh", "scripts/pipeline_base.sh", "scripts/pipeline_close.sh",
             "scripts/graph_base.R",
             "man/CosmoPipe.man.sh", "man/construct_pipeline.man.sh"]
    for relative in files:
        content = (ROOT / relative).read_text()
        for key, value in variables.items():
            content = content.replace(f"@{key}@", value)
        destination = (scripts if relative.startswith("scripts/") else manuals) / Path(relative).name
        destination.write_text(content)
    for name in ("pipeline_graph.py", "graph_viewer.html", "graph_viewer.css", "graph_viewer.js"):
        shutil.copyfile(ROOT / "scripts" / name, scripts / name)
    (directory / "pipeline.ini").write_text(pipeline if pipeline is not None else
        "GraphExample:\n  seed\n  .matching\n" +
        ("  RESUME\n" if resume else "") +
        "  .matching\n  final\n"
    )
    (directory / "subroutines.ini").write_text(subroutines if subroutines is not None else
        ".matching:\n  @seed\n  !match_base\n  .inner\n  -match_base\n"
        ".inner:\n  match\n"
    )
    for name, inputs, outputs in (modes if modes is not None else (
        ("seed", "", "seed"), ("match", "ALLHEAD match_base", "ALLHEAD result"),
        ("final", "result", "final_product"),
    )):
        (scripts / f"{name}.sh").write_text(f'echo "{name}" >> "{directory}/executed"\n')
        (manuals / f"{name}.man.sh").write_text(
            f'_prompt() {{ :; }}\n_inp_var() {{ echo; }}\n'
            f'_inp_data() {{ echo "{inputs}"; }}\n_outputs() {{ echo "{outputs}"; }}\n'
            f'_description() {{ echo "# {name} fixture"; }}\n'
            f'_runcommand() {{ echo "bash {scripts}/{name}.sh"; }}\n'
        )
    command = ["bash", str(scripts / "construct_pipeline.sh"), str(directory / "pipeline.ini")]
    if resume:
        command += ["--resume", "0"]
    result = subprocess.run(command, cwd=directory, text=True, capture_output=True,
                            env={**os.environ, "CONDA_DEFAULT_ENV": "graph-test"}, timeout=60)
    if result.returncode:
        raise AssertionError(result.stdout + "\n" + result.stderr)
    return json.loads((directory / "GraphExample_graph.json").read_text())


class GraphTests(unittest.TestCase):
    def test_real_construction_scopes_repeated_nested_subroutines(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            model = configure_fixture(directory)
            self.assertTrue((directory / "GraphExample_graph.html").is_file())
            self.assertTrue((directory / "GraphExample_pipeline.sh").is_file())
            self.assertEqual([group["number"] for group in model["groups"]], ["", "2", "2.1", "3", "3.1"])
            products = [node for node in model["nodes"] if node["kind"] == "product" and node["name"] == "match_base"]
            self.assertEqual([node["group"] for node in products], ["g2", "g3"])
            self.assertEqual([node["version"] for node in products], [1, 2])
            self.assertTrue(all(node["temporary"] for node in products))
            for invocation, product in zip(("g2.1", "g3.1"), products):
                matcher = next(node for node in model["nodes"] if node["name"] == "match" and node["group"] == invocation)
                self.assertIn((product["id"], matcher["id"]), [(edge["source"], edge["target"]) for edge in model["edges"]])
                other = next(node for node in products if node["id"] != product["id"])
                self.assertNotIn((other["id"], matcher["id"]), [(edge["source"], edge["target"]) for edge in model["edges"]])
            self.assertFalse((directory / "executed").exists(), "Construction executed a processing step")

    def test_resume_metadata_matches_constructed_pipeline(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            model = configure_fixture(directory, resume=True)
            matchers = [node for node in model["nodes"] if node["name"] == "match"]
            self.assertEqual([node["active"] for node in matchers], [False, True])
            self.assertTrue(model["resumed"])
            script = (directory / "GraphExample_pipeline.sh").read_text()
            self.assertNotIn("#Step 2.1.1: match", script)
            self.assertIn("#Step 3.1.1: match", script)

    def test_failed_construction_removes_stale_viewer_artifacts(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            configure_fixture(directory)
            (directory / "pipeline.ini").write_text("GraphExample:\n  missing_script\n")
            result = subprocess.run(
                ["bash", str(directory / "runtime/scripts/construct_pipeline.sh"),
                 str(directory / "pipeline.ini")],
                cwd=directory, text=True, capture_output=True,
                env={**os.environ, "CONDA_DEFAULT_ENV": "graph-test"}, timeout=60,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((directory / "GraphExample_graph.html").exists())
            self.assertFalse((directory / "GraphExample_graph.json").exists())

    def test_rename_does_not_rewrite_earlier_product_versions(self):
        model = GRAPH.build_model(simple_trace([
            event("script", 1, "produce=1", b="match_base", d="match_base", status="active"),
            event("rename", 2, "%match_base-stage1=2", "match_base", "stage1", status="active"),
            event("script", 3, "produce=3", b="match_base", d="match_base", status="active"),
            event("script", 4, "consume=4", a="stage1 match_base", c="stage1 match_base", status="active"),
        ]))
        products = [node for node in model["nodes"] if node["kind"] == "product"]
        self.assertEqual([node["name"] for node in products], ["match_base", "stage1", "match_base"])
        self.assertEqual([node["version"] for node in products], [1, 1, 2])
        consumer = next(node for node in model["nodes"] if node["name"] == "consume")
        incoming = {edge["source"] for edge in model["edges"] if edge["kind"] == "data" and edge["target"] == consumer["id"]}
        self.assertEqual(incoming, {products[1]["id"], products[2]["id"]})

    def test_persistent_product_flows_across_subroutine_boundaries(self):
        steps = [
            event("script", 1, "produce=1.1", b="shared", d="shared", status="active"),
            event("script", 2, "consume=2.1", a="shared", c="shared", status="active"),
        ]
        model = GRAPH.build_model([
            event("root", token="Example", a=".first=1 .second=2"),
            event("group", "1", ".first", "produce=1.1"),
            event("group", "2", ".second", "consume=2.1"),
            event("plan", a="produce=1.1 consume=2.1"), *steps,
        ])
        product = next(node for node in model["nodes"] if node["kind"] == "product")
        consumer = next(node for node in model["nodes"] if node["name"] == "consume")
        self.assertEqual(product["group"], "g1")
        self.assertEqual(consumer["group"], "g2")
        self.assertTrue(any(edge["source"] == product["id"] and edge["target"] == consumer["id"] for edge in model["edges"]))

    def test_deleted_name_must_have_a_new_producer_before_reuse(self):
        with self.assertRaisesRegex(ValueError, "used after deletion"):
            GRAPH.build_model(simple_trace([
                event("script", 1, "produce=1", b="temporary", d="temporary", status="active"),
                event("delete", 2, "-temporary=2", a="temporary", status="active"),
                event("script", 3, "consume=3", a="temporary", c="temporary", status="active"),
            ]))

    def test_validation_placeholders_do_not_merge_symbolic_names(self):
        model = GRAPH.build_model(simple_trace([
            event("script", 1, "produce=1", b="__validitytest__ __validitytest__",
                  d="@BV:FIRST@ @BV:SECOND@", status="active"),
            event("script", 2, "consume=2", a="__validitytest__",
                  c="@BV:SECOND@", status="active"),
        ]))
        products = [node for node in model["nodes"] if node["kind"] == "product"]
        self.assertEqual([node["name"] for node in products], ["@BV:FIRST@", "@BV:SECOND@"])
        self.assertTrue(all(node["runtime_resolved"] for node in products))

    def test_head_aliases_and_exports_are_explicit_dependencies(self):
        model = GRAPH.build_model(simple_trace([
            event("select", 1, "@input=_", a="input", status="active"),
            event("store", 2, "!saved=_", a="saved", status="active"),
            event("export", 3, "~saved-output=1", a="saved", b="output", status="active"),
            event("delete", 4, "-saved=2", a="saved", status="active"),
        ]))
        products = [node for node in model["nodes"] if node["kind"] == "product"]
        self.assertEqual([node["name"] for node in products], ["input", "DATAHEAD", "saved", "output"])
        self.assertTrue(products[0]["external"])
        self.assertTrue(products[2]["temporary"])
        self.assertTrue(products[3]["exported"])
        self.assertTrue(products[3]["final"])

    def test_clearing_head_retires_the_previous_head(self):
        model = GRAPH.build_model(simple_trace([
            event("select", 1, "@input=_", a="input", status="active"),
            event("select", 2, "@=_", status="active"),
        ]))
        head = next(node for node in model["nodes"] if node["head"])
        self.assertTrue(head["retired"])
        self.assertEqual(head["retired_reason"], "DATAHEAD cleared")
        self.assertFalse(head["final"])

    def test_real_multi_value_expansion_keeps_runtime_names_distinct(self):
        with tempfile.TemporaryDirectory() as temp:
            model = configure_fixture(
                Path(temp),
                pipeline="GraphExample:\n"
                         "  +FIRST='__validitytest__ __validitytest__'\n"
                         "  +SECOND='__validitytest__'\n"
                         "  .lists\n  consume\n",
                subroutines=".lists:\n  produce\n",
                modes=[("produce", "", "@BV:FIRST@ @BV:SECOND@"),
                       ("consume", "@BV:SECOND@", "final_product")],
            )
        products = [node for node in model["nodes"] if node["kind"] == "product"]
        self.assertEqual([node["name"] for node in products],
                         ["@BV:FIRST@", "@BV:SECOND@", "final_product"])
        consumer = next(node for node in model["nodes"] if node["name"] == "consume")
        incoming = {edge["source"] for edge in model["edges"]
                    if edge["kind"] == "data" and edge["target"] == consumer["id"]}
        self.assertEqual(incoming, {products[1]["id"]})

    def test_inconsistent_or_missing_runtime_expansions_are_rejected(self):
        trace = simple_trace([
            event("script", 1, "produce=1", b="__validitytest__ __validitytest__ real",
                  d="@BV:FIRST@ @BV:SECOND@", status="active"),
        ])
        with self.assertRaisesRegex(ValueError, "per-declaration"):
            GRAPH.build_model(trace)
        with self.assertRaisesRegex(ValueError, "does not match"):
            GRAPH.build_model(trace + [
                event("declaration", 1, "outputs", "@BV:FIRST@", "__validitytest__"),
                event("declaration", 1, "outputs", "@BV:SECOND@", "real"),
            ])
        with self.assertRaisesRegex(ValueError, "unknown processing step"):
            GRAPH.build_model(trace + [event("declaration", 2, "outputs", "raw", "parsed")])

    def test_standalone_html_escapes_metadata_and_template_markers(self):
        model = GRAPH.build_model(simple_trace([]))
        model["pipeline"] = '</script><script>window.injected=true</script>__GRAPH_SCRIPT__'
        page = GRAPH.render_html(model)
        self.assertNotIn('<script>window.injected=true</script>', page)
        data = re.search(r'<script id="graph-data" type="application/json">(.*?)</script>', page, re.S)[1]
        self.assertEqual(json.loads(data)["pipeline"], model["pipeline"])
        self.assertNotRegex(page, r'<script[^>]+src=')
        self.assertIn("connect-src 'none'", page)

    def test_malformed_or_inconsistent_trace_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "events"
            path.write_bytes(b"root\0broken")
            with self.assertRaisesRegex(ValueError, "Incomplete"):
                GRAPH.read_events(path)
        with self.assertRaisesRegex(ValueError, "missing step metadata"):
            GRAPH.build_model([
                event("root", token="Example", a="step=1"), event("plan", a="step=1")
            ])


if __name__ == "__main__":
    unittest.main()

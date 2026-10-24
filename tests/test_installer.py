"""Installer regressions that do not download or install dependencies."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "COSMOPIPE_MASTER_INSTALL.sh"


class InstallerTests(unittest.TestCase):
    def run_installer(self, *args, cwd=None):
        return subprocess.run(
            ["bash", str(INSTALLER), *args],
            cwd=cwd or ROOT,
            text=True,
            capture_output=True,
            timeout=30,
        )

    def test_shell_syntax(self):
        subprocess.run(["bash", "-n", str(INSTALLER)], check=True)

    def test_runroot_required(self):
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--runroot is required", result.stderr)

    def test_unknown_and_partial_option_rejected(self):
        for option in ("--not-an-option", "--run"):
            with self.subTest(option=option):
                result = self.run_installer(option, "value")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("unknown option", result.stdout)

    def test_missing_value_rejected(self):
        for args in (("--runroot",), ("--runroot", "--noinstall")):
            with self.subTest(args=args):
                result = self.run_installer(*args)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("requires a value", result.stderr)

    def test_environment_creation_name_and_failure(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            mockbin = directory / "bin"
            mockbin.mkdir()
            calls = directory / "conda-calls"
            conda = mockbin / "conda"
            conda.write_text(
                f'#!/bin/sh\nprintf "%s\\n" "$*" >> "{calls}"\n'
                'if [ "$1" = "info" ]; then exit 0; fi\nexit 42\n'
            )
            conda.chmod(0o755)
            result = subprocess.run(
                ["bash", str(INSTALLER), "--runroot", str(directory / "run"),
                 "--condapipename", "custom-cosmopipe", "--verbose", "0"],
                env={**os.environ, "PATH": f"{mockbin}:{os.environ['PATH']}"},
                text=True,
                capture_output=True,
                timeout=30,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(
                "env create --name custom-cosmopipe --file environment.yml",
                calls.read_text(),
            )
            self.assertNotIn("Pipeline Installation Complete", result.stderr)

    def test_noinstall_from_another_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            runroot = directory / "run"
            mockbin = directory / "bin"
            mockbin.mkdir()
            sentinel = directory / "conda-called"
            conda = mockbin / "conda"
            conda.write_text(f'#!/bin/sh\ntouch "{sentinel}"\nexit 99\n')
            conda.chmod(0o755)
            result = subprocess.run(
                [
                    "bash", str(INSTALLER), "--runroot", str(runroot),
                    "--noinstall", "--verbose", "0",
                    "--condapipename", "custom-cosmopipe",
                ],
                cwd=directory,
                env={**os.environ, "PATH": f"{mockbin}:{os.environ['PATH']}"},
                text=True,
                capture_output=True,
                timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertFalse(sentinel.exists(), "--noinstall invoked Conda")
            self.assertFalse((runroot / "INSTALL").exists())
            for name in ("configure.sh", "variables.sh", "defaults.sh", "pipeline.ini"):
                self.assertTrue((runroot / name).is_file(), name)
            variables = (runroot / "variables.sh").read_text()
            self.assertIn("CONDAPIPENAME=custom-cosmopipe", variables)
            self.assertIn(f"RUNROOT={runroot}", variables)
            self.assertIn(f"PACKROOT={ROOT}", variables)

    def test_plotting_environment_creation_and_failure(self):
        for options in ((), ("--noconda",)):
            with self.subTest(options=options), tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                runroot = directory / "run"
                mockbin = directory / "bin"
                mockbin.mkdir()
                calls = directory / "conda-calls"
                conda = mockbin / "conda"
                conda.write_text(
                    f'#!/bin/sh\nprintf "%s\\n" "$*" >> "{calls}"\n'
                    'if [ "$1" = "info" ]; then exit 0; fi\n'
                    'if [ "$3" = "--name" ]; then exit 0; fi\nexit 42\n'
                )
                conda.chmod(0o755)
                result = subprocess.run(
                    ["bash", str(INSTALLER), "--runroot", str(runroot),
                     "--verbose", "0", *options],
                    env={**os.environ, "PATH": f"{mockbin}:{os.environ['PATH']}"},
                    text=True, capture_output=True, timeout=30,
                )
                self.assertEqual(result.returncode, 1)
                self.assertIn(
                    f"env create --prefix {runroot}/INSTALL/plotting-env "
                    "--file environment-plotting.yml",
                    calls.read_text(),
                )
                self.assertNotIn("run -n", calls.read_text())
                self.assertNotIn("Pipeline Installation Complete", result.stderr)

    def test_plotting_environment_reused_with_noconda(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            runroot = directory / "run"
            (runroot / "INSTALL" / "plotting-env" / "conda-meta").mkdir(parents=True)
            mockbin = directory / "bin"
            mockbin.mkdir()
            calls = directory / "conda-calls"
            conda = mockbin / "conda"
            conda.write_text(f'#!/bin/sh\nprintf "%s\\n" "$*" >> "{calls}"\nexit 42\n')
            conda.chmod(0o755)
            result = subprocess.run(
                ["bash", str(INSTALLER), "--runroot", str(runroot),
                 "--noconda", "--verbose", "0"],
                env={**os.environ, "PATH": f"{mockbin}:{os.environ['PATH']}"},
                text=True, capture_output=True, timeout=30,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("env create", calls.read_text())
            self.assertIn("run -n cosmopipe python", calls.read_text())

    def test_plotting_wrapper_selects_isolated_python(self):
        with tempfile.TemporaryDirectory(prefix="cosmopipe plotting ") as temp:
            directory = Path(temp)
            script = (ROOT / "scripts" / "plot_Sigma8.sh").read_text()
            for name, value in {
                "RUNROOT": str(directory), "STORAGEPATH": "work", "SCRIPTPATH": "scripts",
                "SURVEY": "test", "BLINDING": "BLIND", "BV:BLIND": "A",
                "BV:BOLTZMAN": "camb", "BV:STATISTIC": "xipm",
                "BV:SAMPLER": "nautilus", "BV:CHAINSUFFIX": "",
            }.items():
                script = script.replace(f"@{name}@", value)
            result = subprocess.run(
                ["bash", "-c", script], cwd=directory, text=True, capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Missing plotting environment", result.stderr)
            interpreter = directory / "INSTALL" / "plotting-env" / "bin" / "python"
            interpreter.parent.mkdir(parents=True)
            calls = directory / "python-calls"
            interpreter.write_text(f'#!/bin/sh\nprintf "%s\\n" "$@" > "{calls}"\n')
            interpreter.chmod(0o755)
            result = subprocess.run(
                ["bash", "-c", script], cwd=directory, text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            arguments = calls.read_text().splitlines()
            self.assertEqual(arguments[0], f"{directory}/scripts/plot_Sigma8.py")
            self.assertEqual(arguments[-2:], ["--statistic", "xipm"])
            self.assertIn("output_nautilus_A.txt", arguments[2])
            self.assertEqual(
                arguments[4],
                f"{directory}/work/MCMC/output/test_BLIND/camb/xipm/plots/"
                "Sigma8_nautilus_A_xipm.pdf",
            )


if __name__ == "__main__":
    unittest.main()

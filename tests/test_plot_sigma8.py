"""Exercise the real Sigma_8 plotting script with current ChainConsumer."""

from contextlib import redirect_stdout
import io
from pathlib import Path
import re
import runpy
import sys
import tempfile
import unittest
from unittest.mock import patch

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from chainconsumer.plotting import plot_contour


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"


class Sigma8Tests(unittest.TestCase):
    def test_weighted_contours_and_fitted_alpha(self):
        rng = np.random.default_rng(42)
        omega_m = rng.uniform(0.2, 0.4, 2000)
        sigma8 = 0.8 * (0.3 / omega_m)**0.55 + rng.normal(0., 0.012, 2000)
        weights = rng.uniform(0.1, 2., 2000)
        weights[::10] = 0.
        positive = weights > 0
        table = pd.DataFrame({
            "cosmological_parameters--omch2": omega_m * 0.7**2 - 0.022,
            "cosmological_parameters--ombh2": np.full(2000, 0.022),
            "cosmological_parameters--h0": np.full(2000, 0.7),
            "COSMOLOGICAL_PARAMETERS--SIGMA_8": sigma8,
            "weight": weights,
            "like": np.zeros(2000),
        })
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            source = directory / "chain.txt"
            source.write_text("#" + "\t".join(table.columns) + "\n")
            table.to_csv(source, sep="\t", index=False, header=False, mode="a")
            for statistic, colour in (
                ("cosebis", "#ff8c00"), ("bandpowers", "#ff69b4"),
                ("xipm", "#00ced1"),
            ):
                with self.subTest(statistic=statistic):
                    output = directory / f"{statistic}.pdf"
                    stdout = io.StringIO()
                    with (
                        patch.object(sys, "path", [str(SCRIPTS), *sys.path]),
                        patch.object(sys, "argv", [
                            str(SCRIPTS / "plot_Sigma8.py"),
                            "--inputfile", str(source), "--outputfile", str(output),
                            "--statistic", statistic,
                        ]),
                        patch("chainconsumer.plotting.plot_contour", wraps=plot_contour) as contour,
                        matplotlib.rc_context(),
                        redirect_stdout(stdout),
                    ):
                        runpy.run_path(str(SCRIPTS / "plot_Sigma8.py"), run_name="__main__")
                    self.assertTrue(output.read_bytes().startswith(b"%PDF"))
                    self.assertGreater(output.stat().st_size, 1000)
                    alpha = float(re.search(r"alpha =([0-9.]+)", stdout.getvalue())[1])
                    self.assertAlmostEqual(alpha, 0.55, delta=0.03)
                    self.assertEqual(contour.call_count, 2)
                    for call in contour.call_args_list:
                        axis, posterior, x, y = call.args
                        np.testing.assert_allclose(posterior.weights, weights[positive])
                        np.testing.assert_allclose(posterior.get_data(x), omega_m[positive])
                        self.assertEqual(posterior.color.lower(), colour)
                        self.assertEqual(posterior.sigmas, [0., 1., 2.])
                        self.assertEqual(posterior.kde, 1.5)
                        self.assertEqual(posterior.shade_alpha, 0.8)
                        self.assertEqual(posterior.linewidth, 1.5)
                        self.assertGreater(len(axis.collections), 0)
                    first, second = contour.call_args_list
                    np.testing.assert_allclose(
                        first.args[1].get_data(first.args[3]), sigma8[positive],
                    )
                    np.testing.assert_allclose(
                        second.args[1].get_data(second.args[3]),
                        sigma8[positive] * (omega_m[positive] / 0.3)**alpha,
                        rtol=0.001,
                    )


if __name__ == "__main__":
    unittest.main()

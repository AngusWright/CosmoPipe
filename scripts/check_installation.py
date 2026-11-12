#!/usr/bin/env python3
"""Check the installed scientific stack and the APIs used by CosmoPipe."""

import argparse
import importlib
import importlib.util
from importlib.metadata import version
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runroot", required=True, type=Path)
    args = parser.parse_args()
    install = args.runroot.resolve() / "INSTALL"
    sys.path.insert(0, str(install / "OneCovariance"))
    sys.path.insert(0, str(install / "kcap" / "modules" / "scale_cuts"))

    for package in (
        "numpy", "scipy", "pandas", "astropy", "matplotlib", "statsmodels",
        "sklearn", "h5py", "healpy", "fitsio", "pyarrow", "astropandas",
        "tabeval", "treecorr", "camb", "hmf", "cosmosis", "cosmopower",
        "tensorflow_probability", "mpi4py.MPI", "levin",
        "onecov", "twopoint", "wrapper_twopoint", "ldac", "mcal_functions",
        "measure_statistics", "measure_cosebis",
    ):
        importlib.import_module(package)
        print(f"Imported {package}", flush=True)

    import astropandas
    from astropy.io import fits
    import cosmopower
    from cosmosis.datablock import DataBlock, option_section
    import camb
    from hmf import MassFunction
    import levin
    import numpy as np
    import pandas as pd
    from scipy.integrate import cumulative_simpson
    import tensorflow as tf
    import tensorflow_probability as tfp

    block = DataBlock()
    block["cosmological_parameters", "omega_m"] = 0.3
    assert block["cosmological_parameters", "omega_m"] == 0.3
    np.testing.assert_allclose(
        cumulative_simpson([0., 1., 4.], x=[0., 1., 2.])[-1], 8. / 3.
    )
    assert np.isfinite(tfp.distributions.Normal(0., 1.).log_prob(0.).numpy())
    emulator = cosmopower.cosmopower_NN(
        parameters=["omega_m"], modes=np.array([0.1, 1.0]), n_hidden=[4]
    )
    prediction = emulator.predictions_tf(tf.constant([[0.3]], dtype=tf.float32))
    assert prediction.shape == (1, 2)
    assert np.isfinite(prediction.numpy()).all()
    levin.Levin(0, 16, 32, 1e-8, 200, 1)
    camb_params = camb.CAMBparams()
    camb_params.set_cosmology(H0=67.5, ombh2=0.022, omch2=0.12)
    assert np.isfinite(camb.get_background(camb_params).comoving_radial_distance(1.))
    mass_function = MassFunction(Mmin=10, Mmax=12, dlog10m=0.5, transfer_model="EH")
    assert np.isfinite(mass_function.dndm).all()

    interface = install / "CosmoPowerCosmosis" / "cosmosis_modules" / "cosmopower_interface.py"
    spec = importlib.util.spec_from_file_location("cosmopower_interface", interface)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    options = DataBlock()
    options[option_section, "path_2_trained_emulator"] = str(install / "CosmoPowerCosmosis")
    config = module.setup(options)
    for name, value in {
        "A_s": 2.1e-9, "n_s": 0.965, "h0": 0.67, "ombh2": 0.022,
        "omch2": 0.12, "mnu": 0.06, "omega_k": 0., "w": -1., "wa": 0.,
    }.items():
        block["cosmological_parameters", name] = value
    block["halo_model_parameters", "A"] = 3.13
    block["halo_model_parameters", "eta"] = 0.603
    block["NZ_SOURCE", "z"] = np.array([0., 1.])
    block["NZ_SOURCE", "nz"] = 2
    assert module.execute(block, config) == 0
    assert np.isfinite(block["matter_power_lin", "p_k"]).all()
    assert np.isfinite(block["matter_power_nl", "p_k"]).all()

    with tempfile.TemporaryDirectory(prefix="cosmopipe-check-") as temp:
        directory = Path(temp)
        catalogue = directory / "catalogue.fits"
        astropandas.to_fits(pd.DataFrame({"value": [1., 2.]}), catalogue)
        np.testing.assert_array_equal(
            astropandas.read_fits(catalogue)["value"], [1., 2.]
        )

        rng = np.random.default_rng(42)
        scripts = Path(__file__).resolve().parent
        positions = rng.uniform(0., 0.05, size=(1024, 2))
        table = pd.DataFrame({
            "ALPHA_J2000": positions[:, 0], "DELTA_J2000": positions[:, 1],
            "e1": np.full(1024, 0.1), "e2": np.zeros(1024),
            "weight": np.ones(1024), "weight_sq": np.ones(1024),
        })
        shear = directory / "shear.fits"
        astropandas.to_fits(table, shear)
        for weighted in ("true", "false"):
            output = directory / f"correlation-{weighted}.asc"
            subprocess.run(
                [sys.executable, str(scripts / "calc_xi_w_treecorr.py"),
                 "-n", "128", "-s", "0.05", "-l", "2", "-b", "log",
                 "-i", str(shear), "-j", str(shear), "-o", str(output),
                 "-w", weighted, "--bin_slop", "0", "--nthreads", "1"],
                check=True,
            )
            data = np.genfromtxt(output, names=True)
            assert data.shape == (128,)
            assert np.isfinite(data["xip"]).all()
            assert (data["npairs"] > 0).all()
            if weighted == "true":
                assert len(data.dtype.names) == 12
                np.testing.assert_allclose(data["npairs_weighted"], data["npairs"])

        weighted_data = np.genfromtxt(directory / "correlation-true.asc", names=True)
        subprocess.run(
            [sys.executable, str(scripts / "run_measure_statistics_cats2stats.py"),
             "-d", "xipm", "-i", str(directory / "correlation-true.asc"),
             "-t", "meanr", "-p", "xip", "-m", "xim",
             "-s", "0.05", "-l", "2", "--nbins_xipm", "3",
             "--cfoldername", str(directory), "-o", "check", "--force", "true"],
            check=True,
        )
        binned = np.genfromtxt(directory / "xipm_binned_check.asc", names=True)
        assert binned.shape == (3,)
        assert set(binned.dtype.names) == set(weighted_data.dtype.names)
        np.testing.assert_allclose(binned["weight"].sum(), weighted_data["weight"].sum())

        objects = fits.BinTableHDU.from_columns(
            [fits.Column(name="OLD", format="D", array=[1., 2.])],
            name="OBJECTS",
        )
        fits.HDUList([fits.PrimaryHDU(), objects]).writeto(catalogue, overwrite=True)
        renamed = directory / "renamed.fits"
        binaries = list((install / "theli-1.6.1" / "bin").glob("*/ldacrenkey"))
        if len(binaries) != 1:
            raise RuntimeError(f"Expected one installed ldacrenkey, found {binaries}")
        subprocess.run(
            [str(binaries[0]), "-i", str(catalogue), "-o", str(renamed),
             "-t", "OBJECTS", "-k", "OLD", "NEW"],
            check=True,
        )
        with fits.open(renamed) as result:
            np.testing.assert_array_equal(result["OBJECTS"].data["NEW"], [1., 2.])

    for package in ("cosmosis", "cosmopower", "tensorflow", "numpy", "scipy",
                    "astropy", "pandas", "treecorr", "hmf"):
        print(f"{package}=={version(package)}")
    print("CosmoPipe installation compatibility checks passed.")


if __name__ == "__main__":
    main()

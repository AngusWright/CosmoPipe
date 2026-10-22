#!/usr/bin/env python3
"""Create deterministic two-patch FITS catalogues for the combine_patch test."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from astropy.io import fits


def write_catalogue(path: Path, test_ids: list[int], test_redshifts: list[float]) -> None:
    catalogue = fits.BinTableHDU.from_columns(
        [
            fits.Column(name="TEST_ID", format="J", array=np.array(test_ids)),
            fits.Column(name="TEST_Z", format="D", array=np.array(test_redshifts)),
        ],
        name="CATALOGUE",
    )
    fits.HDUList([fits.PrimaryHDU(), catalogue]).writeto(path, overwrite=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    write_catalogue(args.output_dir / "fixture_A_input.fits", [1, 2], [-0.1, 0.1])
    write_catalogue(args.output_dir / "fixture_B_input.fits", [3, 4], [0.5, 1.5])


if __name__ == "__main__":
    main()

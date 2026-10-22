#!/usr/bin/env python3
"""Create a deterministic FITS catalogue for the construct_som unit test."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from astropy.io import fits


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    catalogue = fits.BinTableHDU.from_columns(
        [
            fits.Column(name="TEST_FEATURE_1", format="D", array=np.arange(8.0)),
            fits.Column(
                name="TEST_FEATURE_2",
                format="D",
                array=np.array([0.0, 1.0, 1.0, 2.0, 3.0, 5.0, 8.0, 13.0]),
            ),
            fits.Column(
                name="TEST_FEATURE_3",
                format="D",
                array=np.array([13.0, 8.0, 5.0, 3.0, 2.0, 1.0, 1.0, 0.0]),
            ),
            fits.Column(
                name="TEST_ZPHOT",
                format="D",
                array=np.linspace(0.1, 0.8, 8),
            ),
            fits.Column(
                name="TEST_ZSPEC",
                format="D",
                array=np.linspace(0.11, 0.81, 8),
            ),
        ],
        name="CATALOGUE",
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fits.HDUList([fits.PrimaryHDU(), catalogue]).writeto(args.output, overwrite=True)


if __name__ == "__main__":
    main()

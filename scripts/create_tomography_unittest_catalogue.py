#!/usr/bin/env python3
"""Create the deterministic LDAC fixture used by the tomography unit test."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from astropy.io import fits


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    test_ids = np.arange(1, 10, dtype=np.int32)
    test_redshifts = np.array(
        [-0.1, 0.0, 0.1, 0.5, 0.5001, 1.0, 1.0001, 2.0, 2.1],
        dtype=np.float64,
    )
    objects = fits.BinTableHDU.from_columns(
        [
            fits.Column(name="TEST_ID", format="J", array=test_ids),
            fits.Column(name="TEST_Z", format="D", array=test_redshifts),
        ],
        name="OBJECTS",
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    fits.HDUList([fits.PrimaryHDU(), objects]).writeto(args.output, overwrite=True)


if __name__ == "__main__":
    main()

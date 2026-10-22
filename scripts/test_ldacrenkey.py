#!/usr/bin/env python3
"""Assert that ldacrenkey renamed a fixture column without changing its values."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from astropy.io import fits


def fail(message: str) -> None:
    raise AssertionError(f"LDAC rename-key unit test failed: {message}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--old-key", required=True)
    parser.add_argument("--new-key", required=True)
    args = parser.parse_args()

    with fits.open(args.input, memmap=False) as catalogue:
        try:
            objects = catalogue["OBJECTS"].data
        except KeyError as error:
            raise ValueError(f"{args.input} has no OBJECTS table") from error
        column_names = objects.names
        if args.old_key in column_names:
            fail(f"old key {args.old_key} is still present")
        if args.new_key not in column_names:
            fail(f"new key {args.new_key} is missing")
        if "TEST_ID" not in column_names:
            fail("TEST_ID is missing")

        expected_ids = np.arange(1, 10)
        expected_values = np.array(
            [-0.1, 0.0, 0.1, 0.5, 0.5001, 1.0, 1.0001, 2.0, 2.1]
        )
        if not np.array_equal(objects["TEST_ID"], expected_ids):
            fail(f"unexpected TEST_ID values: {objects['TEST_ID'].tolist()}")
        if not np.array_equal(objects[args.new_key], expected_values):
            fail(
                f"{args.new_key} has values {objects[args.new_key].tolist()}, "
                f"expected {expected_values.tolist()}"
            )

    print("LDAC rename-key unit test passed.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Assert that ldacfilter retained exactly the expected catalogue rows."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from astropy.io import fits


def objects_table(path: Path) -> np.ndarray:
    with fits.open(path, memmap=False) as catalogue:
        try:
            return catalogue["OBJECTS"].data.copy()
        except KeyError as error:
            raise ValueError(f"{path} has no OBJECTS table") from error


def fail(message: str) -> None:
    raise AssertionError(f"LDAC filter unit test failed: {message}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--expected-ids", required=True)
    args = parser.parse_args()

    expected_ids = np.fromstring(args.expected_ids, sep=" ", dtype=np.int64)
    if expected_ids.size == 0:
        fail("LDACFILTER_TEST_EXPECTED_IDS must contain at least one ID")

    input_data = objects_table(args.input)
    output_data = objects_table(args.output)
    if "TEST_ID" not in input_data.names or "TEST_ID" not in output_data.names:
        fail("input and output catalogues must contain TEST_ID")

    input_ids = np.sort(input_data["TEST_ID"])
    output_ids = np.sort(output_data["TEST_ID"])
    if not np.isin(output_ids, input_ids).all():
        fail("output contains IDs absent from the input catalogue")
    if not np.array_equal(output_ids, np.sort(expected_ids)):
        fail(
            f"output has IDs {output_ids.tolist()}, expected "
            f"{np.sort(expected_ids).tolist()}"
        )
    if len(np.unique(output_ids)) != len(output_ids):
        fail("output contains duplicate IDs")

    print("LDAC filter unit test passed.")


if __name__ == "__main__":
    main()

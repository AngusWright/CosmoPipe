#!/usr/bin/env python3
"""Assert that combine_patch merged both patches and labelled each row."""

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
    raise AssertionError(f"Combine patch unit test failed: {message}")


def patch_label(value: str | bytes) -> str:
    return value.decode() if isinstance(value, bytes) else str(value)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    output_data = objects_table(args.output)
    if "TEST_ID" not in output_data.names or "PATCH" not in output_data.names:
        fail("combined catalogue must contain TEST_ID and PATCH")

    output_ids = np.sort(output_data["TEST_ID"])
    expected_ids = np.array([1, 2, 3, 4])
    if not np.array_equal(output_ids, expected_ids):
        fail(f"output has IDs {output_ids.tolist()}, expected {expected_ids.tolist()}")
    if len(np.unique(output_ids)) != len(output_ids):
        fail("output contains duplicate IDs")

    expected_labels = {1: "A_patch", 2: "A_patch", 3: "B_patch", 4: "B_patch"}
    actual_labels = {
        int(test_id): patch_label(label)
        for test_id, label in zip(output_data["TEST_ID"], output_data["PATCH"], strict=True)
    }
    if actual_labels != expected_labels:
        fail(f"output has PATCH labels {actual_labels}, expected {expected_labels}")

    print("Combine patch unit test passed.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Assert that tomography output catalogues match the configured binning."""

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
    raise AssertionError(f"Tomography unit test failed: {message}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--catalogues", required=True, nargs="+", type=Path)
    parser.add_argument("--tomovar", required=True)
    parser.add_argument("--tomolims", required=True)
    args = parser.parse_args()

    limits = np.fromstring(args.tomolims, sep=" ")
    if limits.size < 2 or not np.all(np.diff(limits) > 0):
        fail(f"TOMOLIMS must contain ascending limits; received {args.tomolims!r}")

    input_data = objects_table(args.input)
    if args.tomovar not in input_data.names:
        fail(f"input catalogue has no {args.tomovar} column")
    if "TEST_ID" not in input_data.names:
        fail("input catalogue has no TEST_ID column")

    input_ids = input_data["TEST_ID"]
    input_values = input_data[args.tomovar]
    expected_bins = limits.size - 1
    if len(args.catalogues) != expected_bins:
        fail(
            f"expected {expected_bins} output catalogues, found "
            f"{len(args.catalogues)}"
        )

    seen_bins: set[int] = set()
    actual_ids: list[np.ndarray] = []
    for path in args.catalogues:
        output_data = objects_table(path)
        if args.tomovar not in output_data.names or "TEST_ID" not in output_data.names:
            fail(f"{path} is missing TEST_ID or {args.tomovar}")
        if "TOMOBIN" not in output_data.names:
            fail(f"{path} is missing TOMOBIN")

        labels = np.unique(output_data["TOMOBIN"])
        if labels.size != 1:
            fail(f"{path} contains multiple TOMOBIN labels: {labels.tolist()}")
        bin_number = int(labels[0])
        if bin_number < 1 or bin_number > expected_bins:
            fail(f"{path} has invalid TOMOBIN label {bin_number}")
        if bin_number in seen_bins:
            fail(f"more than one output catalogue has TOMOBIN={bin_number}")
        seen_bins.add(bin_number)

        lower, upper = limits[bin_number - 1 : bin_number + 1]
        expected_ids = np.sort(input_ids[(input_values > lower) & (input_values <= upper)])
        output_ids = np.sort(output_data["TEST_ID"])
        if not np.array_equal(output_ids, expected_ids):
            fail(
                f"TOMOBIN={bin_number} has IDs {output_ids.tolist()}, expected "
                f"{expected_ids.tolist()} for ({lower}, {upper}]"
            )
        if not np.all((output_data[args.tomovar] > lower) & (output_data[args.tomovar] <= upper)):
            fail(f"TOMOBIN={bin_number} contains values outside ({lower}, {upper}]")
        actual_ids.append(output_ids)

    if seen_bins != set(range(1, expected_bins + 1)):
        fail(f"missing TOMOBIN labels {sorted(set(range(1, expected_bins + 1)) - seen_bins)}")

    expected_ids = np.sort(
        input_ids[(input_values > limits[0]) & (input_values <= limits[-1])]
    )
    if not np.array_equal(np.sort(np.concatenate(actual_ids)), expected_ids):
        fail("the output catalogues do not contain the expected union of input objects")

    print("Tomography unit test passed.")


if __name__ == "__main__":
    main()

"""Benchmark LDAC metadata operations and a representative large-table rebuild.

Run with the scientific environment's Python: python tests/benchmark_ldac.py.
Times are warm-run medians; modules run in alternating order to reduce bias.
"""

import argparse
import gc
from pathlib import Path
import statistics
import sys
from time import perf_counter

from astropy.io import fits
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import ldac
import ldac_optimised


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iterations", type=int, default=50000)
    parser.add_argument("--rows", type=int, default=100000)
    parser.add_argument("--repeat", type=int, default=5)
    args = parser.parse_args()
    if min(args.iterations, args.rows, args.repeat) < 1:
        parser.error("iterations, rows, and repeat must be positive")

    tables, cats = [], []
    for module in (ldac, ldac_optimised):
        table = module.LDACTable(fits.BinTableHDU.from_columns([
            fits.Column(name=f"COL{i}", format="D", array=np.zeros(1))
            for i in range(128)
        ]))
        cat = module.LDACCat()
        cat.ldactables = [module.LDACTable() for _ in range(32)]
        for i, entry in enumerate(cat.ldactables):
            entry.setname(f"TABLE{i}")
        tables.append(table)
        cats.append(cat)

    def repeated(function):
        for _ in range(args.iterations):
            function()

    def rebuild(module):
        table = module.LDACTable(fits.BinTableHDU.from_columns([
            fits.Column(name=f"COL{i}", format="D", array=np.arange(args.rows, dtype=float))
            for i in range(24)
        ]))
        for i in range(3):
            table[f"NEW{i}"] = np.ones(args.rows)
        table.keys()
        assert len(table) == args.rows

    workloads = [
        ("catalogue lookup (last of 32)", lambda i: repeated(lambda: cats[i]["TABLE31"])),
        ("catalogue lookup (first of 32)", lambda i: repeated(lambda: cats[i]["TABLE0"])),
        ("catalogue contains (first of 32)", lambda i: repeated(lambda: "TABLE0" in cats[i])),
        ("catalogue contains (last of 32)", lambda i: repeated(lambda: "TABLE31" in cats[i])),
        ("column contains (first of 128)", lambda i: repeated(lambda: "COL0" in tables[i])),
        ("column contains (last of 128)", lambda i: repeated(lambda: "COL127" in tables[i])),
        ("row count", lambda i: repeated(lambda: len(tables[i]))),
        ("numeric column access", lambda i: repeated(lambda: tables[i]["COL127"])),
        (f"add 3 columns ({args.rows} rows)", lambda i: rebuild((ldac, ldac_optimised)[i])),
    ]
    print(f"Python {sys.version.split()[0]}; NumPy {np.__version__}; "
          f"Astropy {__import__('astropy').__version__}")
    print(f"{args.iterations} metadata operations; median of {args.repeat} runs")
    print(f"{'Operation':42} {'Original (s)':>13} {'Optimised (s)':>14} {'Speedup':>9}")
    for name, workload in workloads:
        times = [[], []]
        for index in (0, 1):
            workload(index)
        for repeat in range(args.repeat):
            for index in ((0, 1) if repeat % 2 == 0 else (1, 0)):
                gc.collect()
                start = perf_counter()
                workload(index)
                times[index].append(perf_counter() - start)
        original, optimised = (statistics.median(t) for t in times)
        print(f"{name:42} {original:13.6f} {optimised:14.6f} {original / optimised:8.2f}x")


if __name__ == "__main__":
    main()

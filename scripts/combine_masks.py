#=========================================
#
# File Name : combine_masks.py
# Created By : Christos Georgiou 
# Creation Date : 22-10-2026
# Last Modified : 
#
#=========================================

import argparse
import numpy as np
import healpy


def main():
    parser = argparse.ArgumentParser(
        description="Combine the two North/South HEALPix masks."
    )

    parser.add_argument(
        "-n", "--north", dest="north",
        default='KiDS_Legacy_N_healpix_4096_frac_withAstrom.fits',
        help="North HEALPix mask.",
    )

    parser.add_argument(
        "-s", "--south", dest="south",
        default='KiDS_Legacy_S_healpix_4096_frac_withAstrom.fits',
        help="South HEALPix mask.",
    )

    parser.add_argument(
        "-o", "--output",
        default='KiDS_Legacy_NS_healpix_4096_frac_withAstrom.fits',
        help="Output HEALPix mask.",
    )

    args = parser.parse_args()

    print(f"Reading North mask: {args.north}")
    north = healpy.read_map(args.north)

    print(f"Reading South mask: {args.south}")
    south = healpy.read_map(args.south)

    # Use south mask where it is defined, otherwise use north.
    mask_NS = np.where(np.isnan(south), north, south)

    print(f"Writing combined mask: {args.output}")
    healpy.write_map(
        args.output,
        mask_NS,
        nest=False,
        dtype=float,
        overwrite=True,
    )

    print("Done.")


if __name__ == "__main__":
    main()

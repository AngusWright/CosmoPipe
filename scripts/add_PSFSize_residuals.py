# -*- coding: utf-8 -*-
# @Author: hendrik
# @Date:   2026-03-02
# @Last Modified by: hendrik
# @Last Modified time: 2026-03-02

import os
import argparse

import numpy as np
import astropy.io.fits as fits
from scipy.interpolate import LinearNDInterpolator

# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"step1_methodC.py: correct alpha in variance with method C.",
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "--inpath", type=str,
    help="the in path for the catalogue.")
parser.add_argument(
    "--outpath", type=str, 
    help="the output path for the final catalogue") 
parser.add_argument(
    "--PSF_table", type=str,
    help="table with FoV PSF model")

## arg parser
args = parser.parse_args()

PSF = fits.open(args.PSF_table)
x = PSF[1].data['x']
y = PSF[1].data['y']
PSFSizeRes_grid = PSF[1].data['PSF_R2_ERR'] / PSF[1].data['PSF_R2']

interp = LinearNDInterpolator((x, y), data)

TR1 = fits.open(args.inpath)

X = TR1[1].data['SHE_PSF_FOV_X']
Y = TR1[1].data['SHE_PSF_FOV_Y']

PSFSizeRes = interp(X,Y)


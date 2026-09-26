# -*- coding: utf-8 -*-
# @Author: hendrik
# @Date:   2026-03-02
# @Last Modified by: hendrik
# @Last Modified time: 2026-03-02

import os
import argparse

import numpy as np
import astropy.io.fits as fits
import ldac
from scipy.interpolate import LinearNDInterpolator, NearestNDInterpolator

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
    "--mode", type=str, 
    help="the PSF residual to add (either size or ell)") 
parser.add_argument(
    "--PSF_table", type=str,
    help="table with FoV PSF model")

## arg parser
args = parser.parse_args()

PSF = fits.open(args.PSF_table)
x = PSF[1].data['x']
y = PSF[1].data['y']

if args.mode == 'size':
    PSFVAR = PSF[1].data['PSF_R2_ERR'] / PSF[1].data['PSF_R2'] / PSF[1].data['weights']
    colname = 'PSFSizeRes'
elif args.mode == 'ell':
    PSFVAR = np.sqrt(PSF[1].data['PSF_ERR1']**2 + PSF[1].data['PSF_ERR2']**2) / PSF[1].data['weights']
    colname = 'PSFEllRes'

#interp = LinearNDInterpolator((x, y), PSFVAR)
interp = NearestNDInterpolator((x, y), PSFVAR)

#TR1 = fits.open(args.inpath)
TR1 = ldac.LDACCat(args.inpath)

X = TR1['OBJECTS']['SHE_PSF_FOV_X']
Y = TR1['OBJECTS']['SHE_PSF_FOV_Y']

PSFSizeRes = interp(X,Y)

TR1['OBJECTS'][colname] = PSFSizeRes
TR1.saveas(args.outpath,clobber=False)

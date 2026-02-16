#=========================================
#
# File Name : add_Resolution.py
# Created By : awright
# Creation Date : 30-05-2023
# Last Modified : Thu Feb  5 17:25:39 2026
#
#=========================================


import os
import argparse

import pandas as pd 
import numpy as np
import ldac 

import statsmodels.api as sm
import mcal_functions as mcf 

def g_to_e(g1, g2):
    """
    Converts g-type shears to e-type
    
    Parameters
    ==========
    g1: float or np.ndarray
    g2: float or np.ndarray
    
    Returns
    =======
    e1: float or np.ndarray
    e2: float or np.ndarray
    """
    
    fac = 2 / (1 + g1**2 + g2**2)
    return g1*fac, g2*fac



# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"Compute the g-shear from e-ellipticities",
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "--inpath", type=str,
    help="the in path for the catalogue.")
parser.add_argument(
    "--outpath", type=str, 
    help="the output path for the final catalogue") 
parser.add_argument(
    "--cols_e12", type=str, nargs=2, 
    help="column names for e1_gal, e2_gal.")
parser.add_argument(
    "--cols_g12", type=str, nargs=2, 
    help="column names for g1_gal, g2_gal.")

## arg parser
args = parser.parse_args()

#Read catalogue (keeping as LDAC)
cata, ldac_cat = mcf.flexible_read(args.inpath,as_df=False)

### compute e1 e2 
e1, e2 = g_to_e(cata[args.cols_g12[0]].astype(np.float64), cata[args.cols_g12[1]].astype(np.float64))
cata[args.cols_e12[0]]=e1
cata[args.cols_e12[1]]=e2

#Write the catalogue 
mcf.flexible_write(cata,args.outpath,ldac_cat)


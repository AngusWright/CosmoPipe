#=========================================
#
# File Name : add_Resolution.py
# Created By : awright
# Creation Date : 30-05-2023
# Last Modified : Fri 01 Sep 2023 08:05:53 AM UTC
#
#=========================================



import argparse
import numpy as np
import mcal_functions as mcf 

# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"Add resolution variable to a catalogue",
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "--inpath", type=str,
    help="the in path for the catalogue.")
parser.add_argument(
    "--outpath", type=str, 
    help="the output path for the final catalogue") 
parser.add_argument(
    "--col_scalelength", type=str,
    help="column for the scalelength variable in the catalogue.")
parser.add_argument(
    "--cols_e12", type=str, nargs=2, 
    help="column names for e1_gal, e2_gal.")
parser.add_argument(
    "--cols_psf_Q", type=str, nargs=3, 
    help="column names for PSF_Q11, PSF_Q22, PSF_Q12 shape parameters")

## arg parser
args = parser.parse_args()

#Read catalogue (keeping as LDAC)
cata, ldac_cat = mcf.flexible_read(args.inpath,as_df=False)

# >>>>>>>>>> new selection
### circularised galaxy size
emod = np.hypot(cata[args.cols_e12[0]].astype(np.float64), cata[args.cols_e12[1]].astype(np.float64))
r_ab = (cata[args.col_scalelength].astype(np.float64) * np.sqrt((1.-emod)/(1.+emod)))
### PSF size
PSFsize = ((cata[args.cols_psf_Q[0]].astype(np.float64)*cata[args.cols_psf_Q[1]].astype(np.float64) - cata[args.cols_psf_Q[2]].astype(np.float64)**2.)**0.5)
### resolution parameter
R = (PSFsize / (r_ab**2 + PSFsize))
cata['emod']=emod
cata['r_ab']=r_ab
cata['PSFsize']=PSFsize
cata['R']=R

print(cata['R'])

#Write the catalogue 
mcf.flexible_write(cata,args.outpath,ldac_cat)


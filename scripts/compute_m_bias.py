#=========================================
#
# File Name : compute_m_surface.py
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Mon 18 Mar 2024 09:32:29 PM CET
#
#=========================================

import numpy as np
import pandas as pd
# import statsmodels.api as sm 

# from scipy import stats
# from astropy.io import fits
# from astropy.table import Table
from argparse import ArgumentParser

import mcal_functions as mcf 

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>> Arguments 
parser = ArgumentParser(description='Compute m-bias from calibration surface')
parser.add_argument("--input_surface", dest="input_surface",
            help="Full Input file name and path for m-surface",required=True)
parser.add_argument("--input_cat", dest="input_data",
            help="Full Input file name and path", metavar="input",required=True)
parser.add_argument("--output", dest="outputpath",
            help="Full Output file name and path",required=True)
parser.add_argument("--output_surface", dest="outputpath_surf",
            help="Full Output file name and path for surface file",required=True)
parser.add_argument("--m12name", dest="col_m12",nargs=2,
            help="Column names for the m1/m2 variables in the m_surface file",required=True)
parser.add_argument("--weightname", dest="col_weight",
            help="Column name for the weight variable",required=True)
parser.add_argument("--SNRname", dest="col_SNR",
            help="Column name for the SNR variable",required=True)
parser.add_argument("--Rname", dest="col_R",
            help="Column name for the Resolution variable",required=True)

#Parse the arguments
args = parser.parse_args()

# >>>>>>>>>>>>>>>> workhorse
# load data catalogue
cata_data, ldac_data = mcf.flexible_read(args.input_data)
print('Number of sources in the data', len(cata_data))

### select weight
print(args.col_weight)
print(cata_data)
cata_data = cata_data[cata_data[args.col_weight]>0]
cata_data.reset_index(drop=True, inplace=True)
print('selected objects (weight>0)', len(cata_data))

# save useable parameters
cata_used = pd.DataFrame({
    'SNR': np.array(cata_data[args.col_SNR]).astype(float),
    'R': np.array(cata_data[args.col_R]).astype(float),
    'weight': np.array(cata_data[args.col_weight]).astype(float),
    })

# load m calibraiton surface 
cata_surface, ldac_surface = mcf.flexible_read(args.input_surface)

# calculate m
m_res = pd.DataFrame(-999., index=np.arange(1),
                    columns = ['m','m_err','m1', 'm2', 'm1_err', 'm2_err','Nwei','Nwei_good','Nwei_good_out','N','N_good'])
m1, m2, m1_err, m2_err, good_id, goodwt, newsurf = mcf.mCalFunc_from_surface(cata=cata_used, surface=cata_surface, 
                                            col_SNR="SNR", col_R="R", col_weight="weight", 
                                            col_m1=args.col_m12[0], col_m2=args.col_m12[1])
print(f'{args.input_data}: {(m1+m2)/2.}, {np.sqrt(m1_err**2+m2_err**2)}')
m_res.loc[0, 'm'] = (m1+m2)/2.
m_res.loc[0, 'm_err'] = np.sqrt(m1_err**2+m2_err**2)
m_res.loc[0, 'm1'] = m1
m_res.loc[0, 'm2'] = m2
m_res.loc[0, 'm1_err'] = m1_err
m_res.loc[0, 'm2_err'] = m2_err
m_res.loc[0, 'Nwei'] = np.sum(cata_data[args.col_weight].values)
m_res.loc[0, 'Nwei_good'] = np.sum(cata_data.loc[good_id,args.col_weight].values)
m_res.loc[0, 'Nwei_good_out'] = goodwt
m_res.loc[0, 'N'] = len(cata_data[args.col_weight].values)
m_res.loc[0, 'N_good'] = len(cata_data.loc[good_id,args.col_weight].values)

m_res.to_csv(args.outputpath, index=False, float_format='%.6f')
print(f'results saved to {args.outputpath}')

#save m calibraiton surface 
mcf.flexible_write(newsurf,args.outputpath_surf,ldac_surface)
print(f'surface saved to {args.outputpath_surf}')


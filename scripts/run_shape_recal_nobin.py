# -*- coding: utf-8 -*-
# @Author: lshuns
# @Date:   2022-03-14 17:57:35
# @Last Modified by:   lshuns
# @Last Modified time: 2022-09-26 17:33:55

### correct alpha in measured e with method D
##### weight should be corrected already
##### final catalogue only contains objects with non-zero weight and within given Z_B_edges
##### if the redshift calibration flag is provided, only gold class will be saved
##### method D contains two steps:
############ 1. general fitting to remove the main trend in resolution and SNR
############ 2. tomographic bins + 20*20 SNR and resolution bins to remove residual

import os
import time
import argparse
import ldac
import astropy.io.fits as aif
from astropy.table import Table

import numpy as np
import pandas as pd 
import numpy.linalg as la
import statsmodels.api as sm 
import mcal_functions as mcf

tzero = time.time()
# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"step2_methodD.py: correct alpha in e1,2 with method D.",
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "--inpath", type=str,
    help="the in path for the catalogue.")
parser.add_argument(
    "--outpath", type=str, 
    help="filename for the output catalogue.") 
parser.add_argument(
    "--col_weight", type=str,
    help="columns to the weight in the catalogue.")
parser.add_argument(
    "--cols_e12", type=str, nargs=2, 
    help="column names for e1_gal, e2_gal.")
parser.add_argument(
    "--cols_psf_e12", type=str, nargs=2, 
    help="column names for e1_psf, e2_psf.")
parser.add_argument(
    "--removeconst", type=str, default="False", 
    help="remove constant term from ellipticities?")
parser.add_argument(
    "--flagsource", type=str, default="False", 
    help="flag sources that are not well modelled?")

## arg parser
args = parser.parse_args()
inpath = args.inpath
outpath = args.outpath

col_weight = args.col_weight
col_e1, col_e2 = args.cols_e12
col_psf_e1, col_psf_e2 = args.cols_psf_e12
flagsource = args.flagsource == "True"
remove_constant = args.removeconst == "True"

#Recalibrated names 
recalname_e1 = col_e1 + "_alphaRecal"
recalname_e2 = col_e2 + "_alphaRecal"
recalname_alpha1 = "AlphaRecalD2_alpha1"
recalname_alpha1_err = "AlphaRecalD2_alpha1_err"
recalname_alpha2 = "AlphaRecalD2_alpha2"
recalname_alpha2_err = "AlphaRecalD2_alpha2_err"
recalname_const1 = "AlphaRecalD2_const1"
recalname_const1_err = "AlphaRecalD2_const1_err"
recalname_const2 = "AlphaRecalD2_const2"
recalname_const2_err = "AlphaRecalD2_const2_err"


# >>>>>>>>>>>>>>>>>>>>> workhorse

print("starting: "+str(time.time()-tzero))

# ++++++ 0. load catalogue
obj_cat,ldac_cat = mcf.flexible_read(inpath,as_df=True)

# Infer SeqNr of all objects 
seqnr = obj_cat['SeqNr'].to_numpy()

print("timer: "+str(time.time()-tzero))

print('number original', len(obj_cat))
# Set up flag for objects with successful shape recalibration
## only preserve weight > 0
obj_cat = obj_cat[(obj_cat[col_weight]>0)]

print('number after weight selection', len(obj_cat))
print("timer: "+str(time.time()-tzero))

# ++++++ 1. get alpha map 
start_time = time.time()

# Columns of interest
columns = ['SeqNr', col_weight, col_e1, col_e2, col_psf_e1, col_psf_e2]
# Only keep columns of interest in dataframe
obj_cat = obj_cat[columns] 

# ++++++ 3. step2: direct correction for residual alpha
start_time = time.time()

## construct a temporary pandas df 
obj_df = pd.DataFrame({"AlphaRecal_index":obj_cat.index,
                       col_weight:obj_cat[col_weight].astype(np.float64),
                       col_e1:obj_cat[col_e1].astype(np.float64),
                       col_e2:obj_cat[col_e2].astype(np.float64),
                       col_psf_e1:obj_cat[col_psf_e1].astype(np.float64),
                       col_psf_e2:obj_cat[col_psf_e2].astype(np.float64),
                       "bin":np.ones(len(obj_cat.index))})

print(obj_df)

# correct in each bin
cata_corr = []
for name, group in obj_df.groupby(by=['bin']):

    # >>>>>>>>>>>>>>>> calculate alpha
    # unique index
    index_obj = group['AlphaRecal_index'].values
    # out shear
    e1_out = np.array(group[col_e1])
    e2_out = np.array(group[col_e2])
    weight_out = np.array(group[col_weight])
    # out PSF 
    e1_psf = np.array(group[col_psf_e1])
    e2_psf = np.array(group[col_psf_e2])
    del group
    # calculate alpha using least square
    ## e1
    mod_wls = sm.WLS(e1_out, sm.add_constant(e1_psf), weights=weight_out)
    res_wls = mod_wls.fit()
    #If we want to flag sources 
    if flagsource: 
        #Get predicted e1_out 
        fitvals = res_wls.get_prediction()
        #Get e1 1-sigma confidence interval size
        conf_int = fitvals.conf_int(obs=True,alpha=0.3173105)
        conf_int = conf_int[:,1]-conf_int[:,0]
        #Flag sources that are more than 5-sigma away from the prediction 
        tmp_mask_e1 = (e1_out > fitvals.predicted + conf_int*5) | (e1_out < fitvals.predicted - conf_int*5)
    alpha1 = res_wls.params[1]
    alpha1_err = (res_wls.cov_params()[1, 1])**0.5
    const1 = res_wls.params[0]
    const1_err = (res_wls.cov_params()[0, 0])**0.5
    del res_wls, mod_wls
    ## e2
    mod_wls = sm.WLS(e2_out, sm.add_constant(e2_psf), weights=weight_out)
    res_wls = mod_wls.fit()
    #If we want to flag sources 
    if flagsource: 
        #Get predicted e2_out 
        fitvals = res_wls.get_prediction()
        #Get e2 1-sigma confidence interval size
        conf_int = fitvals.conf_int(obs=True,alpha=0.3173105)
        conf_int = conf_int[:,1]-conf_int[:,0]
        #Flag sources that are more than 5-sigma away from the prediction 
        tmp_mask_e2 = (e2_out > fitvals.predicted + conf_int*5) | (e2_out < fitvals.predicted - conf_int*5)
        #mask keeps True and discards False
        mask = (tmp_mask_e1 | tmp_mask_e2) == False
    alpha2 = res_wls.params[1]
    alpha2_err = (res_wls.cov_params()[1, 1])**0.5
    const2 = res_wls.params[0]
    const2_err = (res_wls.cov_params()[0, 0])**0.5
    del weight_out, res_wls, mod_wls

    # >>>>>>>>>>>>>>>> correct 
    if remove_constant: 
        e1_corr = e1_out - alpha1 * e1_psf - const1
        e2_corr = e2_out - alpha2 * e2_psf - const2 
    else: 
        e1_corr = e1_out - alpha1 * e1_psf
        e2_corr = e2_out - alpha2 * e2_psf

    # >>>>>>>>>>>>>>>> save
    if flagsource: 
        cata_tmp = pd.DataFrame({'AlphaRecal_index': index_obj, 
                                recalname_e1: e1_corr,
                                recalname_e2: e2_corr,
                                recalname_alpha1: alpha1,
                                recalname_alpha1_err: alpha1_err,
                                recalname_alpha2: alpha2,
                                recalname_alpha2_err: alpha2_err,
                                recalname_const1: const1,
                                recalname_const1_err: const1_err,
                                recalname_const2: const2,
                                recalname_const2_err: const2_err,
                                'mask': mask })
    else: 
        cata_tmp = pd.DataFrame({'AlphaRecal_index': index_obj, 
                                recalname_e1: e1_corr,
                                recalname_e2: e2_corr,
                                recalname_alpha1: alpha1,
                                recalname_alpha1_err: alpha1_err,
                                recalname_alpha2: alpha2,
                                recalname_alpha2_err: alpha2_err,
                                recalname_const1: const1,
                                recalname_const1_err: const1_err,
                                recalname_const2: const2,
                                recalname_const2_err: const2_err})
    del e1_out, alpha1, alpha1_err, e1_psf, e2_out, alpha2, alpha2_err, e2_psf, const1, const1_err, const2, const2_err, index_obj, e1_corr, e2_corr
    cata_corr.append(cata_tmp)
    del cata_tmp
cata_corr = pd.concat(cata_corr)

#Mask the poorly modelled objects 
if flagsource: 
    print('number with well modelled alphas after step D1', np.sum(cata_corr['mask']), 'fraction', np.sum(cata_corr['mask'])/len(cata_corr))
    cata_corr = cata_corr[cata_corr['mask']]
    del mask 

# meaningful e
mask_tmp = (cata_corr[recalname_e1]>-1) & (cata_corr[recalname_e1]<1) \
           & (cata_corr[recalname_e2]>-1) & (cata_corr[recalname_e2]<1)
print('number with meaningful e after D2', np.sum(mask_tmp), 'fraction', np.sum(mask_tmp)/len(cata_corr))
cata_corr = cata_corr[mask_tmp]
del mask_tmp

# merge
obj_cat[recalname_alpha1] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_alpha1] = cata_corr[recalname_alpha1].to_numpy() 
obj_cat[recalname_alpha2] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_alpha2] = cata_corr[recalname_alpha2].to_numpy() 
obj_cat[recalname_const1] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_const1] = cata_corr[recalname_const1].to_numpy() 
obj_cat[recalname_const2] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_const2] = cata_corr[recalname_const2].to_numpy()
obj_cat[recalname_alpha1_err] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_alpha1_err] = cata_corr[recalname_alpha1_err].to_numpy() 
obj_cat[recalname_alpha2_err] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_alpha2_err] = cata_corr[recalname_alpha2_err].to_numpy() 
obj_cat[recalname_const1_err] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_const1_err] = cata_corr[recalname_const1_err].to_numpy() 
obj_cat[recalname_const2_err] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_const2_err] = cata_corr[recalname_const2_err].to_numpy()
obj_cat[recalname_e1] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_e1] = cata_corr[recalname_e1].to_numpy()
obj_cat[recalname_e2] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat.loc[cata_corr['AlphaRecal_index'],recalname_e2] = cata_corr[recalname_e2].to_numpy()
mask_tmp = ((obj_cat[recalname_e1] == 0) & (obj_cat[recalname_e2] == 0))==False
obj_cat = obj_cat[mask_tmp]
del cata_corr
print('D2 finished in', time.time() - start_time, 's')
print("timer: "+str(time.time()-tzero))

# save
if os.path.exists(outpath):
    os.remove(outpath)
# Infer output columns
output_columns = [c for c in obj_cat.columns if ('AlphaRecal' in c or 'alphaRecal' in c) and 'weight' not in c]
print(output_columns)
# Infer SeqNr of objects that survived the AlphaRecal cuts
seqnr_alpharecal = obj_cat['SeqNr'].to_numpy()
# Infer indices of these objects in original catalogue
idx = np.where(np.isin(seqnr, seqnr_alpharecal, assume_unique=True))[0]
# Set up flag
flag_recal = np.full(len(seqnr), 0)
flag_recal[idx] = 1

# Output dataframe
df_out = pd.DataFrame(index=range(len(seqnr)))
# Fill with values
for c in output_columns:
    df_out.loc[idx, c] = obj_cat[c].to_numpy()
df_out.loc[np.arange(len(flag_recal)), 'flag_recal'] = flag_recal

print(df_out)
tstep = time.time()
table = Table.from_pandas(df_out)
print('Constructing astropy data table in', time.time() - tstep, 's')
tstep = time.time()
hdu=aif.BinTableHDU(data=table, name='OBJECTS')
print('Constructing hdu in', time.time() - tstep, 's')
hdu.writeto(outpath, overwrite=True)
print('Saving in', time.time() - tstep, 's')

print('number in final cata', len(obj_cat))
print('final results saved to', outpath)
print("timer: "+str(time.time()-tzero))

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

import numpy as np
import pandas as pd 
import numpy.linalg as la
import statsmodels.api as sm 

# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"step2_methodD.py: correct alpha in e1,2 with method D.",
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "--inpath", type=str,
    help="the in path for the catalogue.\n\
    supported formats: ldac")
parser.add_argument(
    "--outDir", type=str, 
    help="directory for the final catalogue.\n\
    outpath name will be inpath_name + _A2 or _A2_goldclasses")
parser.add_argument(
    "--col_goldFlag", type=str,
    help="columns to the redshift gold class in the catalogue.")
parser.add_argument(
    "--col_weight", type=str,
    help="columns to the weight in the catalogue.")
parser.add_argument(
    "--col_snr", type=str,
    help="columns to the SNR in the catalogue.")
parser.add_argument(
    "--col_ZB", type=str,
    help="columns to the Z_B in the catalogue.")
parser.add_argument(
    "--cols_e12", type=str, nargs=2, 
    help="column names for e1_gal, e2_gal.")
parser.add_argument(
    "--cols_psf_e12", type=str, nargs=2, 
    help="column names for e1_psf, e2_psf.")
parser.add_argument(
    "--Z_B_edges", type=float, nargs='*', default=None,
    help="edges for tomographic binning.")

## arg parser
args = parser.parse_args()
inpath = args.inpath
outDir = args.outDir

col_goldFlag = args.col_goldFlag
if col_goldFlag is not None:
    outpath = os.path.join(outDir, os.path.basename(inpath).replace('.cat', '_A2_goldclasses.cat'))
else:
    outpath = os.path.join(outDir, os.path.basename(inpath).replace('.cat', '_A2.cat'))

col_weight = args.col_weight
col_snr = args.col_snr
col_ZB = args.col_ZB
col_e1, col_e2 = args.cols_e12
col_psf_e1, col_psf_e2 = args.cols_psf_e12
Z_B_edges = np.array(args.Z_B_edges)
del args

# >>>>>>>>>>>>>>>>>>>>> workhorse

# ++++++ 0. load catalogue
ldac_cat = ldac.LDACCat(inpath)
obj_cat = ldac_cat['OBJECTS']

print('number original', len(obj_cat))
## only gold class
if col_goldFlag is not None:
    obj_cat = obj_cat.filter(obj_cat[col_goldFlag]>0)
    print('number after gold selection', len(obj_cat))
## only preserve weight > 0
obj_cat = obj_cat.filter((obj_cat[col_weight]>0))
print('number after weight selection', len(obj_cat))
## those out of ZB range are removed
obj_cat = obj_cat.filter((obj_cat[col_ZB]>Z_B_edges[0]) & (obj_cat[col_ZB]<=Z_B_edges[-1]))
print('number after Z_B selection', len(obj_cat))

# ++++++ 1. get alpha map 
start_time = time.time()

## number of bins
N_R = 20
N_SNR = 20

## start with R bin
obj_cat['bin_R'] = pd.qcut(obj_cat['R'], N_R, labels=False, retbins=False)

## then snr bin
obj_cat['bin_snr'] = np.zeros(len(obj_cat))-999
for ibin_R in range(N_R):

    # select catalogue
    mask_binR = (obj_cat['bin_R'] == ibin_R)

    # bin in R
    obj_cat['bin_snr'][mask_binR] = pd.qcut(obj_cat[col_snr][mask_binR], N_SNR, 
                                                labels=False, retbins=False)


## construct a temporary pandas df 
obj_df = pd.DataFrame({"bin_R":obj_cat['bin_R'].astype(np.int32),
                       "bin_snr":obj_cat["bin_snr"].astype(np.float64),
                       col_snr:obj_cat[col_snr].astype(np.float64),
                       col_weight:obj_cat[col_weight].astype(np.float64),
                       col_e1:obj_cat[col_e1].astype(np.float64),
                       col_e2:obj_cat[col_e2].astype(np.float64),
                       col_psf_e1:obj_cat[col_psf_e1].astype(np.float64),
                       col_psf_e2:obj_cat[col_psf_e2].astype(np.float64),
                       "R":obj_cat["R"].astype(np.float64)})

print(obj_df)

## group based on binning
cata_grouped = obj_df.groupby(by=['bin_R', 'bin_snr'])

## get the 2D alpha map
cata_alpha = cata_grouped.sum()
cata_alpha = cata_alpha[[col_weight]].copy()
cata_alpha.rename(columns={col_weight: 'total_weights'}, inplace=True)
for name, group in cata_grouped:

    # out shear
    e1_out = np.array(group[col_e1])
    e2_out = np.array(group[col_e2])
    weight_out = np.array(group[col_weight])

    # out PSF 
    e1_psf = np.array(group[col_psf_e1])
    e2_psf = np.array(group[col_psf_e2])

    # save center
    cata_alpha.loc[name, 'R_mean_wei'] = np.average(group['R'].values, weights=weight_out)
    cata_alpha.loc[name, 'SNR_mean_wei'] = np.average(group[col_snr].values, weights=weight_out)
    del group

    # calculate alpha using least square
    ## e1
    mod_wls = sm.WLS(e1_out, sm.add_constant(e1_psf), weights=weight_out)
    res_wls = mod_wls.fit()
    cata_alpha.loc[name, 'alpha1'] = res_wls.params[1]
    cata_alpha.loc[name, 'alpha1_err'] = (res_wls.cov_params()[1, 1])**0.5
    del e1_out, e1_psf, mod_wls, res_wls
    ## e2
    mod_wls = sm.WLS(e2_out, sm.add_constant(e2_psf), weights=weight_out)
    res_wls = mod_wls.fit()
    cata_alpha.loc[name, 'alpha2'] = res_wls.params[1]
    cata_alpha.loc[name, 'alpha2_err'] = (res_wls.cov_params()[1, 1])**0.5
    del e2_out, e2_psf, weight_out, mod_wls, res_wls

del cata_grouped
print('alpha map produced in', time.time() - start_time, 's')

# ++++++ 2. step1: fitting in whole and removing general trend
start_time = time.time()

## training model
# e1
fitting_weight = 1./np.square(cata_alpha['alpha1_err'].values)
A = np.vstack([fitting_weight * 1, 
                fitting_weight * np.power(cata_alpha['SNR_mean_wei'].values, -2),
                fitting_weight * np.power(cata_alpha['SNR_mean_wei'].values, -3),
                fitting_weight * cata_alpha['R_mean_wei'].values,
                fitting_weight * cata_alpha['R_mean_wei'].values * np.power(cata_alpha['SNR_mean_wei'].values, -2)]).T
poly1 = la.lstsq(A, fitting_weight * cata_alpha['alpha1'].values, rcond=None)[0] # poly coefficients
del fitting_weight, A
# e2
fitting_weight = 1./np.square(cata_alpha['alpha2_err'].values)
A = np.vstack([fitting_weight * 1, 
                fitting_weight * np.power(cata_alpha['SNR_mean_wei'].values, -2),
                fitting_weight * np.power(cata_alpha['SNR_mean_wei'].values, -3),
                fitting_weight * cata_alpha['R_mean_wei'].values,
                fitting_weight * cata_alpha['R_mean_wei'].values * np.power(cata_alpha['SNR_mean_wei'].values, -2)]).T
poly2 = la.lstsq(A, fitting_weight * cata_alpha['alpha2'].values, rcond=None)[0] # poly coefficients
del fitting_weight, A, cata_alpha

## remove the general trend
# e1
alpha = poly1[0] \
        + poly1[1] * np.power(obj_cat[col_snr], -2) \
        + poly1[2] * np.power(obj_cat[col_snr], -3) \
        + poly1[3] * obj_cat['R'] \
        + poly1[4] * obj_cat['R'] * np.power(obj_cat[col_snr], -2)
obj_cat['AlphaRecalD1_e1'] = np.zeros(len(obj_cat)).astype(np.float64)
obj_cat['AlphaRecalD1_e1'] = obj_cat[col_e1] - alpha * obj_cat[col_psf_e1]
del alpha, poly1
# e2
alpha = poly2[0] \
        + poly2[1] * np.power(obj_cat[col_snr], -2) \
        + poly2[2] * np.power(obj_cat[col_snr], -3) \
        + poly2[3] * obj_cat['R'] \
        + poly2[4] * obj_cat['R'] * np.power(obj_cat[col_snr], -2)
obj_cat['AlphaRecalD1_e2'] = np.zeros(len(obj_cat)).astype(np.float64)
obj_cat['AlphaRecalD1_e2'] = obj_cat[col_e2] - alpha * obj_cat[col_psf_e2]
del alpha, poly2

## meaningful e
mask_tmp = (obj_cat['AlphaRecalD1_e1']>-1) & (obj_cat['AlphaRecalD1_e1']<1) \
           & (obj_cat['AlphaRecalD1_e2']>-1) & (obj_cat['AlphaRecalD1_e2']<1)
print('number with meaningful e after D1', np.sum(mask_tmp), 'fraction', np.sum(mask_tmp)/len(obj_cat))
obj_cat = obj_cat.filter(mask_tmp)
del mask_tmp

print('D1 finished in', time.time() - start_time, 's')

# ++++++ 3. step2: direct correction for residual alpha
start_time = time.time()

# start with ZB bins
obj_cat['bin_ZB'] = pd.cut(obj_cat[col_ZB], Z_B_edges, 
                                    right=True, labels=False)

# then R and SNR
obj_cat['bin_R'] = np.zeros(len(obj_cat))-999
obj_cat['bin_snr'] = np.zeros(len(obj_cat))-999
for ibin_ZB in range(len(Z_B_edges)-1):

    # select catalogue
    mask_binZB = np.array(obj_cat['bin_ZB']) == ibin_ZB

    # bin in R
    obj_cat['bin_R'][mask_binZB] = pd.qcut(obj_cat['R'][mask_binZB], N_R, 
                                    labels=False, retbins=False)

    # in each R bin, do SNR binning
    for ibin_R in range(N_R):

        # select catalogue
        mask_binR = (obj_cat['bin_R'] == ibin_R)

        # bin in R
        obj_cat['bin_snr'][mask_binZB & mask_binR] = pd.qcut(obj_cat[col_snr][mask_binZB & mask_binR], N_SNR, 
                                                    labels=False, retbins=False)
        del mask_binR
    del mask_binZB

## construct a temporary pandas df 
obj_df = pd.DataFrame({"AlphaRecal_index":np.arange(len(obj_cat)),
                       "bin_R":obj_cat['bin_R'],
                       "bin_snr":obj_cat["bin_snr"],
                       "bin_ZB":obj_cat["bin_ZB"],
                       col_weight:obj_cat[col_weight],
                       "AlphaRecalD1_e1":obj_cat["AlphaRecalD1_e1"],
                       "AlphaRecalD1_e2":obj_cat["AlphaRecalD1_e2"],
                       col_psf_e1:obj_cat[col_psf_e1],
                       col_psf_e2:obj_cat[col_psf_e2],
                       "R":obj_cat["R"]})

# correct in each bin
cata_corr = []
for name, group in obj_df.groupby(by=['bin_ZB', 'bin_R', 'bin_snr']):

    # >>>>>>>>>>>>>>>> calculate alpha
    # unique index
    index_obj = group['AlphaRecal_index'].values
    # out shear
    e1_out = np.array(group["AlphaRecalD1_e1"])
    e2_out = np.array(group["AlphaRecalD1_e2"])
    weight_out = np.array(group[col_weight])
    # out PSF 
    e1_psf = np.array(group[col_psf_e1])
    e2_psf = np.array(group[col_psf_e2])
    del group
    # calculate alpha using least square
    ## e1
    mod_wls = sm.WLS(e1_out, sm.add_constant(e1_psf), weights=weight_out)
    res_wls = mod_wls.fit()
    alpha1 = res_wls.params[1]
    del res_wls, mod_wls
    ## e2
    mod_wls = sm.WLS(e2_out, sm.add_constant(e2_psf), weights=weight_out)
    res_wls = mod_wls.fit()
    alpha2 = res_wls.params[1]
    del weight_out, res_wls, mod_wls

    # >>>>>>>>>>>>>>>> correct 
    e1_corr = e1_out - alpha1 * e1_psf
    e2_corr = e2_out - alpha2 * e2_psf
    del e1_out, alpha1, e1_psf, e2_out, alpha2, e2_psf

    # >>>>>>>>>>>>>>>> save
    cata_tmp = pd.DataFrame({'AlphaRecal_index': index_obj, 
                            'AlphaRecalD2_e1': e1_corr,
                            'AlphaRecalD2_e2': e2_corr})
    del index_obj, e1_corr, e2_corr
    cata_corr.append(cata_tmp)
    del cata_tmp
cata_corr = pd.concat(cata_corr)

# meaningful e
mask_tmp = (cata_corr['AlphaRecalD2_e1']>-1) & (cata_corr['AlphaRecalD2_e1']<1) \
           & (cata_corr['AlphaRecalD2_e2']>-1) & (cata_corr['AlphaRecalD2_e2']<1)
print('number with meaningful e after D2', np.sum(mask_tmp), 'fraction', np.sum(mask_tmp)/len(cata_corr))
cata_corr = cata_corr[mask_tmp]
del mask_tmp

# merge
obj_cat['AlphaRecalD2_e1'] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat['AlphaRecalD2_e2'] = np.zeros(len(obj_cat)).astype(np.float64) 
obj_cat['AlphaRecalD2_e1'][cata_corr['AlphaRecal_index']] = cata_corr['AlphaRecalD2_e1'] 
obj_cat['AlphaRecalD2_e2'][cata_corr['AlphaRecal_index']] = cata_corr['AlphaRecalD2_e2'] 
del cata_corr
print('D2 finished in', time.time() - start_time, 's')

# save
ldac_cat['OBJECTS']=obj_cat
if os.path.exists(outpath):
    os.remove(outpath)
ldac_cat.saveas(outpath)
print('number in final cata', len(obj_cat))
print('final results saved to', outpath)
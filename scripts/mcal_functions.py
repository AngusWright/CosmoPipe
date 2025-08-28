#=========================================
#
# File Name : mcal_functions.py
# Created By : awright
# Creation Date : 25-05-2023
# Last Modified : Thu 17 Jul 2025 11:32:55 AM CEST
#
#=========================================

#Required packages 
print("importing")
import numpy as np
import pandas as pd
import statsmodels.api as sm 
from astropy.io import fits
from astropy.table import Table
import ldac 
import os
import astropandas as apd

#Functions used for m-calibration pipeline 
#Flexible file read {{{
def flexible_read(filepath,as_df=True): 
    print("reading:",filepath)
    #Get the file extension 
    file_extension=filepath.split(".")[-1]
    if file_extension == 'csv':
        #Read CSV with pandas 
        print("reading as CSV")
        ldac_cat=None
        cata = pd.read_csv(filepath)
    elif file_extension == 'asc':
        #Read ASCII with pandas 
        print("reading as ASCII")
        ldac_cat=None
        cata = pd.read_csv(filepath)
    elif file_extension == 'feather':
        #Read feather with pandas 
        print("reading as feather")
        ldac_cat=None
        cata = pd.read_feather(filepath)
    elif file_extension == 'parquet':
        #Read parquet with pandas 
        print("reading as parquet")
        ldac_cat=None
        cata = pd.read_parquet(filepath)
    elif file_extension == 'fits' or file_extension == 'cat':
        #If FITS, try ldac first 
        try:
            #Read LDAC with ldac tools
            ldac_cat = ldac.LDACCat(filepath)
            cata = ldac_cat['OBJECTS']
            print("reading as LDAC")
            if as_df: 
                #Convert the catalogue to a pandas data frame 
                cata=pd.DataFrame(cata.hdu.data)
        except Exception:
            #If that fails, read with fits 
            print("reading as FITS")
            ldac_cat=None
            cata = apd.read_fits(filepath)
    else:
        #Error if not supported 
        raise Exception(f'Not supported input file type! {filepath}\nMust be one of csv/fits/cat/feather.')
    #Convert 32 bit cols to 64bit 
    if isinstance(cata, pd.DataFrame):
        if any(cata.dtypes=="float32"): 
            cata.loc[:,cata.dtypes=="float32"]=cata.loc[:,cata.dtypes=="float32"].astype(float)
        for key in cata.keys():
            if ">" in str(cata[key].dtype):
                cata[key]=cata[key].astype(str(cata[key].dtype).replace(">","<"))
            if "<" in str(cata[key].dtype):
                cata[key]=cata[key].astype(str(cata[key].dtype).replace("<",">"))
    #Return the catalogue 
    return cata, ldac_cat
#}}}

#Flexible file write {{{
def flexible_write(cata,filepath,ldac_cat=None,table_name='OBJECTS'): 
    #Get the file extension 
    file_extension=filepath.split(".")[-1]
    if file_extension == 'csv':
        #Write CSV with pandas 
        if not isinstance(cata, pd.DataFrame):
            raise Exception("catalogue 'cata' must be a pandas data.frame for CSV write")
        cata.to_csv(filepath)
    elif file_extension == 'asc':
        #Write ASCII with pandas 
        if not isinstance(cata, pd.DataFrame):
            raise Exception("catalogue 'cata' must be a pandas data.frame for ascii write")
        cata.to_csv(filepath)
    elif file_extension == 'feather':
        #Write feather with pandas 
        if not isinstance(cata, pd.DataFrame):
            raise Exception("catalogue 'cata' must be a pandas data.frame for feather write")
        cata = pd.to_feather(filepath)
    elif file_extension == 'cat' and not ldac_cat is None:
        #Write LDAC with ldac tools
        print("Writing .cat file as LDAC")
        if isinstance(cata, pd.DataFrame):
            #Check ordering 
            if any(ldac_cat[table_name]['SeqNr']!=cata['SeqNr']):
                raise Exception("catalogue 'cata' is not ordered to match SeqNr")
            #Check the catalogue keys 
            ldac_keys=ldac_cat[table_name].keys()
            cata_keys=cata.keys()
            #Loop over the catalogue keys 
            for key in cata_keys: 
                #Do we need to update the ldac catalogue 
                if key in ldac_keys: 
                    print(f"Checking key {key}")
                    #Do we need to update a catalogue column?
                    if type(ldac_cat[table_name][key]) == np.chararray: 
                        charvec=cata[key].to_numpy().astype(str)
                        if any(ldac_cat[table_name][key]!=charvec): 
                            print(f"Updating charachter key {key}")
                            #Update it 
                            ldac_cat[table_name][key]=charvec 
                        del charvec 
                    else: 
                        if any(ldac_cat[table_name][key]!=cata[key]): 
                            print(f"Updating non-charachter key {key}")
                            #Update it 
                            ldac_cat[table_name][key]=cata[key]
                else: 
                    print(f"Adding key {key}")
                    #Add the column 
                    ldac_cat[table_name][key]=cata[key]

        #Rejoin the ldac object and data catalogue
        #ldac_cat['OBJECTS']=cata
        ldac_cat[table_name].update=1
        #Delete existing file
        if os.path.exists(filepath):
            print("Deleting old LDAC file")
            os.remove(filepath)
        #Write to LDAC
        print("Writing")
        ldac_cat.saveas(filepath)
    elif file_extension == 'fits' and not ldac_cat is None:
        #Write LDAC with ldac tools
        print("Writing .fits file as LDAC")
        if isinstance(cata, pd.DataFrame):
            #Check ordering 
            if any(ldac_cat[table_name]['SeqNr']!=cata['SeqNr']):
                raise Exception("catalogue 'cata' is not ordered to match SeqNr")
            #Check the catalogue keys 
            ldac_keys=ldac_cat[table_name].keys()
            cata_keys=cata.keys()
            #Loop over the catalogue keys 
            for key in cata_keys: 
                #Do we need to update the ldac catalogue 
                if key in ldac_keys: 
                    print(f"Checking key {key}")
                    #Do we need to update a catalogue column?
                    if type(ldac_cat[table_name][key]) == np.chararray: 
                        charvec=cata[key].to_numpy().astype(str)
                        if any(ldac_cat[table_name][key]!=charvec): 
                            print(f"Updating charachter key {key}")
                            #Update it 
                            ldac_cat[table_name][key]=charvec 
                        del charvec 
                    else: 
                        if any(ldac_cat[table_name][key]!=cata[key]): 
                            print(f"Updating non-charachter key {key}")
                            #Update it 
                            ldac_cat[table_name][key]=cata[key]
                else: 
                    print(f"Adding key {key}")
                    #Add the column 
                    ldac_cat[table_name][key]=cata[key]

        #Rejoin the ldac object and data catalogue
        #ldac_cat['OBJECTS']=cata
        ldac_cat[table_name].update=1
        #Delete existing file
        if os.path.exists(filepath):
            print("Deleting old LDAC file")
            os.remove(filepath)
        #Write to LDAC
        print("Writing")
        ldac_cat.saveas(filepath)
    elif file_extension == 'cat' and ldac_cat is None:
        print("Writing .cat file as FITS")
        apd.to_fits(cata, filepath)
    elif file_extension == 'fits' and ldac_cat is None:
        print("Writing .fits file as FITS")
        apd.to_fits(cata, filepath)
    else:
        #Error if not supported 
        raise Exception(f'Not supported input file type! {filepath}\nMust be one of csv/fits/cat/feather.')
    #Return nothing 
    return 
#}}}

def _WgQuantile1DFunc_SNR_R(values, weights, Nbin): #{{{
    """
    Calculate the weighted quantile by given bin numbers
        designed for 1D numpy array.
    """

    # Define the quantile points based on the number of bins
    pq = np.linspace(0, 1, Nbin+1)

    # Sort the data
    ind_sorted = np.argsort(values)
    v_sorted = values[ind_sorted]
    wg_sorted = weights[ind_sorted]
    del ind_sorted, values, weights

    # Compute the quantiles
    Pn = (np.cumsum(wg_sorted) - 0.5*wg_sorted)/np.sum(wg_sorted)

    # interp the quantiles
    res = np.interp(pq, Pn, v_sorted)

    # include all points
    res[0] = 0.
    res[-1] = 999.
    return res
#}}}

def _WgBin2DFunc_SNR_R(v1, v2, wgs, Nbin1, Nbin2, right=True): #{{{
    """
    Calculate the weighted quantile by given bin numbers
        designed for 2D numpy array
    """

    # Calculate quantiles for v1
    q1 = _WgQuantile1DFunc_SNR_R(v1, wgs, Nbin1)

    #Compute quantiles for v2 in each v1 bin
    q2s = np.zeros((Nbin1, Nbin2+1))
    for i in range(Nbin1):

        if right:
            mask = (v1>q1[i]) & (v1<=q1[i+1])
        else:
            mask = (v1>=q1[i]) & (v1<q1[i+1])

        q2s[i] = _WgQuantile1DFunc_SNR_R(v2[mask], wgs[mask], Nbin2)

    return q1, q2s
#}}}

def mCalFunc_tile_based(cataSim, psf_frame=False): #{{{
    """
    NOTE: this can only be used when 
        1. the input shear are constant across the tile image
        2. number of tiles are sufficient large

    Calculate the residual shear bias for a given simulated catalogue
        it first calculates shear g_out for each tile (accounting for shape noise cancellation)
            then estimate bias using all tiles and shear inputs by requiring sum(g_out - (1+m)g_in) -> min

        Used columns and their names:
            tile_label: unique label for tile
            g1_in, g2_in: input shear
            e1_out, e2_out: measured ellipticity
            shape_weight: shape measurement weights
            if psf_frame:
                e1_psf, e2_psf: ellipticity of PSF
    """

    # out gal e
    e1_out = np.array(cataSim['e1_out'])
    e2_out = np.array(cataSim['e2_out'])

    # rotate to psf frame
    if psf_frame:
        print('Measured e will be rotated to PSF frame...')
        # out PSF 
        e1_psf = np.array(cataSim['e1_psf'])
        e2_psf = np.array(cataSim['e2_psf'])
        PSF_angle = np.arctan2(e2_psf, e1_psf)

        # rotate the ellipticities
        ct = np.cos(PSF_angle)
        st = np.sin(PSF_angle)
        e1_uc = e1_out*ct + e2_out*st
        e2_uc = -e1_out*st + e2_out*ct
        del e1_psf, e2_psf, PSF_angle, ct, st

        e1_out = e1_uc
        e2_out = e2_uc
        del e1_uc, e2_uc

    # build dataframe and select used columns
    cataSim = pd.DataFrame({'tile_label': np.array(cataSim['tile_label']),
                            'g1_in': np.array(cataSim['g1_in']),
                            'g2_in': np.array(cataSim['g2_in']),
                            'e1_out': e1_out,
                            'e2_out': e2_out,
                            'shape_weight': np.array(cataSim['shape_weight'])
                            })
    del e1_out, e2_out

    # sort to speed up
    cataSim.sort_values(by=['tile_label', 'g1_in', 'g2_in'], inplace=True)

    # prepare the weighted mean
    cataSim.loc[:, 'e1_out'] *= cataSim['shape_weight'].values
    cataSim.loc[:, 'e2_out'] *= cataSim['shape_weight'].values

    # group based on tile and shear
    cataSim = cataSim.groupby(['tile_label', 'g1_in', 'g2_in'], as_index=False).sum()
    if len(cataSim) < 10:
        raise Exception('less than 10 points for lsq, use pair_based!')
    # print('number of groups (points) for lsq', len(cataSim))
    ## last step of the weighted mean
    cataSim.loc[:, 'e1_out'] /= cataSim['shape_weight'].values
    cataSim.loc[:, 'e2_out'] /= cataSim['shape_weight'].values

    # get least square values
    ## e1
    mod_wls = sm.WLS(cataSim['e1_out'].values, 
                     sm.add_constant(cataSim['g1_in'].values,has_constant='add'),
                     weights=cataSim['shape_weight'].values)
    res_wls = mod_wls.fit() 
    #print(res_wls.summary())
    print("m1params: ",res_wls.params)
    m1 = res_wls.params[1] - 1
    c1 = res_wls.params[0]
    m1_err = (res_wls.cov_params()[1, 1])**0.5
    c1_err = (res_wls.cov_params()[0, 0])**0.5
    ## e2
    mod_wls = sm.WLS(cataSim['e2_out'].values, 
                        sm.add_constant(cataSim['g2_in'].values,has_constant='add'), 
                        weights=cataSim['shape_weight'].values)
    res_wls = mod_wls.fit()
    print("m2params: ",res_wls.params)
    m2 = res_wls.params[1] - 1
    c2 = res_wls.params[0]
    m2_err = (res_wls.cov_params()[1, 1])**0.5
    c2_err = (res_wls.cov_params()[0, 0])**0.5

    # save
    del cataSim
    res = {'m1': m1, 'm2': m2,
            'c1': c1, 'c2': c2,
            'm1_err': m1_err, 'm2_err': m2_err,
            'c1_err': c1_err, 'c2_err': c2_err,
            }

    return res
#}}}

def mCalFunc_pair_based(cataSim): #{{{

    # build dataframe and select used columns
    cataSim = cataSim[['id_input', 'g1_in', 'g2_in', 'e1_out', 'e2_out', 'shape_weight']].copy()

    # sort to speed up
    cataSim.sort_values(by=['id_input', 'g1_in', 'g2_in'], inplace=True)

    # prepare the weighted mean
    cataSim.loc[:, 'e1_out'] *= cataSim['shape_weight'].values
    cataSim.loc[:, 'e2_out'] *= cataSim['shape_weight'].values

    # group based on tile and shear
    cataSim = cataSim.groupby(['id_input', 'g1_in', 'g2_in'], as_index=False).sum()
    if len(cataSim) < 3:
        raise Exception('less than 3 points for lsq, use pair_based!')
    print('number of groups (points) for lsq', len(cataSim))
    ## last step of the weighted mean
    cataSim.loc[:, 'e1_out'] /= cataSim['shape_weight'].values
    cataSim.loc[:, 'e2_out'] /= cataSim['shape_weight'].values

    # get least square values
    ## e1
    mod_wls = sm.WLS(cataSim['e1_out'].values, \
                        sm.add_constant(cataSim['g1_in'].values), \
                        weights=cataSim['shape_weight'].values)
    res_wls = mod_wls.fit()
    m1 = res_wls.params[1] - 1
    c1 = res_wls.params[0]
    m1_err = (res_wls.cov_params()[1, 1])**0.5
    c1_err = (res_wls.cov_params()[0, 0])**0.5
    ## e2
    mod_wls = sm.WLS(cataSim['e2_out'].values, \
                        sm.add_constant(cataSim['g2_in'].values), \
                        weights=cataSim['shape_weight'].values)
    res_wls = mod_wls.fit()
    m2 = res_wls.params[1] - 1
    c2 = res_wls.params[0]
    m2_err = (res_wls.cov_params()[1, 1])**0.5
    c2_err = (res_wls.cov_params()[0, 0])**0.5

    # save
    res = {'m1': m1, 'm2': m2,
            'c1': c1, 'c2': c2,
            'm1_err': m1_err, 'm2_err': m2_err,
            'c1_err': c1_err, 'c2_err': c2_err}

    return res
#}}}

def minmax_to_bins(cat,var,index=None): #{{{
    #Takes column name "var" and constructs bin limits from the unique entries of "var_min" and "var_max"
    if index is None: 
        limits=np.unique(cat.loc[:,var+'_min']).tolist()+[np.max(cat.loc[:,var+'_max'])]
    else: 
        limits=np.unique(cat.loc[index,var+'_min']).tolist()+[np.max(cat.loc[index,var+'_max'])]
    print(limits)
    return limits

#}}}

def binby_SNR_R(surface,cata,SNRname,Rname): #{{{
    # define the SNR bin edges 
    SNR_edges = minmax_to_bins(surface,'bin_SNR')
    # bin the catalogue 
    cata.loc[:, 'bin_SNR_id'] = pd.cut(cata.loc[:, SNRname].values, SNR_edges, 
                                right=True, labels=False)
    #Loop over SNR bins 
    for i_SNR in range(len(SNR_edges)-1):
        #Define the R bin edges, in this bin of SNR
        R_edges = minmax_to_bins(surface,'bin_R',index=(surface['bin_SNR_id']==i_SNR))

        # Get the sources in this SNR bin 
        mask_bin_SNR = (cata['bin_SNR_id'].values == i_SNR)
        #Bin by R
        cata.loc[mask_bin_SNR, 'bin_R_id'] = pd.cut(
                                    cata.loc[mask_bin_SNR, Rname].values, 
                                    R_edges, 
                                    right=True, labels=False)
        del mask_bin_SNR

    if any(np.isinf(cata['bin_SNR_id'])): 
        print(f"WARNING: there is/are {len(np.where(np.isinf(cata['bin_SNR_id'])))} infinite SNR index/s")
        cata.loc[np.isinf(cata['bin_SNR_id']),'bin_SNR_id']=-999
    if any(np.isinf(cata['bin_R_id'])): 
        print(f"WARNING: there is/are {len(np.where(np.isinf(cata['bin_R_id'])))} infinite R index/s")
        cata.loc[np.isinf(cata['bin_R_id']),'bin_R_id']=-999
    if any(np.isnan(cata['bin_SNR_id'])): 
        print(f"WARNING: there is/are {len(np.where(np.isnan(cata['bin_SNR_id'])))} NaN SNR index/s")
        cata.loc[np.isnan(cata['bin_SNR_id']),'bin_SNR_id']=-999
    if any(np.isnan(cata['bin_SNR_id'])): 
        print(f"WARNING: there is/are {len(np.where(np.isnan(cata['bin_R_id'])))} NaN R index/s")
        cata.loc[np.isnan(cata['bin_R_id']),'bin_R_id']=-999
    #Return the catalogue 
    return cata 

#}}}

def e12_from_g12(cata,col_e12,col_g12): #{{{
    g = np.array(cata[col_g12[0]]) + 1j*np.array(cata[col_g12[1]])
    e_in_gal = np.array(cata[col_e12[0]]) + 1j*np.array(cata[col_e12[1]])
    e_true = (e_in_gal+g) / (1+np.conj(g)*e_in_gal)

    e1_out = (e_true.real).astype(float)
    e2_out = (e_true.imag).astype(float)

    return e1_out,e2_out
#}}}

def mCalFunc_from_surface(cata, surface,col_SNR, col_R, col_weight, col_m1, col_m2): #{{{
    """
    Calculate the shear bias for a given catalogue
        It first splits galaxies into bins based on their SNR, R
            then assign each galaxy a m using the m calibration surface
        The final results are the weighted average of individual m

    Parameters:
    -----------
    cata : catalogue of the data for which the mean m is calculated
    surface : catalogue of the surface of doom with shear bias and binning info
    col_SNR : column name for the signal-to-noise ratio
    col_R : column name for the resolution factor
    col_weight: column name for the measurement weight
    col_m1 : column name for m1 in the surface of doom
    col_m2 : column name for m2 in the surface of doom
    """

    # used columns from data cata
    cata = pd.DataFrame({'SNR': np.array(cata[col_SNR]).astype(float),
                         'R': np.array(cata[col_R]).astype(float),
                         'weight': np.array(cata[col_weight]).astype(float),
                         'bin_SNR_id': -999, 'bin_R_id': -999})

    # used columns from surface of doom
    surface = pd.DataFrame({'bin_SNR_id': np.array(surface['bin_SNR_id']).astype(int),
                        'bin_R_id': np.array(surface['bin_R_id']).astype(int),
                        'bin_SNR_min': np.array(surface['bin_SNR_min']).astype(float),
                        'bin_SNR_max': np.array(surface['bin_SNR_max']).astype(float),
                        'bin_R_min': np.array(surface['bin_R_min']).astype(float),
                        'bin_R_max': np.array(surface['bin_R_max']).astype(float),
                        'm1': np.array(surface[col_m1]).astype(float),
                        'm1_err': np.array(surface[f'{col_m1}_err']).astype(float),
                        'm2': np.array(surface[col_m2]).astype(float),
                        'm2_err': np.array(surface[f'{col_m2}_err']).astype(float),
                        'data_wgt': 0 
                        })

    # bin galaxies
    cata = binby_SNR_R(surface,cata,col_SNR,col_R)

    # the indexes of sources with good binning 
    #print(cata['bin_SNR_id'].values)
    #print(cata['bin_SNR_id'].values!=-999)
    good_id = (cata['bin_SNR_id'].values!=-999) & (cata['bin_R_id'].values!=-999) 

    # group
    ## sort to speed up
    cata = cata.astype({'bin_SNR_id': int, 'bin_R_id': int})
    cata.sort_values(by=['bin_SNR_id', 'bin_R_id'], inplace=True)
    cata = cata.groupby(by=['bin_SNR_id', 'bin_R_id'])

    # loop over groups to get mean m
    m1_final = 0 
    m1_err_final = 0
    m2_final = 0 
    m2_err_final = 0
    wgRealSum = 0 
    for name, group in cata:
        bin_SNR_id, bin_R_id = name

        # total weights in each bin
        wgRealBin = np.sum(group['weight'].values)
        wgRealSum += wgRealBin

        # m from surface 
        mask_surf = (surface['bin_SNR_id']==bin_SNR_id)\
                   &(surface['bin_R_id']==bin_R_id)
        if len(surface.loc[mask_surf, 'm1'])==0:
            print(f"THERE IS NO SURFACE ELEMENT FOR SNR_BIN {bin_SNR_id} AND R_BIN {bin_R_id}?!")
            continue 

        surface.loc[mask_surf,'data_wgt'] += wgRealBin
        #print(mask_surf)
        #print(surface.loc[mask_surf, 'm1'])
        m1_final += (wgRealBin * surface.loc[mask_surf, 'm1'].values[0])
        m2_final += (wgRealBin * surface.loc[mask_surf, 'm2'].values[0])
        m1_err_final += (wgRealBin * surface.loc[mask_surf, 'm1_err'].values[0])**2
        m2_err_final += (wgRealBin * surface.loc[mask_surf, 'm2_err'].values[0])**2

    # take the mean
    m1_final = m1_final / wgRealSum
    m2_final = m2_final / wgRealSum
    m1_err_final = m1_err_final**0.5 / wgRealSum
    m2_err_final = m2_err_final**0.5 / wgRealSum
    return (m1_final, m2_final, m1_err_final, m2_err_final, good_id, wgRealSum,surface)
#}}}


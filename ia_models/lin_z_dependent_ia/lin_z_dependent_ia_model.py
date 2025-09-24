from __future__ import print_function
from builtins import range
from cosmosis.datablock import option_section, names
import numpy as np

"""
This module requires that the NLA intrinsic alignments have been calculated using a=1. 
It then reads the 
"""


def setup(options):
    suffix = options.get_string(option_section, "suffix", "")
    new_suffix = options.get_string(option_section, "new_suffix", "")
    sample = options.get_string(option_section, "sample", "")
    do_shear_shear = options.get_bool(option_section, "do_shear_intrinsic", True)
    do_position_shear = options.get_bool(option_section, "do_galaxy_intrinsic", False)

    if suffix:
        suffix = "_" + suffix
    
    if new_suffix:
        new_suffix = "_" + new_suffix

    return new_suffix, suffix, sample, do_shear_shear, do_position_shear


def execute(block, config):
    new_suffix, suffix, sample, do_shear_shear, do_position_shear = config

    parameters = "intrinsic_alignment_parameters" + suffix

    a_in  = block[parameters,"a"]
    if a_in != 1.0:
        raise Exception("Please set a in "+parameters+" to 1.")

    A_IA  = block[parameters,"a_ia"]
    B_IA  = block[parameters,"b_ia"]
    a_piv = block[parameters,"a_piv"]

    if do_shear_shear:
        shear_intrinsic = 'shear_cl_gi'+suffix
        intrinsic_intrinsic = 'shear_cl_ii'+suffix
        shear_intrinsic_new = 'shear_cl_gi'+new_suffix
        intrinsic_intrinsic_new = 'shear_cl_ii'+new_suffix
    
        nbins = block[shear_intrinsic, 'nbin_a']
    
        # calcualte a_mean from the redshift distributions:
        try:
            a_mean = [block[parameters, "a_mean_"+ str(i + 1)] for i in range(nbins)]
            a_mean_source = 'values file'
        except:
            a_mean = []
            for i in range(nbins):
                bin_name = "bin_" +str(i+1)
                nz = block['nz_'+sample, bin_name]
                z  = block['nz_'+sample, "z"]
                # Calculate the mean scale factor per bin
                a_m = np.average(1/(1+z), weights=nz)
                a_mean.append(a_m)
                a_mean_source = 'input nz from '+sample
        block[intrinsic_intrinsic,'a_mean'] = a_mean
        block[shear_intrinsic,'a_mean'] = a_mean
        block[intrinsic_intrinsic,'a_mean_source'] = a_mean_source
    
        for i in range(nbins):
            for j in range(i + 1):
                bin_ij = 'bin_'+str(i+1)+'_'+str(j+1)
                bin_ji = 'bin_'+str(j+1)+'_'+str(i+1)
                # only works if a is set to one in the parameters
                coef_i = (A_IA + B_IA * (a_mean[i]/a_piv -1))
                coef_j = (A_IA + B_IA * (a_mean[j]/a_piv -1))
                # block[intrinsic_intrinsic, bin_ij] *= coef_i * coef_j
                # block[shear_intrinsic, bin_ij] *= coef_j
                # block[shear_intrinsic, bin_ji] *= coef_i
                block[intrinsic_intrinsic_new, bin_ij] = coef_i * coef_j * block[intrinsic_intrinsic, bin_ij]
                block[shear_intrinsic_new, bin_ij] = coef_j  * block[shear_intrinsic, bin_ij]
                block[shear_intrinsic_new, bin_ji] = coef_i  * block[shear_intrinsic, bin_ji]
                
    if do_position_shear:
        galaxy_intrinsic = 'galaxy_intrinsic_cl'+suffix
        galaxy_intrinsic_new = 'galaxy_intrinsic_cl'+new_suffix
    
        nbins_a = block[shear_intrinsic, 'nbin_a']
        nbins_b = block[shear_intrinsic, 'nbin_b']
    
        # calcualte a_mean from the redshift distributions:
        try:
            a_mean = [block[parameters, "a_mean_"+ str(i + 1)] for i in range(nbins_b)]
            a_mean_source = 'values file'
        except:
            a_mean = []
            for i in range(nbins_b):
                bin_name = "bin_" +str(i+1)
                nz = block['nz_'+sample, bin_name]
                z  = block['nz_'+sample, "z"]
                # Calculate the mean scale factor per bin
                a_m = np.average(1/(1+z), weights=nz)
                a_mean.append(a_m)
                a_mean_source = 'input nz from '+sample
        block[galaxy_intrinsic,'a_mean'] = a_mean
        block[galaxy_intrinsic,'a_mean_source'] = a_mean_source
    
        for i in range(nbins_a):
            for j in range(nbins_b):
                bin_ij = 'bin_'+str(i+1)+'_'+str(j+1)
                # only works if a is set to one in the parameters
                coef_j = (A_IA + B_IA * (a_mean[j]/a_piv -1))
                block[galaxy_intrinsic_new, bin_ij] = coef_j * block[galaxy_intrinsic, bin_ij]
    

    return 0

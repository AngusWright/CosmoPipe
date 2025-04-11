from __future__ import print_function
from builtins import range
from cosmosis.datablock import option_section, names
import numpy as np

"""
NLA model, early-type only, no redshift dependence, with mass dependent alignment
NLA pre-factor changes to: 
A_{IA, total}^(i) = A_IA -> A_IA* f_r^(i) * (<M_*>^(i) / M_{*, pivot})^beta, 
Parameters: A_IA with informative prior; beta with narrow informative prior
Inputs: 
f_r^(i): fraction of early-type galaxies per tomo_bin from catalogue via T_B
<M_*>^(i): mean stellar mass of early-type galaxies per tomo bin from catalogue
prior on beta: mass scaling prediction from Piras et al. (2018), translated to M_* and propagating uncertainty
prior on A_IA: constraints from Fortuna et al., in prep. + uncertainty propagation in stellar mass measurements and T_B
M_{*, pivot}: derive from mean stellar mass of early-type galaxies with M_r=-22 in KiDS-Legacy
"""


def setup(options):
    suffix = options.get_string(option_section, "suffix", "")
    new_suffix = options.get_string(option_section, "new_suffix", "")
    do_shear_shear = options.get_bool(option_section, "do_shear_intrinsic", True)
    do_position_shear = options.get_bool(option_section, "do_galaxy_intrinsic", False)

    if suffix:
        suffix = "_" + suffix
    
    if new_suffix:
        new_suffix = "_" + new_suffix

    return new_suffix, suffix, do_shear_shear, do_position_shear


def execute(block, config):
    new_suffix, suffix, do_shear_shear, do_position_shear = config

    parameters = "intrinsic_alignment_parameters" + suffix

    beta  = block[parameters,"beta"]
    log10_M_piv = block[parameters,"log10_M_piv"]
    M_piv = 10 ** log10_M_piv


    if do_shear_shear:
        nbins = block[shear_intrinsic, 'nbin_a']
        # calcualte a_mean from the redshift distributions:
        M_mean = [(10 ** block[parameters, "log10_M_mean_"+ str(i + 1)]) for i in range(nbins)]
        f_r    = [block[parameters, "f_r_"+ str(i + 1)] for i in range(nbins)]
    
        shear_intrinsic = 'shear_cl_gi'+suffix
        intrinsic_intrinsic = 'shear_cl_ii'+suffix
        shear_intrinsic_new = 'shear_cl_gi'+new_suffix
        intrinsic_intrinsic_new = 'shear_cl_ii'+new_suffix
    
        block[intrinsic_intrinsic,'M_mean'] = M_mean
        block[shear_intrinsic,'M_mean'] = M_mean
    
        block[intrinsic_intrinsic,'M_piv'] = M_piv
        block[shear_intrinsic,'M_piv'] = M_piv
    
        block[intrinsic_intrinsic,'f_r'] = f_r
        block[shear_intrinsic,'f_r'] = f_r
    
        block[intrinsic_intrinsic,'model'] = 'mass_dependent IA'
        block[shear_intrinsic,'model'] = 'mass_dependent IA'
    
    
        for i in range(nbins):
            for j in range(i + 1):
                bin_ij = 'bin_'+str(i+1)+'_'+str(j+1)
                bin_ji = 'bin_'+str(j+1)+'_'+str(i+1)
                # only works if a is set to one in the parameters
                coef_i = f_r[i] * np.power((M_mean[i] / M_piv), beta)
                coef_j = f_r[j] * np.power((M_mean[j] / M_piv), beta)
                # block[intrinsic_intrinsic, bin_ij] *= coef_i * coef_j
                # block[shear_intrinsic, bin_ij] *= coef_j
                # block[shear_intrinsic, bin_ji] *= coef_i
                block[intrinsic_intrinsic_new, bin_ij] = coef_i * coef_j * block[intrinsic_intrinsic, bin_ij]
                block[shear_intrinsic_new, bin_ij] = coef_j * block[shear_intrinsic, bin_ij]
                block[shear_intrinsic_new, bin_ji] = coef_i * block[shear_intrinsic, bin_ji]
    
    if do_position_shear:
        nbins_a = block[shear_intrinsic, 'nbin_a']
        nbins_b = block[shear_intrinsic, 'nbin_b']
        # calcualte a_mean from the redshift distributions:
        M_mean = [(10 ** block[parameters, "log10_M_mean_"+ str(i + 1)]) for i in range(nbins_b)]
        f_r    = [block[parameters, "f_r_"+ str(i + 1)] for i in range(nbins_b)]

        galaxy_intrinsic = 'galaxy_intrinsic_cl'+suffix
        galaxy_intrinsic_new = 'galaxy_intrinsic_cl'+new_suffix
        
        block[galaxy_intrinsic,'M_mean'] = M_mean
        block[galaxy_intrinsic,'M_piv'] = M_piv
        block[galaxy_intrinsic,'f_r'] = f_r
        block[galaxy_intrinsic,'model'] = 'mass_dependent IA'
    
        for i in range(nbins_a):
            for j in range(nbins_b):
                bin_ij = 'bin_'+str(i+1)+'_'+str(j+1)
                # only works if a is set to one in the parameters
                coef_j = f_r[j] * np.power((M_mean[j] / M_piv), beta)
            
                block[galaxy_intrinsic_new, bin_ij] = coef_j * block[galaxy_intrinsic, bin_ij]

    return 0

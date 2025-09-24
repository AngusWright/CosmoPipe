  #!/usr/bin/env python
# -*- coding: utf-8 -*-


import time
import multiprocessing as multi
import numpy as np
import matplotlib.pyplot as pl
import scipy
from scipy.integrate import simps, trapz, cumtrapz
from scipy.interpolate import interp1d, UnivariateSpline
import scipy.special as sp
import astropy.io.fits as fits
from astropy.units import eV
import astropy.units as u
from astropy.cosmology import FlatLambdaCDM, Flatw0waCDM, LambdaCDM, z_at_value
from astropy.stats import sigma_clip
import scipy.stats as ss
from scipy.signal import find_peaks
from scipy.stats import gaussian_kde
from sklearn.neighbors import KernelDensity
import matplotlib.patheffects as pe
import matplotlib.patches as mpatches
from matplotlib.patches import Rectangle



if __name__ == '__main__':


    parser = argparse.ArgumentParser(description='Cut given binning limits by the lower and upper stellar mass limit.')
    parser.add_argument('--mass_lo', type=float, help='Low stellar mass limit', nargs='?', default=12.0, const=12.0)
    parser.add_argument('--mass_hi', type=float, help='High stellar mass limit', nargs='?', default=12.0, const=12.0)
    parser.add_argument('--z_lo', type=float, help='Low redshift limit', nargs='?', default=0.0, const=0.0)
    parser.add_argument('--z_hi', type=float, help='High redshift limit', nargs='?', default=0.0, const=0.0)
    parser.add_argument('--lowlimfile', type=str, help='Input file for low mass lim function', default='mass_lim_low.npy', required=True)
    parser.add_argument('--highlimfile', type=str, help='Input file for high mass lim function', default='mass_lim.npy', required=True)
    args = parser.parse_args()
    
    
    
    mass_lo = args.mass_lo
    mass_hi = args.mass_hi
    z_lo = args.z_lo
    z_hi = args.z_hi
    
    lowlimfile = args.lowlimfile
    highlimfile = args.highlimfile


    import dill as pickle
    with open(highlimfile, 'rb') as dill_file:
        fit_func_inv = pickle.load(dill_file)
        
    with open(lowlimfile, 'rb') as dill_file:
        fit_func_low = pickle.load(dill_file)

    z_lo1 = fit_func_low(mass_lo)
    z_lo2 = fit_func_low(mass_hi)
    z_hi1 = fit_func_inv(mass_lo)
    z_hi2 = fit_func_inv(mass_hi)
    
    z_lo_out = max(z_lo1, z_lo2)
    z_hi_out = min(z_hi1, z_hi2)
    
    if z > z_low:
        z = z
    else:
        z = z_low
        
    if z <= z_high:
        z = z
    else:
        z = z_high
        
    exit(z)
        




    

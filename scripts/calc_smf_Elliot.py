  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import argparse
import numpy as np
import matplotlib.pyplot as pl
import astropy.io.fits as fits
from astropy.cosmology import LambdaCDM
import dill as pickle
from scipy.interpolate import InterpolatedUnivariateSpline
from scipy.integrate import simpson
pl.ioff()




#parser = argparse.ArgumentParser()
#parser.add_argument('--f_tomo', type=float, help='Fraction of galaxies in this bin', required=False, default=1.0)
#parser.add_argument('--nz_file', type=str, help='n(z) file', required=False, default='')
#parser.add_argument('--nz_tot', type=str, help='n(z) files (all of them)', required=False, default='', nargs='?')
#parser.add_argument('--nobs',type=int, help='Number of SMF bins', required=False, default=0)
#
#args = parser.parse_args()

estimator = "simple"
compare_to_gama = False

area_kids = 1350
total_sky_area = (180.0**2.0/np.pi**2.0) * 4.0*np.pi #~41253.0
frac = (area_kids/total_sky_area)
area_in_rad = area_kids / (180.0**2.0/np.pi**2.0)
# f_tomo = args.f_tomo

#nz_file = args.nz_file
#nz_tot_file = args.nz_tot
#nobs = args.nobs

"""
From LePhare's documentation:
https://www.cfht.hawaii.edu/~arnouts/LEPHARE/DOWNLOAD/lephare_doc.pdf
Mass is the stellar mass (M_sun)
From Blicki+2021:
We used a standard concordance cosmology (Ωm = 0.3, ΩΛ = 0.7, and H0 = 70 km s^-1 Mpc^-1),
a Chabrier (2003) initial mass function, the Calzetti et al. (1994) dust-extinction law,
Bruzual & Charlot (2003) stellar population synthesis models,
and exponentially declining star formation histories.
The input photometry to LePhare was extinction corrected using the Schlegel et al. (1998)
maps with the Schlafly & Finkbeiner (2011) coefficients, as described in Kuijken et al. (2019).
On average, the KiDS-Bright stellar mass estimates are smaller than those of GAMA
by ∆ log10 M_star ≡log10 M_KiDS_star - log10 M_GAMA_star = -0.09±0.18 dex (median and SMAD).
Only 9% this scatter is due to the photo_z errors.
Such an overall bias between the former and the latter is expected:
while our flux-scale correction is meant to compensate
for the flux missed by the GAaP measurements with respect to
AUTO magnitudes, an analogous correction in GAMA serves to
account for a flux that falls beyond the finite SDSS-based AUTO
aperture used for the SEDs.
"""

nbins = 30
Mmin_smf = 9.1
Mmax_smf = 11.3
min_z = 0.04
max_z = 0.37
nmbins = 100

stellar_mass_column = "stellar_mass"
z_column = "redshift"

h0 = 0.681
omegam = 0.306
omegav = 0.694


out_path = "./smf_data"
outname = f"none_flam_{estimator}"

input_file = "misc_data/kids_cat_all_bin_mask_rect.fits"

file_in = fits.open(input_file)

"""
compare_to_gama = True

area_kids = 777.4
frac = (area_kids/41253.0)


nbins = 30
Mmin_smf = 7.0
Mmax_smf = 12.5

stellar_mass_column = 'stellar_mass'
z_column = 'z_ANNZ_KV'

h0 = 1.0
omegam = 0.3
omegav = 0.7

file_in = fits.open('fluxscale_fixed.fits')

"""

cosmo_model = LambdaCDM(H0=h0*100., Om0=omegam, Ode0=omegav)

# TODO: what are these files?
# M_star_lim(z) the completeness in stellar mass as a function of redshift or our
# flux limited sample
# z_max,i: The maximum redshift beyond which galaxy i with stellar mass M_star,i
# would no longer be part of the sample


# Not used
# with open(os.path.join(path, 'mass_lim_low.npy'), 'rb') as dill_file:
#     fit_func_low = pickle.load(dill_file)

data = file_in[1].data

stellar_mass_in = data[stellar_mass_column] + (2 * np.log10(h0))
z_in = data[z_column]
stellar_mass_in = stellar_mass_in[np.logical_and(z_in >= min_z, z_in <= max_z)]
# We set the possible minimum z to 0.001
z_min = np.maximum(0.001, min_z)
# max_z is given as an input, this is the maximum redshift in the stellar mass-redshift bin.
z_max_bin = max_z * np.ones_like(stellar_mass_in)
# This is the function that was imported. Finds z_max given a stellar mass?
# Set z_max_i to which ever is smaller:
# the maximum redshift where it can be visible given the flux limit,
# or maximum redshift of the stellar mass-redshift bin
z_max_i = z_max_bin


if estimator == 'simple':
    # Comoving distance at z_min and z_max_i in units of Mpc h
    # z_max_i is the maximum redshift at which galaxy i is visible in the sample
    dc_min = cosmo_model.comoving_distance(z_min).to('Mpc').value * h0
    dc_max = cosmo_model.comoving_distance(z_max_i).to('Mpc').value * h0

    # comoving volume between zmin and zmax (a fraction of a spherical shell of thickness dc_max-dc_min)
    # V_max_i is the comoving volume over which galaxy i would be visible in the sample.
    V_max = 4.0*np.pi/3.0 * frac * (dc_max**3.0 - dc_min**3.0)

    M_bins = np.linspace(Mmin_smf, Mmax_smf, nbins+1, endpoint=True, retstep=True)
    delta_log10_M = M_bins[1]
    M_bins = M_bins[0]

    phi_bins = np.zeros(nbins)
    vmax_out = np.zeros(nbins)
    M_center = (M_bins[1:] + M_bins[:-1])/2.0

    # This is the same as doing a weighted histogram, where the weights are 1/V_max
    # In principle we can have an extra weight for the galaxies
    # that accounts for the completeness of the sample: Sum w/V_max
    # If the sample is volume limited then all galaxies that exist in
    # our stellar mass-redshift bins are observable.
    for i in range(nbins):
        index = ((stellar_mass_in > M_bins[i]) & (M_bins[i+1] > stellar_mass_in))
        phi_bins[i] = np.sum(1.0/V_max[index])
        # Compute the arithmetic mean, ignoring NaNs.
        vmax_out[i] = np.nanmean(V_max[index])

    phi_bins = np.abs(phi_bins)


# Φ(m∗) ∆m∗ = sum 1.0/V_max (e.g. eq 1 of 0901.0706)
# Φ(m∗) m* dm*/m*  = Φ(m∗) m* dln m*= Φ(m∗) m* ln(10) dlog10_m* = sum 1.0/V_max
# Φ(m∗) m* ln(10)  = 1/dlog10_m*  sum 1.0/V_max
data_out = np.array([10.0**M_center, phi_bins/delta_log10_M, np.ones_like(phi_bins)]).T
vmax_out = np.array([M_center, vmax_out]).T

np.savetxt(f"{out_path}/smf_vec/{outname}_smf.txt", np.nan_to_num(data_out))
np.savetxt(f"{out_path}/vmax/{outname}_vmax.txt", np.nan_to_num(vmax_out))
#np.savetxt(f"{out_path}/f_tomo/{outname}_ftomo.txt", np.array([f_tomo]))


# Find the number of galaxies in nmbins stellar mass bins
cond_mass = (stellar_mass_in <= Mmax_smf) & (stellar_mass_in > Mmin_smf)
masses = stellar_mass_in[cond_mass]
nm, mbins = np.histogram(masses, bins=nmbins,range=(Mmin_smf,Mmax_smf), density=True, weights=None)
obs_mid = (mbins[1:] + mbins[:-1])/2.0
np.savetxt(f"{out_path}/smf/{outname}_nmstar.txt", np.array([obs_mid, nm]).T,
            header='log10 Stellar Mass [M_sun/h^2] Number of galaxies in log10 bin')


quit()
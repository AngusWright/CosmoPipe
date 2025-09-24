  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import matplotlib.pyplot as pl
from scipy.interpolate import interp1d
import astropy.io.fits as fits
import astropy.units as u
# from astropy.cosmology import FlatLambdaCDM, Flatw0waCDM, LambdaCDM, z_at_value
from astropy.cosmology import LambdaCDM, z_at_value
from sklearn.neighbors import KernelDensity
import dill as pickle
pl.ioff()


def invert_func(fit_func, y_arr):
    
    inv = np.zeros_like(y_arr)
    for i,x in enumerate(y_arr):
        root = np.abs((fit_func - x).roots)
        inv[i] = root[2]
    
    return inv


if __name__ == '__main__':


    parser = argparse.ArgumentParser(description='Calculate stellar mass limit for sample of galaxies ala MassFitFuncR package')
    parser.add_argument('--h0', type=float, help='h0 from LePhare or other stellar mass code estimation routine', nargs='?', default=1.0, const=1.0)
    parser.add_argument('--omegam', type=float, help='Om_m from LePhare or other stellar mass code estimation routine', nargs='?', default=0.3, const=0.3)
    parser.add_argument('--omegav', type=float, help='Om_v from LePhare or other stellar mass code estimation routine', nargs='?', default=0.7, const=0.7)
    parser.add_argument('--min_mass', type=float, help='Minimum stellar mass to determine mass limit', nargs='?', default=6.0, const=6.0)
    parser.add_argument('--max_mass', type=float, help='Maximum stellar mass to determine mass limit', nargs='?', default=12.0, const=12.0)
    parser.add_argument('--min_z', type=float, help='Minimum redshift to determine mass limit', nargs='?', default=0.0, const=0.0)
    parser.add_argument('--max_z', type=float, help='Maximum redshift to determine mass limit', nargs='?', default=0.6, const=0.6)
    parser.add_argument('--stellar_mass_column', type=str, help='Stellar mass column', default='stellar_mass_fluxscale_corrected', required=True)
    parser.add_argument('--z_column', type=str, help='Redshift column', default='z_ANNZ_KV', required=True)
    parser.add_argument('--file', type=str, help='Input catalogue', default='fluxscale_fixed.fits', required=True)
    parser.add_argument('--plot_inspect_figs', type=bool, help='Plot inspect figures', nargs='?', default=False, const=True)
    parser.add_argument('--outfile1', type=str, help='Output file for mass lim function', default='mass_lim.npy', required=True)
    parser.add_argument('--outfile2', type=str, help='Output file for low mass lim function', default='mass_lim_low.npy', required=True)
    args = parser.parse_args()
    
    plot_inspect_figs = args.plot_inspect_figs
    file_in = fits.open(args.file)
    
    h0 = args.h0
    omegam = args.omegam
    omegav = args.omegav
    
    
    min_mass = args.min_mass
    max_mass = args.max_mass
    min_z = args.min_z
    max_z = args.max_z
    
    stellar_mass_column = args.stellar_mass_column
    z_column = args.z_column
    
    outfile1 = args.outfile1
    outfile2 = args.outfile2
      
    """
    # These are just the default values as used in 2x2pt paper.
    plot_inspect_figs = True
    file_in = fits.open('fluxscale_fixed.fits')
    
    h0 = 1.0
    omegam = 0.3
    omegav = 0.7
    
    
    min_mass = 6.0
    max_mass = 12.0
    min_z = 0.0
    max_z = 0.7
    
    stellar_mass_column = 'stellar_mass'
    z_column = 'z_ANNZ_KV'
    """
    
    # Maybe set this by user, leaving hardcoded for now...
    n_bins_z = 20
    n_bins_m = 20
    degree = 9
    nboot = 20

    cosmo_model = LambdaCDM(H0=h0*100., Om0=omegam, Ode0=omegav)
    
    data = file_in[1].data
    
    stellar_mass_in = data[stellar_mass_column]
    z_in = data[z_column]
    
    comoving_distances_in = cosmo_model.comoving_distance(z_in).to('Mpc').value
    
    idx_mask = (stellar_mass_in <= max_mass) & (stellar_mass_in > min_mass) & (z_in > min_z) & (z_in <= max_z)
    stellar_mass = stellar_mass_in[idx_mask]
    z = z_in[idx_mask]
    comoving_distances = comoving_distances_in[idx_mask]
    
    
    z_bins, z_step = np.linspace(min_z, max_z, n_bins_z+1, endpoint=True, retstep=True)
    stellar_mass_bins, mass_step = np.linspace(min_mass, max_mass, n_bins_m+1, endpoint=True, retstep=True)
    
    z_centers = (z_bins[1:] + z_bins[:-1])/2.0
    mass_centers = (stellar_mass_bins[1:] + stellar_mass_bins[:-1])/2.0
    
    co_bins = cosmo_model.comoving_distance(z_bins).to('Mpc').value
    co_centers = cosmo_model.comoving_distance(z_centers).to('Mpc').value
    co_step = cosmo_model.comoving_distance(z_step).to('Mpc').value
    
    max_co_dist = np.max(comoving_distances)
    min_co_dist = np.max([np.min(comoving_distances),0.0])
    
    
    mass_low = np.zeros((n_bins_m,2))
    for i in range(n_bins_m):
        index_m = np.where((stellar_mass > stellar_mass_bins[i]) & (stellar_mass_bins[i+1] > stellar_mass))
        mass_low[i,:] = mass_centers[i], np.percentile(z[index_m], 0.01)
        
    fit_func_low = interp1d(mass_low[:,0], mass_low[:,1], fill_value='extrapolate')
    with open(outfile2, 'wb') as dill_file:
        pickle.dump(fit_func_low, dill_file)


    for_fit_z = np.zeros((nboot*n_bins_z, 2))
    for i in range(n_bins_z):
        for n in range(nboot):
            if nboot > 1:
                index_boot = np.random.choice(np.arange(stellar_mass.size), size=stellar_mass.size)
            else:
                index_boot = np.arange(stellar_mass.size)
            temp_logmstar = stellar_mass[index_boot]
            temp_codist = comoving_distances[index_boot]
            index_z = np.where((temp_codist > co_bins[i]) & (co_bins[i+1] > temp_codist))
            if len(temp_logmstar[index_z]) < 2:
                for_fit_z[n*n_bins_z+i,:] = np.nan, np.nan
            else:
                bw = mass_step/np.sqrt(12.0)
                kde = KernelDensity(kernel='tophat', bandwidth=bw).fit(temp_logmstar[index_z][:, None])
                x = np.linspace(np.min(stellar_mass), np.max(stellar_mass), 1000)
                mden = np.exp(kde.score_samples(x[:, None]))
                z_out = z_at_value(cosmo_model.comoving_distance, np.median(temp_codist[index_z])*u.Mpc)
                mden_out = x[np.argmax(mden)]
                for_fit_z[n*n_bins_z+i,:] = z_out, mden_out
                if plot_inspect_figs:
                    pl.plot(x, mden, color='black')
                    pl.plot(mden_out, np.zeros_like(mden_out), color='red', marker='o', ls='')
    
    if plot_inspect_figs:
        pl.savefig('smf_peaks_in_mass.png')
        pl.clf()
    

    
    x = np.linspace(min_co_dist, max_co_dist, 1000)
    intp_x = np.array([z_at_value(cosmo_model.comoving_distance, l*u.Mpc, zmin=-0.01) for l in x])

    for_fit_m = np.zeros((nboot*n_bins_m, 2))
    
    for i in range(n_bins_m):
        for n in range(nboot):
            if nboot > 1:
                index_boot = np.random.choice(np.arange(comoving_distances.size), size=comoving_distances.size)
            else:
                index_boot = np.arange(comoving_distances.size)
            temp_logmstar = stellar_mass[index_boot]
            temp_codist = comoving_distances[index_boot]
            index_m = np.where((temp_logmstar > stellar_mass_bins[i]) & (stellar_mass_bins[i+1] > temp_logmstar))
            if len(temp_codist[index_m]) < 2:
                for_fit_m[n*n_bins_m+i,:] = np.nan, np.nan
            else:
                bw = co_step/np.sqrt(12.0)
                kde = KernelDensity(kernel='tophat', bandwidth=bw).fit(temp_codist[index_m][:, None])
                cden = np.exp(kde.score_samples(x[:, None]))
                cden[~np.isfinite(cden)] = 0.0
                xval = np.linspace(np.min(z), max_z, 1000)
                zden = np.interp(xval, intp_x, cden)
                try:
                    xlim = xval[np.max(np.where(zden > np.max(zden)/3.0))]
                    lim = xval[np.max(np.where(zden > np.median(zden[xval <= xlim])))]
                    mden_out = np.median(temp_logmstar[index_m])
                    lim = xval[np.argmax(zden)]
                    for_fit_m[n*n_bins_m+i,:] = lim, mden_out
                    if plot_inspect_figs:
                        pl.plot(xval, zden, color='black')
                        pl.plot(lim, np.zeros_like(lim), color='red', marker='o', ls='')
                except:
                    for_fit_m[n*n_bins_m+i,:] = np.nan, np.nan
    
    if plot_inspect_figs:
        pl.savefig('smf_peaks_in_z.png')
        pl.clf()
    
 
    for_fit = np.concatenate((for_fit_z, for_fit_m), axis=0)
    for_fit = for_fit[~np.isnan(for_fit[:,1])] #remove nans
    #for_fit = for_fit[(for_fit[:,0]<0.6) & (for_fit[:,0]>0.05)]
    for_fit = for_fit[for_fit[:,0].argsort()]
    
    #for_fit = np.insert(for_fit, 0, [0.0, 7.0], axis=0)
    
    fit_inv = np.polyfit(for_fit[:,0], for_fit[:,1], degree)
    fit_func = np.poly1d(fit_inv)
    
    y = np.linspace(0.0, z.max(), 100)
    fit_func_inv = interp1d(fit_func(y), y, fill_value='extrapolate')
    
    with open(outfile1, 'wb') as dill_file:
        pickle.dump(fit_func_inv, dill_file)
    
    if plot_inspect_figs:
        x = np.linspace(6.0, 13.0, 100)
        pl.rc('text',usetex=True)
        pl.rcParams.update({'font.size': 20})
        fig, ax = pl.subplots(1, 1, figsize=(8, 8))
        ax.hexbin(z, stellar_mass, gridsize=100, bins='log')
        ax.plot(for_fit_z[:,0], for_fit_z[:,1], ls='', ms=2, marker='o', color='red')
        ax.plot(for_fit_m[:,0], for_fit_m[:,1], ls='', ms=2, marker='o', color='blue')
        ax.plot(fit_func_inv(x), x)
        ax.plot(y, fit_func(y))
        ax.plot(fit_func_low(x), x)
        ax.set_ylim([5, 13])
        ax.set_xlim([0, 0.6])
        pl.savefig('mass_lims.png')
        pl.clf()
    
    
    

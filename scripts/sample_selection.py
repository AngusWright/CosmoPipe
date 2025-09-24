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
from scipy.signal import find_peaks
from scipy.stats import gaussian_kde, norm
from sklearn.neighbors import KernelDensity
import matplotlib.patheffects as pe
import matplotlib.patches as mpatches
from matplotlib.patches import Rectangle
import dill as pickle
import argparse
import os
import subprocess

def create_nz(x_array, z_array, sigma, zdep):

    nz = np.zeros_like(x_array)
    for z in z_array:
        if zdep:
            rv = norm(loc=z, scale=(sigma / (1.0+z)))
        else:
            rv = norm(loc=z, scale=sigma)
        nz += rv.pdf(x_array)
    nz = nz / np.nansum(nz) # normalise
    return nz

if __name__ == '__main__':


    parser = argparse.ArgumentParser(description='Cut given binning limits by the lower and upper stellar mass limit.')
    parser.add_argument('--m_bins', type=str, help='Stellar mass bins', nargs='+', required=True)
    parser.add_argument('--z_bins', type=str, help='Redshift bins', nargs='+', required=True)
    parser.add_argument('--stellar_mass_column', type=str, help='Stellar mass column', default='stellar_mass', required=True)
    parser.add_argument('--z_column', type=str, help='Redshift column', default='z_ANNZ_KV', required=True)
    parser.add_argument('--path', type=str, help='Path to npy files required for mass limit', required=True)
    parser.add_argument('--file', type=str, help='Input catalogue', default='fluxscale_fixed.fits', required=True)
    parser.add_argument('--file_rand', type=str, help='Input randoms catalogue', default='fluxscale_fixed_rand.fits', required=True)
    parser.add_argument('--plot', type=bool, help='Plot check figures', nargs='?', default=False, const=True)
    parser.add_argument('--randoms', type=bool, help='Apply selection to randoms', nargs='?', default=False, const=True)
    parser.add_argument('--percentile_split', type=bool, help='Further split bins by percentiles of galaxies', nargs='?', default=False, const=True)
    parser.add_argument('--percentiles', type=str, help='Which percentiles to split the galaxies', nargs='+', default=[])
    parser.add_argument('--slice_in', type=str, help='In which quantity to split data first', required=True)
    parser.add_argument('--output_path', type=str, help='Output path', required=True)
    parser.add_argument('--output_name', type=str, help='Output file', required=True)
    parser.add_argument('--output_name_rand', type=str, help='Output file randoms', required=True)
    parser.add_argument('--output_name_nz', type=str, help='Output nz file', required=True)
    parser.add_argument('--volume_limited', type=str, help='Create volume limited samples', required=True)
    parser.add_argument('--stacked_nz', type=str, help='Create stacked n(z) from aNNZ redshifts and their uncertainty', required=True, default='False')
    parser.add_argument('--z_dependent_error', type=str, help='If uncertanty on z_aNNz is dependent on redhshift or now', required=False, default='True')
    parser.add_argument('--z_sigma', type=float, help='Redshift uncertainty', required=False, default=0.018)
    parser.add_argument('--nz_step', type=float, help='Redshift step size', required=False, default=0.05)
    
    
    args = parser.parse_args()
    
    volume_limited = args.volume_limited
    volume_limited = volume_limited.lower() in ["true","t","1","y","yes"]
    
    random = args.randoms
    percentile_split = args.percentile_split
    plot = args.plot
    
    m_bins_in = args.m_bins #np.array([9.1,9.6,9.95,10.25,10.5,10.7,11.3])
    z_bins_in = args.z_bins
    
    m_bins = np.array([float(i) for i in m_bins_in])
    z_bins = np.array([float(i) for i in z_bins_in])
    
    z_column = args.z_column
    stellar_mass_column = args.stellar_mass_column
    
    print(stellar_mass_column)
    print(args.slice_in)
    
    if args.slice_in == stellar_mass_column:
        slice_in_m = True
        slice_in_z = False
    if args.slice_in == z_column:
        slice_in_m = False
        slice_in_z = True
    
    path = args.path
    outpath = args.output_path
    outname = args.output_name
    outname_nz = args.output_name_nz
    outname_rand = args.output_name_rand
    percentiles_in = args.percentiles #[25, 50, 75]
    percentiles = np.array([float(i) for i in percentiles_in])

    
    stacked_nz = args.stacked_nz
    stacked_nz = stacked_nz.lower() in ["true","t","1","y","yes"]
    
    z_dependent_error = args.z_dependent_error
    z_dependent_error = z_dependent_error.lower() in ["true","t","1","y","yes"]
    
    z_sigma = args.z_sigma
    nz_step = args.nz_step
    
    with open(os.path.join(path, 'mass_lim.npy'), 'rb') as dill_file:
        fit_func_inv = pickle.load(dill_file)
    with open(os.path.join(path, 'mass_lim_low.npy'), 'rb') as dill_file:
        fit_func_low = pickle.load(dill_file)
    
    file_in = fits.open(args.file, memmap=True)
    data = file_in[1].data
    
    if plot:
        x = np.linspace(6.0, 13.0, 100)
        pl.rc('text',usetex=True)
        fig, ax = pl.subplots(1, 1, figsize=(6, 6))
        ax.set_ylim([6, 12])
        ax.set_xlim([0, 0.55])
        ax.hexbin(data[z_column], data[stellar_mass_column], gridsize=100, cmap='viridis', bins='log', rasterized=True, extent=(0, 0.7, 6, 12))
        ax.plot(fit_func_inv(x), x, label=r'$M_{\star}\, \mathrm{limit}$')
    
    #idx_in = np.where(data[z_column] <= fit_func_inv(data[stellar_mass_column]))
    #data = data[idx_in].copy()
    
    stellar_mass_in = data[stellar_mass_column]
    z_in = data[z_column]
    
    details = {}
    
    if slice_in_m and slice_in_z:
        raise ValueError('Primary slicing in redshift and stellar mass is not allowed, select one or another')
        
    if slice_in_m:
        x_bins = m_bins
        y_bins_in = z_bins
        func_low = fit_func_low
        func_high = fit_func_inv
        x_data = stellar_mass_in
        y_data = z_in
        details['x_data_name'] = stellar_mass_column
        details['y_data_name'] = z_column
        if stacked_nz:
            centers = np.arange(0.0, 1.0, step=nz_step)
            nz_tot = np.zeros_like(centers)
            #nz = create_nz(centers, np.nan_to_num(y_data), z_sigma, z_dependent_error)
            #np.savetxt(f'{outpath}/nz_tot.txt', np.column_stack([centers, nz]), header='binstart, density')
    if slice_in_z:
        x_bins = z_bins
        y_bins_in = m_bins
        yrange = np.linspace(m_bins[0], m_bins[-1], 100)
        # Need to invert low/high limits as otherwise we get inconsistency when slicing
        func_high = interp1d(fit_func_low(yrange), yrange, fill_value='extrapolate')
        func_low = interp1d(fit_func_inv(yrange), yrange, fill_value='extrapolate')
        x_data = z_in
        y_data = stellar_mass_in
        details['x_data_name'] = z_column
        details['y_data_name'] = stellar_mass_column
        if stacked_nz:
            centers = np.arange(0.0, 1.0, step=nz_step)
            nz_tot = np.zeros_like(centers)
            #nz = create_nz(centers, np.nan_to_num(x_data), z_sigma, z_dependent_error)
            #np.savetxt(f'{outpath}/nz_tot.txt', np.column_stack([centers, nz]), header='binstart, density')
    
    if volume_limited:
        # First we refine the binning with the stellar mass/luminosity limits
        count = 0
        for i in range(len(x_bins)-1):
            y_low = max(func_low(x_bins[i+1]), min(y_bins_in))
            if slice_in_m:
                y_high = min(func_high(x_bins[i]), max(y_bins_in))
            if slice_in_z:
                y_high = min(func_high(x_bins[i+1]), max(y_bins_in))
            y_bins_extra = np.array([y_low, y_high])
            y_bins = np.unique(np.concatenate((y_bins_in, y_bins_extra)))

            #idx = np.where((stellar_mass_in <= x_bins[i+1]) & (stellar_mass_in > x_bins[i]) & (z_in <= z_high) & (z_in > z_low))
            idx00 = np.where((x_data <= x_bins[-1]) & (x_data > x_bins[0]) & (y_data <= y_high) & (y_data > y_low))
            idx0 = np.where((x_data <= x_bins[i+1]) & (x_data > x_bins[i]) & (y_data <= y_high) & (y_data > y_low))
            
            if slice_in_m and percentile_split:
                med = np.percentile(y_data[idx0], percentiles)
                y_bins = np.append(y_bins, med)
                    
            if slice_in_z and percentile_split:
                med = np.log10(np.percentile(10.0**y_data[idx0], percentiles))
                y_bins = np.append(y_bins, med)
                
            y_bins = np.sort(y_bins)
            y_bins = y_bins[(y_bins <= y_high) & (y_bins >= y_low)]
            
            # Then we apply refined binning including additional splits in median numbers
            for j in range(len(y_bins)-1):
                idx = np.where((x_data <= x_bins[i+1]) & (x_data > x_bins[i]) & (y_data <= y_bins[j+1]) & (y_data > y_bins[j]))
                if idx[0].size == 0:
                    continue
                data_out = np.copy(data[idx])
        
                if plot:
                    ax.scatter(z_in[idx], stellar_mass_in[idx], color='k', alpha=0.25, marker='.', s=1, rasterized=True)
                    if slice_in_m:
                        ax.add_patch(Rectangle((y_bins[j],x_bins[i]),(y_bins[j+1]-y_bins[j]),(x_bins[i+1]-x_bins[i]),linewidth=1,edgecolor='r',facecolor='none'))
                    if slice_in_z:
                        ax.add_patch(Rectangle((x_bins[i],y_bins[j]),(x_bins[i+1]-x_bins[i]),(y_bins[j+1]-y_bins[j]),linewidth=1,edgecolor='r',facecolor='none'))
                
                cols = fits.ColDefs(data_out)
                hdu = fits.BinTableHDU.from_columns(cols)
                hdu.writeto(f'{outname}{count+1}.fits', overwrite=True)
                details['x_lims_lo'] = x_bins[i]
                details['x_lims_hi'] = x_bins[i+1]
                details['y_lims_lo'] = y_bins[j]
                details['y_lims_hi'] = y_bins[j+1]
                if slice_in_m:
                    details['x_med'] = np.log10(np.median(10.0**x_data[idx]))
                    details['y_med'] = np.median(y_data[idx])
                    details['slice_in'] = 'obs'
                    details['f_tomo'] = len(x_data[idx])/len(x_data[idx00])
                    if stacked_nz:
                        centers = np.arange(0.0, 1.0, step=nz_step)
                        nz = create_nz(centers, y_data[idx], z_sigma, z_dependent_error)
                        nz_tot += nz
                        np.savetxt(f'{outname_nz}{count+1}.txt', np.column_stack([centers, nz]), header='binstart, density')
                if slice_in_z:
                    details['x_med'] = np.median(x_data[idx])
                    details['y_med'] = np.log10(np.median(10.0**y_data[idx]))
                    details['slice_in'] = 'z'
                    details['f_tomo'] = len(y_data[idx])/len(y_data[idx00])
                    if stacked_nz:
                        centers = np.arange(0.0, 1.0, step=nz_step)
                        nz = create_nz(centers, x_data[idx], z_sigma, z_dependent_error)
                        nz_tot += nz
                        np.savetxt(f'{outname_nz}{count+1}.txt', np.column_stack([centers, nz]), header='binstart, density')
                with open(f'{outpath}/stats_LB{count+1}.txt', 'w') as f:
                    for key, value in details.items():
                        f.write(f'{key}\t{value}\n')
    
                if random:
                    print('\nApplying selection to randoms...')
                    #"""
                    random_in = fits.open(args.file_rand, memmap=True)
                    randoms = random_in[1].data
                    
                    index = np.in1d(randoms['clone_ID'].astype(bytes), data_out['ID'])
                
                    rand_out = np.copy(randoms[np.where(randoms[index])][::10]) # remove every 3nd after testing
                    num_col = np.arange(len(rand_out['clone_ID']))
                
                    cols_rand = fits.ColDefs(rand_out)
                    num = fits.Column(name='UNIQUEID', format='J', array=num_col)
                    hdu = fits.BinTableHDU.from_columns(cols_rand + num)
                    hdu.writeto(f'{outname_rand}{count+1}_rand.fits', overwrite=True)
                    #"""
                    #subprocess.call(['ln', '-sf', args.file_rand, f'{outname_rand}{count+1}_rand.fits'])
                count += 1
                
    if not volume_limited:
        # First we refine the binning with the stellar mass/luminosity limits
        count = 0
        for i in range(len(x_bins)-1):
            y_high = min(func_high(x_bins[i+1]), max(y_bins_in))
            if slice_in_m:
                y_low = max(func_low(x_bins[i+1]), min(y_bins_in))
            if slice_in_z:
                y_low = max(func_low(x_bins[i]), min(y_bins_in))
            y_bins_extra = np.array([y_low, y_high])
            y_bins = np.unique(np.concatenate((y_bins_in, y_bins_extra)))
        
            #idx = np.where((stellar_mass_in <= x_bins[i+1]) & (stellar_mass_in > x_bins[i]) & (z_in <= z_high) & (z_in > z_low))
            if slice_in_m:
                idx00 = np.where((x_data <= x_bins[-1]) & (x_data > x_bins[0]) & (y_data <= y_high) & (y_data > y_low) & (y_data <= func_high(x_data)))
                idx0 = np.where((x_data <= x_bins[i+1]) & (x_data > x_bins[i]) & (y_data <= y_high) & (y_data > y_low) & (y_data <= func_high(x_data)))
            if slice_in_z:
                idx00 = np.where((x_data <= x_bins[-1]) & (x_data > x_bins[0]) & (y_data <= y_high) & (y_data > y_low) & (y_data > func_low(x_data)))
                idx0 = np.where((x_data <= x_bins[i+1]) & (x_data > x_bins[i]) & (y_data <= y_high) & (y_data > y_low) & (y_data > func_low(x_data)))
            
            if slice_in_m and percentile_split:
                med = np.percentile(y_data[idx0], percentiles)
                y_bins = np.append(y_bins, med)
                    
            if slice_in_z and percentile_split:
                med = np.log10(np.percentile(10.0**y_data[idx0], percentiles))
                y_bins = np.append(y_bins, med)
                
            y_bins = np.sort(y_bins)
            y_bins = y_bins[(y_bins <= y_high) & (y_bins >= y_low)]
            
            # Then we apply refined binning including additional splits in median numbers
            for j in range(len(y_bins)-1):
                if slice_in_m:
                    idx = np.where((x_data <= x_bins[i+1]) & (x_data > x_bins[i]) & (y_data <= y_bins[j+1]) & (y_data > y_bins[j]) & (y_data <= func_high(x_data)))
                if slice_in_z:
                    idx = np.where((x_data <= x_bins[i+1]) & (x_data > x_bins[i]) & (y_data <= y_bins[j+1]) & (y_data > y_bins[j]) & (y_data > func_low(x_data)))
                if idx[0].size == 0:
                    continue
                data_out = np.copy(data[idx])
        
                if plot:
                    ax.scatter(z_in[idx], stellar_mass_in[idx], color='k', alpha=0.25, marker='.', s=1, rasterized=True)
                    if slice_in_m:
                        ax.plot([y_bins[j], min(func_high(x_bins[i]), y_bins[j+1])], [x_bins[i], x_bins[i]], linewidth=1, color='r')
                        ax.plot([y_bins[j], min(func_high(x_bins[i+1]), y_bins[j+1])], [x_bins[i+1], x_bins[i+1]], linewidth=1, color='r')
                        ax.plot([y_bins[j], y_bins[j]], [x_bins[i], x_bins[i+1]], linewidth=1, color='r')
                        ax.plot(np.maximum(func_high(np.linspace(x_bins[i], x_bins[i+1], 50, endpoint=True)), np.ones(50)*y_bins[j]), np.linspace(x_bins[i], x_bins[i+1], 50, endpoint=True),  linewidth=1, color='r')
                    if slice_in_z:
                        ax.plot([x_bins[i], x_bins[i]], [max(y_bins[j], func_low(x_bins[i])), y_bins[j+1]], linewidth=1, color='r')
                        ax.plot([x_bins[i+1], x_bins[i+1]], [max(y_bins[j], func_low(x_bins[i+1])), y_bins[j+1]], linewidth=1, color='r')
                        ax.plot([x_bins[i], x_bins[i+1]], [y_bins[j+1], y_bins[j+1]], linewidth=1, color='r')
                        ax.plot(np.linspace(x_bins[i], x_bins[i+1], 50, endpoint=True), np.maximum(func_low(np.linspace(x_bins[i], x_bins[i+1], 50, endpoint=True)), np.ones(50)*y_bins[j]), linewidth=1, color='r')
        
                
                cols = fits.ColDefs(data_out)
                hdu = fits.BinTableHDU.from_columns(cols)
                hdu.writeto(f'{outname}{count+1}.fits', overwrite=True)
                details['x_lims_lo'] = x_bins[i]
                details['x_lims_hi'] = x_bins[i+1]
                details['y_lims_lo'] = y_bins[j]
                details['y_lims_hi'] = y_bins[j+1]
                if slice_in_m:
                    details['x_med'] = np.log10(np.median(10.0**x_data[idx]))
                    details['y_med'] = np.median(y_data[idx])
                    details['slice_in'] = 'obs'
                    details['f_tomo'] = len(x_data[idx])/len(x_data[idx00])
                    if stacked_nz:
                        centers = np.arange(0.0, 1.0, step=nz_step)
                        nz = create_nz(centers, y_data[idx], z_sigma, z_dependent_error)
                        nz_tot += nz
                        np.savetxt(f'{outname_nz}{count+1}.txt', np.column_stack([centers, nz]), header='binstart, density')
                if slice_in_z:
                    details['x_med'] = np.median(x_data[idx])
                    details['y_med'] = np.log10(np.median(10.0**y_data[idx]))
                    details['slice_in'] = 'z'
                    details['f_tomo'] = len(y_data[idx])/len(y_data[idx00])
                    if stacked_nz:
                        centers = np.arange(0.0, 1.0, step=nz_step)
                        nz = create_nz(centers, x_data[idx], z_sigma, z_dependent_error)
                        nz_tot += nz
                        np.savetxt(f'{outname_nz}{count+1}.txt', np.column_stack([centers, nz]), header='binstart, density')
                with open(f'{outpath}/stats_LB{count+1}.txt', 'w') as f:
                    for key, value in details.items():
                        f.write(f'{key}\t{value}\n')
    
    
                if random:
                    print('\nApplying selection to randoms...')
                    #"""
                    random_in = fits.open(args.file_rand, memmap=True)
                    randoms = random_in[1].data
                    index = np.in1d(randoms['clone_ID'].astype(bytes), data_out['ID'])
                
                    rand_out = np.copy(randoms[np.where(randoms[index])][::10]) # remove every 3nd after testing
                    num_col = np.arange(len(rand_out['clone_ID']))
                
                    cols_rand = fits.ColDefs(rand_out)
                    num = fits.Column(name='UNIQUEID', format='J', array=num_col)
                    hdu = fits.BinTableHDU.from_columns(cols_rand + num)
                    hdu.writeto(f'{outname_rand}{count+1}_rand.fits', overwrite=True)
                    #"""
                    #subprocess.call(['ln', '-sf', args.file_rand, f'{outname_rand}{count+1}_rand.fits'])
                count += 1
            
            
    with open(f'{outpath}/nbins.txt', 'w') as f:
        f.write(f'nbins\t{count}\n')
    nz_tot /= np.nansum(nz_tot)
    np.savetxt(f'{outpath}/nz_tot.txt', np.column_stack([centers, nz_tot]), header='binstart, density')

    if plot:
        ax.set_ylabel(r'$\log(M_{\star}/h^{-2}\,M_{\odot})$')
        ax.set_xlabel(r'$z_{\mathrm{ANNz}}$')
        handles, labels = ax.get_legend_handles_labels()
        # manually define a new patch
        patch = mpatches.Patch(edgecolor='red', facecolor='white', label=r'$\mathrm{Volume\, limited\ sample}$')
        # handles is a list, so append manual patch
        handles.append(patch)
        # plot the legend
        pl.legend(handles=handles, loc='lower right')#, fontsize=12)
        pl.tight_layout()
        pl.savefig(f'{outpath}/selection.pdf', dpi=800)
        pl.clf()

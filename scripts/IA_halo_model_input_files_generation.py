
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
from astropy.io import fits
import argparse

# Question remains how to get cen/sat determination of KiDS galaxies, if at all, but if using the halo mass dependent IA that should not matter.

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Generate files needed for the IA halo model')
    parser.add_argument('-n', '--nzbins', dest="nzbins",type=int,
        help='Number of redshift bins',required=True, default=30)
    parser.add_argument('-s','--split_value', dest="split_value", type=float,required=True,
             help='red/blue split value', default=3.0)
    parser.add_argument('-c','--catalogue', dest="catalogue", type=str,required=True,
             help='Input catalogue')
    parser.add_argument('-o','--observable', dest="observable", type=str,required=False,
             help='Column name of desired observable', default='mstar_bestfit')
    parser.add_argument('-l','--log', dest="if_log", type=str,required=False,
             help='If desired observable is log quantity or not', default="False")
    parser.add_argument('-p','--output_path', dest="output_path", type=str,required=True,
             help='file for output catalogue')
    parser.add_argument('-z','--redshift_column', dest="z", type=str,required=False,
             help='Column name of redshift', default='Z_B')
    parser.add_argument('-t','--split_tag', dest="split_tag", type=str,required=False,
             help='Column name of the quantity to perform split in', default='T_B',nargs='+')
             
    #TO-DO: pass the redshift column name and color coloumn name as an argument

    args = parser.parse_args()
    
    nzbins = args.nzbins
    split_value = args.split_value
    catalogue = args.catalogue
    observable = args.observable
    output_path = args.output_path
    split_tag = args.split_tag
    z = args.z
    if_log = args.if_log
    if_log=if_log.lower() in ["true","t","1","y","yes"]

    plots = True

    # Settings
    #split_value = 3.0
    #nzbins = 30
    #catalogue = 'KIDS_cat.fits'

    hdul = fits.open(catalogue, memmap=True)
    hdul[1].header
    
    df = hdul['OBJECTS'].data
    df_obs = df[observable]
    
    # For the moment we use a cut in the u-r absolute color vs redshift
    if len(split_tag) == 1:
        df_split = df[split_tag[0]]
        plot_tag = split_tag[0]
    if len(split_tag) == 2:
        df_split = df[split_tag[0]] - df[split_tag[1]]
        plot_tag = split_tag[0] + '-' + split_tag[1]
    if len(split_tag) > 2:
        raise ValueError('Only one or two tags allowed, to either select on one value or colour')
    
    if plots:
        plt.scatter(df_split, df[z], s=0.000005, rasterized=True)
        plt.axvline(split_value)
        plt.xlabel(plot_tag, fontsize=15)
        plt.ylabel(z, fontsize=15)
        #plt.show()
        plt.savefig(f'{output_path}/check1.pdf')
        plt.clf()
        
        plt.hist(df_split, histtype='step', bins=150, density=True)
        plt.axvline(split_value)
        plt.xlabel(plot_tag, fontsize=15)
        #plt.show()
        plt.savefig(f'{output_path}/check2.pdf')
        plt.clf()
    
    # Redshift edges for the red/blue split histograms
    edges = np.linspace(np.min(df[z]), np.max(df[z]), nzbins + 1, endpoint=True)
    nblue = np.histogram(df[z][df_split >= split_value], bins=edges)[0]
    nred = np.histogram(df[z][df_split < split_value], bins=edges)[0]
    total = nblue + nred
    red_fraction = nred / total
    blue_fraction = nblue / total
    z_bins = (edges[1:] + edges[:-1])/2.0
    # Fraction of red galaxies as a function of redshift
    np.savetxt(f'{output_path}/f_red.txt', np.column_stack([z_bins, red_fraction]))
    
    if plots:
        plt.plot(z_bins, blue_fraction)
        plt.xlabel(z, fontsize=15)
        plt.ylabel('fraction of blue galaxies', fontsize=15)
        #plt.show()
        plt.savefig(f'{output_path}/check3.pdf')
        plt.clf()
    
    # Mass limits for red centrals as a function of redshift
    obs_min = np.empty(nzbins)
    obs_max = np.empty(nzbins)
    for i in range(nzbins):
        selection = df_obs[(df[z] <= edges[i+1]) & (df[z] > edges[i]) & (df_split < split_value)]# & (df['flag_central'] == 0)]
        if if_log:
            obs_min[i] = np.min(10.0**selection)
            obs_max[i] = np.max(10.0**selection)
        else:
            obs_min[i] = np.min(selection)
            obs_max[i] = np.max(selection)
        
    np.savetxt(f'{output_path}/red_cen_obs_pdf.txt', np.column_stack([z_bins, obs_min, obs_max]), header='z obs_min obs_max')
    
    # Luminosity limits for blue centrals as a function of redshift
    obs_min = np.empty(nzbins)
    obs_max = np.empty(nzbins)
    for i in range(nzbins):
        selection = df_obs[(df[z] <= edges[i+1]) & (df[z] > edges[i]) & (df_split >= split_value)]# & (df['flag_central'] == 0)]
        if if_log:
            obs_min[i] = np.min(10.0**selection)
            obs_max[i] = np.max(10.0**selection)
        else:
            obs_min[i] = np.min(selection)
            obs_max[i] = np.max(selection)
        
    np.savetxt(f'{output_path}/blue_cen_obs_pdf.txt', np.column_stack([z_bins, obs_min, obs_max]), header='z obs_min obs_max')
    
    
    if plots:
        # Check of the luminosity pdfs for red centrals at 4 different redshifts
        for i in [0,10,20,nzbins-1]:
            selection = df_obs[(df[z] <= edges[i+1]) & (df[z] > edges[i]) & (df_split < split_value)]# & (df['flag_central'] == 0)]
            if if_log:
                plt.hist(np.log10(10.0**selection), bins=10, histtype='step', density=True)
            else:
                plt.hist(np.log10(selection), bins=10, histtype='step', density=True)
        plt.xlabel('log_lum',fontsize=15)
        #plt.show()
        plt.savefig(f'{output_path}/check4.pdf')
        plt.clf()
    
    """
    if observable in ['lum', 'luminosity']:
        # Luminosity pdfs for blue satellites, red satellites, and red centrals as a function of redshift
        # Used for luminosity dependent IA halo model only
        c1=fits.Column(name='z', array=df[z][(df_split >= split_value) & (df['flag_central'] == 1)], format='E')
        c2=fits.Column(name='loglum', array=np.log10(df_obs[(df_split >= split_value) & (df['flag_central'] == 1)]), format='E')
        t=fits.BinTableHDU.from_columns([c1,c2])
        t.writeto('bluesat_lum.fits', overwrite=True)
    
        c1=fits.Column(name='z', array=df[z][(df_split < split_value) & (df['flag_central'] == 1)], format='E')
        c2=fits.Column(name='loglum', array=np.log10(df_obs[(df_split < split_value) & (df['flag_central'] == 1)]), format='E')
        t=fits.BinTableHDU.from_columns([c1,c2])
        t.writeto('redsat_lum.fits', overwrite=True)
    
        c1=fits.Column(name='z', array=df[z][(df_split < split_value) & (df['flag_central'] == 0)], format='E')
        c2=fits.Column(name='loglum', array=np.log10(df_obs[(df_split < split_value) & (df['flag_central'] == 0)]), format='E')
        t=fits.BinTableHDU.from_columns([c1,c2])
        t.writeto('redcen_lum.fits', overwrite=True)
    """

# ----------------------------------------------------------------
# File Name:           calc_xi_w_treecorr.py
# Author:              Catherine Heymans (heymans@roe.ac.uk)
# Description:         short python script to run treecorr to calculate xi_+/- 
#                      given a KiDS fits catalogue
#                      script will need to change if keywords in KIDS cats are updated
# ----------------------------------------------------------------

import treecorr
import sys
import numpy as np
import astropy.io.fits as fits
from argparse import ArgumentParser

def subtractNoise(g_1, g_2, eps_1, eps_2):
    g   = g_1 + 1j * g_2
    g_c = g_1 - 1j * g_2
    eps = eps_1 + 1j * eps_2
    
    e = (eps - g) / (1.0 - g_c*eps)
    e = np.array([e.real, e.imag])
    return e

if __name__ == '__main__':

    # Read in user input to set the nbins, theta_min, theta_max, lin_not_log, fitscat1, fitscat2, outfilename, weighted
    # Specify the input arguments
    parser = ArgumentParser(description='Compute 2cpfs from user inputs')
    parser.add_argument("-n", "--nbins", dest="nbins",type=int,
        help="Number of theta bins", metavar="nBins",required=True)
    parser.add_argument('-s','--theta_min', dest="theta_min", type=float,required=True, 
             help='minimum theta for binning')
    parser.add_argument('-l','--theta_max', dest="theta_max", type=float,required=True, 
             help='maximum theta for binning')
    parser.add_argument('-b','--binning', dest="binning", type=str, required=True,
             help='What binning scheme do we want? log or lin')
    parser.add_argument('-i','--fileone', dest="fitscat1", type=str,required=True,
             help='file for first input catalogue')
    parser.add_argument('-j','--filetwo', dest="fitscat2", type=str,required=True,
             help='file for second input catalogue')
    parser.add_argument('-co','--covoutput', dest="covoutfile", type=str,default='cov.txt',
             help='file for covariance output')
    parser.add_argument('-o','--output', dest="outfile", type=str,required=True,
             help='file for output catalogue')
    parser.add_argument('-w','--weighted', dest="weighted", type=str,required=True,
             help='Do we want a weighted measurement?')
    parser.add_argument('--file1e1', dest="cat1e1name", type=str,default='e1',
             help='Name of the e1 component in the first catalogue')
    parser.add_argument('--file1e2', dest="cat1e2name", type=str,default='e2',
             help='Name of the e2 component in the first catalogue')
    parser.add_argument('--file2e1', dest="cat2e1name", type=str,default='e1',
             help='Name of the e1 component in the second catalogue')
    parser.add_argument('--file2e2', dest="cat2e2name", type=str,default='e2',
             help='Name of the e2 component in the second catalogue')
    parser.add_argument('--file1w', dest="cat1wname", type=str,default='weight',
             help='Name of the weight in the first catalogue')
    parser.add_argument('--file2w', dest="cat2wname", type=str,default='weight',
             help='Name of the weight in the second catalogue')
    parser.add_argument('--file1ra', dest="cat1raname", type=str,default='ALPHA_J2000',
             help='Name of the RA column in the first catalogue')
    parser.add_argument('--file2ra', dest="cat2raname", type=str,default='ALPHA_J2000',
             help='Name of the RA column in the second catalogue')
    parser.add_argument('--file1dec', dest="cat1decname", type=str,default='DELTA_J2000',
             help='Name of the Dec column in the first catalogue')
    parser.add_argument('--file2dec', dest="cat2decname", type=str,default='DELTA_J2000',
             help='Name of the Dec column in the second catalogue')
    parser.add_argument('--patch_centers', dest="center_file", type=str, nargs='?',default=None,
             help='File containing centers for performing jackknife/bootstrap covariance calculations')
    parser.add_argument('--nthreads', dest="num_threads", type=int,default=None,
             help='Number of desired parallel threads. If None (default) then uses all available')
    parser.add_argument('--bin_slop', dest="bin_slop", type=float,required=True, 
             help='bin_slop value')
    
    args = parser.parse_args()
    
    nbins = args.nbins
    theta_min = args.theta_min
    theta_max = args.theta_max
    binning = args.binning
    fitscat1 = args.fitscat1
    fitscat2 = args.fitscat2
    outfile = args.outfile
    covoutfile = args.covoutfile
    weighted = args.weighted
    cat1e1name = args.cat1e1name
    cat1e2name = args.cat1e2name
    cat1wname = args.cat1wname
    cat1raname = args.cat1raname
    cat1decname = args.cat1decname
    cat2e1name = args.cat2e1name
    cat2e2name = args.cat2e2name
    cat2wname = args.cat2wname
    cat2raname = args.cat2raname
    cat2decname = args.cat2decname
    num_threads = args.num_threads
    inbinslop = args.bin_slop
    center_file = args.center_file

    print("Using the following parameters:") 
    print(f"nbins = {args.nbins}")
    print(f"theta_min = {args.theta_min}")
    print(f"theta_max = {args.theta_max}")
    print(f"binning = {args.binning}")
    print(f"fitscat1 = {args.fitscat1}")
    print(f"fitscat2 = {args.fitscat2}")
    print(f"outfile = {args.outfile}")
    print(f"covoutfile = {args.covoutfile}")
    print(f"weighted = {args.weighted}")
    print(f"cat1e1name = {args.cat1e1name}")
    print(f"cat1e2name = {args.cat1e2name}")
    print(f"cat1wname = {args.cat1wname}")
    print(f"cat1raname = {args.cat1raname}")
    print(f"cat1decname = {args.cat1decname}")
    print(f"cat2e1name = {args.cat2e1name}")
    print(f"cat2e2name = {args.cat2e2name}")
    print(f"cat2wname = {args.cat2wname}")
    print(f"cat2raname = {args.cat2raname}")
    print(f"cat2decname = {args.cat2decname}")
    print(f"num_threads = {args.num_threads}")
    print(f"bin_slop = {args.bin_slop}")
    print(f"center_file = {args.center_file}")

    #Convert weighted to logical 
    weighted=weighted.lower() in ["true","t","1","y","yes"]
    #Match partial binning labels 
    if binning.lower() in ["lin","linear"]:
        binning='lin'
    elif binning.lower() in ["log","logarithmic","loga","logar"]:
        binning='log'
    else:
        raise ValueError('\"%s\" is not an allowed option for binning' % binning)

    # prepare the catalogues
    if center_file: 
        cat1 = treecorr.Catalog(fitscat1, ra_col=cat1raname, dec_col=cat1decname, ra_units='deg', dec_units='deg', \
                                          g1_col=cat1e1name, g2_col=cat1e2name, w_col=cat1wname,patch_centers=center_file)
        #cat1.write_patch_centers(file_name=outfile+"cens.txt")
        cat2 = treecorr.Catalog(fitscat2, ra_col=cat2raname, dec_col=cat2decname, ra_units='deg', dec_units='deg', \
                                          g1_col=cat2e1name, g2_col=cat2e2name, w_col=cat2wname,patch_centers=cat1.patch_centers)
    else:
        cat1 = treecorr.Catalog(fitscat1, ra_col=cat1raname, dec_col=cat1decname, ra_units='deg', dec_units='deg', \
                                          g1_col=cat1e1name, g2_col=cat1e2name, w_col=cat1wname)
        cat2 = treecorr.Catalog(fitscat2, ra_col=cat2raname, dec_col=cat2decname, ra_units='deg', dec_units='deg', \
                                          g1_col=cat2e1name, g2_col=cat2e2name, w_col=cat2wname)

    # Define the binning based on command line input
    if(binning=='lin'): 
        print("Performing LINEAR binning") 
        if center_file: 
            gg = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin',\
                bin_type='Linear', bin_slop=inbinslop, var_method='jackknife')
        else: 
            gg = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin',\
                bin_type='Linear', bin_slop=inbinslop)
    else: # Log is the default bin_type for Treecorr
        print("Performing LOGARITHMIC binning") 
        if center_file:
            gg = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin', \
                bin_slop=inbinslop, var_method='jackknife')
        else: 
            gg = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin',\
                bin_slop=inbinslop)


    # Calculate the 2pt correlation function
    print("Processing with TreeCorr") 
    gg.process(cat1, cat2, num_threads=num_threads)

    if (weighted):    
        print("Performing a WEIGHTED treecor measurement (requires double run)") 
        # prepare the weighted_square catalogues - hack so that Treecorr returns the correct Npairs for a weighted sample

        cat1_wsq = treecorr.Catalog(fitscat1, ra_col=cat1raname, dec_col=cat1decname, ra_units='deg', dec_units='deg', \
                                      g1_col=cat1e1name, g2_col=cat1e2name, w_col=cat1wname+'_sq')
        cat2_wsq = treecorr.Catalog(fitscat2, ra_col=cat2raname, dec_col=cat2decname, ra_units='deg', dec_units='deg', \
                                      g1_col=cat2e1name, g2_col=cat2e2name, w_col=cat2wname+'_sq')

        # Define the binning based on command line input
        if(binning=='lin'): 
            print("Performing LINEAR binning (wsq run)") 
            gg_wsq = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin',\
                                        bin_type='Linear', bin_slop=inbinslop)
        else: # Log is the default bin_type for Treecorr
            print("Performing LOGARITHMIC binning (wsq run)") 
            gg_wsq = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin', \
                                        bin_slop=inbinslop)    

        # Calculate the weighted square 2pt correlation function
        print("Processing with TreeCorr (wsq)") 
        gg_wsq.process(cat1_wsq,cat2_wsq, num_threads=num_threads)

        # Calculate the weighted Npairs = sum(weight_a*weight_b)^2 / sum(weight_a^2*weight_b^2)

        npairs_weighted = (gg.weight)*(gg.weight)/gg_wsq.weight

        #Use treecorr to write out the output file updating the npairs column and praise-be for Jarvis and his well documented code
        #as sigma_xip = sigma_xim, I've replaced sigma_xim with the raw npairs so we can store it in case useful at any point
        
        try: 
            #Try with the new treecorr syntax
            with treecorr.util.make_writer(outfile,precision=12) as writer:
                writer.write(
                    ['r_nom','meanr','meanlogr','xip','xim','xip_im','xim_im','sigma_xip','sigma_xim', 'npairs', 'weight','npairs_weighted' ],
                    [ gg.rnom,gg.meanr, gg.meanlogr,gg.xip, gg.xim, gg.xip_im, gg.xim_im, np.sqrt(gg.varxip), np.sqrt(gg.varxim), gg.npairs, gg.weight, npairs_weighted])
        except: 
            #Try with the old treecorr syntax 
            treecorr.util.gen_write(outfile,
                    ['r_nom','meanr','meanlogr','xip','xim','xip_im','xim_im','sigma_xip','sigma_xim', 'npairs', 'weight','npairs_weighted' ],
                    [ gg.rnom,gg.meanr, gg.meanlogr,gg.xip, gg.xim, gg.xip_im, gg.xim_im, np.sqrt(gg.varxip), np.sqrt(gg.varxim), gg.npairs, 
                    gg.weight, npairs_weighted], precision=12)


    else:

        # Write it out unweighted npairs and praise-be again for Jarvis and his well documented code
        gg.write(outfile, precision=12)

    if center_file is not None:
        np.savetxt(covoutfile,gg.cov)


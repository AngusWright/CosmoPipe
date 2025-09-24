# ----------------------------------------------------------------
# File Name:           calc_spatial_bins_treecorr.py
# Author:              Catherine Heymans (heymans@roe.ac.uk)
# Description:         short python script to run treecorr to calculate xi_+/- 
#                      given a KiDS fits catalogue
#                      script will need to change if keywords in KIDS cats are updated
# ----------------------------------------------------------------

import treecorr
from argparse import ArgumentParser

if __name__ == '__main__':

    # Read in user input to set the nbins, theta_min, theta_max, lin_not_log, fitscat1, fitscat2, outfilename, weighted
    # Specify the input arguments
    parser = ArgumentParser(description='Compute 2cpfs from user inputs')
    parser.add_argument('-i','--fileone', dest="fitscat1", type=str,required=True,
             help='file for first input catalogue')
    parser.add_argument('-o','--output', dest="outfile", type=str,required=True,
             help='file for output catalogue')
    parser.add_argument('--file1ra', dest="cat1raname", type=str,default='ALPHA_J2000',
             help='Name of the RA column in the first catalogue')
    parser.add_argument('--file1dec', dest="cat1decname", type=str,default='DELTA_J2000',
             help='Name of the Dec column in the first catalogue')
    parser.add_argument('--nthreads', dest="num_threads", type=int,default=None,
             help='Number of desired parallel threads. If None (default) then uses all available')
    parser.add_argument('--npatch', dest="npatch", type=int,default=None,
             help='Number of desired parallel threads. If None (default) then uses all available')
    
    args = parser.parse_args()
    
    fitscat1 = args.fitscat1
    outfile = args.outfile
    cat1raname = args.cat1raname
    cat1decname = args.cat1decname
    num_threads = args.num_threads
    npatch = args.npatch

    print("Using the following parameters:") 
    print(f"fitscat1 = {args.fitscat1}")
    print(f"outfile = {args.outfile}")
    print(f"cat1raname = {args.cat1raname}")
    print(f"cat1decname = {args.cat1decname}")
    print(f"num_threads = {args.num_threads}")

    cat1 = treecorr.Catalog(fitscat1, ra_col=cat1raname, dec_col=cat1decname, ra_units='deg', dec_units='deg', \
                            npatch=npatch)
    cat1.write_patch_centers(file_name=outfile)


# ----------------------------------------------------------------
# File Name:           calc_wt_w_treecorr.py
# Author:              Catherine Heymans (heymans@roe.ac.uk)
#                      Adapted by Andrej Dvornik to include w(theta) estimation and
#                      modified for CosmoPipe
# Description:         run treecorr to calculate w(theta) 
#                      uses Landy-Szalay estimator w(theta) = (DD-DR-RD+RR)/RR
#                      where D: data, R: randoms
#                      script will need to change if keywords in KIDS cats are updated
#  Treecorr doc: https://rmjarvis.github.io/TreeCorr/_build/html/correlation2.html
# ----------------------------------------------------------------

import treecorr
import numpy as np
import argparse

## Calculate shape noise given noisy & noise-free shear
def subtractNoise(g_1, g_2, eps_1, eps_2):
    g   = g_1 + 1j * g_2
    g_c = g_1 - 1j * g_2
    eps = eps_1 + 1j * eps_2
    e = (eps - g) / (1.0 - g_c*eps)
    e = np.array([e.real, e.imag])
    return e

if __name__ == '__main__':
    # Read in user input to set the nbins, theta_min, theta_max, lin_not_log, lenscat, rancat, sourcecat, outfilename, weighted
    # Read in user input to set the nbins, theta_min, theta_max, lin_not_log, fitscat1, fitscat2, outfilename, weighted
    # Specify the input arguments
    parser = argparse.ArgumentParser(description='Compute clustering from user inputs')
    parser.add_argument('-n', '--nbins', dest="nbins",type=int,
        help='Number of theta bins', metavar="nBins",required=True)
    parser.add_argument('-tmin','--theta_min', dest="theta_min", type=float,required=True,
             help='minimum theta for binning')
    parser.add_argument('-tmax','--theta_max', dest="theta_max", type=float,required=True,
             help='maximum theta for binning')
    parser.add_argument('-b','--binning', dest="binning", type=str, required=True,
             help='What binning scheme do we want? log or lin')
    parser.add_argument('-l','--lenscat', dest="lenscat", type=str,required=True,
             help='file for first input catalogue')
    parser.add_argument('-r','--randcat', dest="randcat", type=str,required=True,
             help='file for second input catalogue')
    parser.add_argument('-s','--sourcecat', dest="sourcecat", type=str,required=False, default='None',
             help='file for second input catalogue')
    parser.add_argument('-co','--covoutput', dest="covoutfile", type=str,required=True,
             help='file for covariance output')
    parser.add_argument('-o','--output', dest="outfile", type=str,required=True,
             help='file for output catalogue')
    parser.add_argument('-w','--weighted', dest="weighted", type=str,required=True,
             help='Do we want a weighted measurement?')
    parser.add_argument('--lensw', dest="lenswname", type=str,default='weight',
             help='Name of the weight in the lens catalogue')
    parser.add_argument('--lensra', dest="lensraname", type=str,default='ALPHA_J2000',
             help='Name of the RA column in the lens catalogue')
    parser.add_argument('--lensdec', dest="lensdecname", type=str,default='DELTA_J2000',
             help='Name of the Dec column in the lens catalogue')
    parser.add_argument('--randra', dest="randraname", type=str,default='ALPHA_J2000',
             help='Name of the RA column in the randoms catalogue')
    parser.add_argument('--randdec', dest="randdecname", type=str,default='DELTA_J2000',
             help='Name of the Dec column in the randoms catalogue')
    parser.add_argument('--patch_centers', dest="center_file", type=str, nargs='?',default=None,
             help='File containing centers for performing jackknife/bootstrap covariance calculations')
    parser.add_argument('--nthreads', dest="num_threads", type=int,default=None,
             help='Number of desired parallel threads. If None (default) then uses all available')
    parser.add_argument('--bin_slop_NN', dest="bin_slop_NN", type=float,required=True,
             help='bin_slop value for NN cross correlation')
    
    args = parser.parse_args()
    
    nbins = args.nbins
    theta_min = args.theta_min
    theta_max = args.theta_max
    binning = args.binning
    outfile = args.outfile
    covoutfile = args.covoutfile
    weighted = args.weighted
    lenswname = args.lenswname
    lensraname = args.lensraname
    lensdecname = args.lensdecname
    randraname = args.randraname
    randdecname = args.randdecname
    
    num_threads = args.num_threads
    inbinslop_NN = args.bin_slop_NN
    center_file = args.center_file
    
    clustering = args.clustering

    print("Using the following parameters:")
    print(f"nbins = {args.nbins}")
    print(f"theta_min = {args.theta_min}")
    print(f"theta_max = {args.theta_max}")
    print(f"binning = {args.binning}")
    print(f"lenscat = {args.lenscat}")
    print(f"randcat = {args.randcat}")
    print(f"outfile = {args.outfile}")
    print(f"covoutfile = {args.covoutfile}")
    print(f"weighted = {args.weighted}")
    print(f"lenswname = {args.lenswname}")
    print(f"lensraname = {args.lensraname}")
    print(f"lensdecname = {args.lensdecname}")
    print(f"randraname = {args.randraname}")
    print(f"randdecname = {args.randdecname}")
    print(f"num_threads = {args.num_threads}")
    print(f"bin_slop_NN = {args.bin_slop_NN}")
    print(f"center_file = {args.center_file}")
    print(f"clustering = {args.clustering}")

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
    if lenswname in ["None","none",""]:
        lenswname = None

    if center_file:
        # center_file for patch centers for jackknife/bootstrap covariance. If given calculate covariance
        lenscat = treecorr.Catalog(args.lenscat, ra_col=lensraname, dec_col=lensdecname, ra_units='deg',
                                   dec_units='deg', w_col=lenswname, patch_centers=center_file)
        rancat = treecorr.Catalog(args.randcat, ra_col=randraname, dec_col=randdecname, ra_units='deg',
                                  dec_units='deg', patch_centers=lenscat.patch_centers, every_nth=100)
    else:
        lenscat = treecorr.Catalog(args.lenscat, ra_col=lensraname, dec_col=lensdecname,
                                   ra_units='deg', dec_units='deg', w_col=lenswname)
        rancat = treecorr.Catalog(args.randcat, ra_col=randraname, dec_col=randdecname,
                                  ra_units='deg', dec_units='deg', every_nth=100)
    

    ## Set bin_slop
    #if nbins > 100: ## Fine-binning
    #    inbinslop_NN = 1.0 # when using fine bins I find this is suitable
    #    inbinslop_NG = 1.2
    #else: ## Broad bins
    #    inbinslop_NN = 0.03
    #    inbinslop_NG = 0.05
    
    # Define the binning based on command line input
    if binning == 'lin':
        config = {'min_sep': theta_min,
                  'max_sep': theta_max,
                  'nbins'  : nbins,
                  'sep_units': 'arcmin',
                  'bin_type': 'Linear',
                  }
    else:
        config = {'min_sep': theta_min,
                  'max_sep': theta_max,
                  'nbins'  : nbins,
                  'sep_units': 'arcmin',
                  }
    

        # Number of lens pairs
        dd = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
        # Number of random pairs
        rr = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
        # Number of lens-random pairs
        dr = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
        # Number of random-lens pairs
        rd = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
    

    # Now calculate the different 2pt correlation functions
    dd.process(lenscat, num_threads=num_threads)
    rr.process(rancat, num_threads=num_threads)
    dr.process(lenscat, rancat, num_threads=num_threads)
    rd.process(rancat, lenscat, num_threads=num_threads)
    
    #We also need to calculate the random oversampling factor
    N_oversample=np.sum(rancat.w)/np.sum(lenscat.w)

    # Treecorr does this for us automatically, provided we pass the required pair counts
    wt, varxi = dd.calculateXi(rr=rr,dr=dr,rd=rd)
    
    # TODO: ADD WEIGHTED PAIR COUNT CALCULATION HERE!
    
    #Use treecorr to write out the output file and praise-be once more for Jarvis and his well documented code
    with treecorr.util.make_writer(outfile, precision=12) as writer:
        writer.write(
            ['r_nom','meanr','meanlogr','wtheta','sigma', 'nocor_wtheta', 'weight', 'npairs'],
            np.nan_to_num([ dd.rnom, dd.meanr, dd.meanlogr, wt, np.sqrt(dd.varxi), dd.xi, dd.weight, dd.npairs],
                            nan=0.0, posinf=0.0, neginf=0.0))
            
    if center_file is not None:
        # center_file for patch centers for jackknife/bootstrap covariance. If given calculate covariance
        cov_wt = dd.estimate_cov(method='jackknife')
        samples_wt, w_wt = dd.build_cov_design_matrix(method='jackknife')
        np.savetxt(covoutfile, cov_wt)
        #np.savetxt(outfile+'_wt_cov_samples_new.txt', samples_wt)
        #np.savetxt(outfile+'_wt_cov_w_new.txt', w_wt)

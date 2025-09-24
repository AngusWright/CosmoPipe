# ----------------------------------------------------------------
# File Name:           calc_gt_w_treecorr.py
# Author:              Catherine Heymans (heymans@roe.ac.uk)
#                      Adapted by Andrej Dvornik to include w(theta) estimation and
#                      modified for CosmoPipe
# Description:         short python script to run treecorr to calculate gamma_t
#                      we're using the Mandelbaum estimator where the randoms are subtracted
#                      so we need a lens, source and random catalogue 
#                      script will need to change if keywords in KIDS cats are updated
#  Treecorr doc: https://rmjarvis.github.io/TreeCorr/_build/html/correlation2.html
# ----------------------------------------------------------------

import treecorr
import numpy as np
import argparse

# import sys
# import astropy.io.fits as fits


# TODO: Either change the name of this file to calc_gt_wt_w_treecorr.py 
# or move the clustering part to a new file. The latter is preferable as other files only do 
# one type of correlation using treecorr.

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
    parser = argparse.ArgumentParser(description='Compute galaxy-galaxy lensing and or/clustering from user inputs')
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
    parser.add_argument('--e1', dest="e1name", type=str,default='e1', required=False,
             help='Name of the e1 component in the source catalogue')
    parser.add_argument('--e2', dest="e2name", type=str,default='e2', required=False,
             help='Name of the e2 component in the source catalogue')
    parser.add_argument('--lensw', dest="lenswname", type=str,default='weight',
             help='Name of the weight in the lens catalogue')
    parser.add_argument('--sourcew', dest="sourcewname", type=str,default='weight',
             help='Name of the weight in the source catalogue')
    parser.add_argument('--lensra', dest="lensraname", type=str,default='ALPHA_J2000',
             help='Name of the RA column in the lens catalogue')
    parser.add_argument('--lensdec', dest="lensdecname", type=str,default='DELTA_J2000',
             help='Name of the Dec column in the lens catalogue')
    parser.add_argument('--randra', dest="randraname", type=str,default='ALPHA_J2000',
             help='Name of the RA column in the randoms catalogue')
    parser.add_argument('--randdec', dest="randdecname", type=str,default='DELTA_J2000',
             help='Name of the Dec column in the randoms catalogue')
    parser.add_argument('--sourcera', dest="sourceraname", type=str,default='ALPHA_J2000',
             help='Name of the RA column in the source catalogue')
    parser.add_argument('--sourcedec', dest="sourcedecname", type=str,default='DELTA_J2000',
             help='Name of the Dec column in the source catalogue')
    parser.add_argument('--patch_centers', dest="center_file", type=str, nargs='?',default=None,
             help='File containing centers for performing jackknife/bootstrap covariance calculations')
    parser.add_argument('--nthreads', dest="num_threads", type=int,default=None,
             help='Number of desired parallel threads. If None (default) then uses all available')
    parser.add_argument('--bin_slop_NN', dest="bin_slop_NN", type=float,required=True,
             help='bin_slop value for NN cross correlation')
    parser.add_argument('--bin_slop_NG', dest="bin_slop_NG", type=float,required=True,
             help='bin_slop value for NG cross correlation')
    parser.add_argument('--clustering', dest="clustering", type=bool, const=True,default=False,
             help='Run clustering', nargs='?')
    parser.add_argument('--lensing', dest="lensing", type=bool, const=True,default=False,
             help='Run galaxy-galaxy lensing', nargs='?')
    
    args = parser.parse_args()
    
    nbins = args.nbins
    theta_min = args.theta_min
    theta_max = args.theta_max
    binning = args.binning
    outfile = args.outfile
    covoutfile = args.covoutfile
    weighted = args.weighted
    e1name = args.e1name
    e2name = args.e2name
    lenswname = args.lenswname
    sourcewname = args.sourcewname
    lensraname = args.lensraname
    lensdecname = args.lensdecname
    randraname = args.randraname
    randdecname = args.randdecname
    sourceraname = args.sourceraname
    sourcedecname = args.sourcedecname
    
    num_threads = args.num_threads
    inbinslop_NN = args.bin_slop_NN
    inbinslop_NG = args.bin_slop_NG
    center_file = args.center_file
    
    lensing = args.lensing
    clustering = args.clustering

    print("Using the following parameters:")
    print(f"nbins = {args.nbins}")
    print(f"theta_min = {args.theta_min}")
    print(f"theta_max = {args.theta_max}")
    print(f"binning = {args.binning}")
    print(f"lenscat = {args.lenscat}")
    print(f"randcat = {args.randcat}")
    print(f"sourcecat = {args.sourcecat}")
    print(f"outfile = {args.outfile}")
    print(f"covoutfile = {args.covoutfile}")
    print(f"weighted = {args.weighted}")
    print(f"e1name = {args.e1name}")
    print(f"e2name = {args.e2name}")
    print(f"lenswname = {args.lenswname}")
    print(f"sourcewname = {args.sourcewname}")
    print(f"lensraname = {args.lensraname}")
    print(f"lensdecname = {args.lensdecname}")
    print(f"randraname = {args.randraname}")
    print(f"randdecname = {args.randdecname}")
    print(f"sourceraname = {args.sourceraname}")
    print(f"sourcedecname = {args.sourcedecname}")
    print(f"num_threads = {args.num_threads}")
    print(f"bin_slop_NN = {args.bin_slop_NN}")
    print(f"bin_slop_NG = {args.bin_slop_NG}")
    print(f"center_file = {args.center_file}")
    print(f"lensing = {args.lensing}")
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

        lenscat = treecorr.Catalog(args.lenscat, ra_col=lensraname, dec_col=lensdecname, ra_units='deg',
                                   dec_units='deg', w_col=lenswname, patch_centers=center_file)
        rancat = treecorr.Catalog(args.randcat, ra_col=randraname, dec_col=randdecname, ra_units='deg',
                                  dec_units='deg', patch_centers=lenscat.patch_centers, every_nth=100)
        if lensing:
            sourcecat = treecorr.Catalog(args.sourcecat, ra_col=sourceraname, dec_col=sourcedecname,
                                    ra_units='deg', dec_units='deg', g1_col=e1name, g2_col=e2name,
                                    w_col=sourcewname, patch_centers=lenscat.patch_centers)#, flip_g1=True)
    else:
        lenscat = treecorr.Catalog(args.lenscat, ra_col=lensraname, dec_col=lensdecname,
                                   ra_units='deg', dec_units='deg', w_col=lenswname)
        rancat = treecorr.Catalog(args.randcat, ra_col=randraname, dec_col=randdecname,
                                  ra_units='deg', dec_units='deg', every_nth=100)
        if lensing:
            sourcecat = treecorr.Catalog(args.sourcecat, ra_col=sourceraname, dec_col=sourcedecname,
                                    ra_units='deg', dec_units='deg', g1_col=e1name, g2_col=e2name, w_col=sourcewname)#, flip_g1=True)
    
        
    

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
    # Set-up the different correlations that we want to measure
    if lensing:
            # Number of source lens pairs
            nlns = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
            # Number of source random pairs
            nrns = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
            # Average shear around lenses
            ls = treecorr.NGCorrelation(config=config, bin_slop=inbinslop_NG)
            # Average shear around randoms
            rs = treecorr.NGCorrelation(config=config, bin_slop=inbinslop_NG)
    if clustering:
            # Number of lens pairs
            dd = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
            # Number of random pairs
            rr = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
            # Number of lens-random pairs
            dr = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
            # Number of random-lens pairs
            rd = treecorr.NNCorrelation(config=config, bin_slop=inbinslop_NN)
    

    # Now calculate the different 2pt correlation functions
    if lensing:
        nlns.process(lenscat, sourcecat, num_threads=num_threads)
        nrns.process(rancat, sourcecat, num_threads=num_threads)
        ls.process(lenscat, sourcecat, num_threads=num_threads)
        rs.process(rancat, sourcecat, num_threads=num_threads)
    if clustering:
        dd.process(lenscat, num_threads=num_threads)
        rr.process(rancat, num_threads=num_threads)
        dr.process(lenscat, rancat, num_threads=num_threads)
        rd.process(rancat, lenscat, num_threads=num_threads)
    
    #We also need to calculate the random oversampling factor
    N_oversample=np.sum(rancat.w)/np.sum(lenscat.w)

    if lensing:
        # We will use the Mandelbaum 2006 estimator which includes both the random and boost correction.
        # It is given by
        # gt = (SD-SR)/NsNr
        # SD = sum of shear around source-lens pairs
        # SR = sum of shear around source-random pairs
        # NrNs = number of source random pairs
        # Note that we have a different number of randoms from lenses so we also need to make
        # sure that we rescale NrNs accordingly
    
        # The easiest way to do this in Treecorr is
        # gt = (SD/NlNs)*NlNs/NrNs - SR/NrNs
        # where NsNl = number of source lens pairs
        #
        # SD/NsNl = ls.xi
        # NlNs = nlns.weight/nlns.tot
        # NrNs = nrns.weight/nrns.tot
        # SR/NrNs = rs.xi
    
        #gamma_t = ls.xi*(nlns.weight/nrns.weight)*N_oversample - rs.xi
        #gamma_x = ls.xi_im*(nlns.weight/nrns.weight)*N_oversample - rs.xi_im
        func_gamma_t = lambda corrs: corrs[0].xi*(corrs[1].weight/corrs[2].weight)*N_oversample - corrs[3].xi
        func_gamma_x = lambda corrs: corrs[0].xi_im*(corrs[1].weight/corrs[2].weight)*N_oversample - corrs[3].xi_im
        
        corrs_gamma_t = [ls, nlns, nrns, rs]
        corrs_gamma_x = [ls, nlns, nrns, rs]
        
        gamma_t = func_gamma_t(corrs_gamma_t)
        gamma_x = func_gamma_x(corrs_gamma_x)
        
        if center_file is not None:
            cov_gt = treecorr.estimate_multi_cov(corrs_gamma_t, method='jackknife', func=func_gamma_t)
            samples_gt, w_gt = treecorr.build_multi_cov_design_matrix(corrs_gamma_t, method='jackknife', func=func_gamma_t)
            np.savetxt(covoutfile, cov_gt)
            #np.savetxt(outfile+'_gt_cov_samples_new.txt', samples_gt)
            #np.savetxt(outfile+'_gt_cov_w_new.txt', w_gt)
    
        if weighted:
            # prepare the weighted_square catalogues - hack so that Treecorr returns the correct Npairs for a weighted sample
            if lenswname == None:
                lenswnamesq = None
            else:
                lenswnamesq = lenswname+'_sq'
            lenscat_wsq = treecorr.Catalog(args.lenscat, ra_col=lensraname, dec_col=lensdecname, ra_units='deg', dec_units='deg',
                                        w_col=lenswnamesq)
            sourcecat_wsq = treecorr.Catalog(args.sourcecat, ra_col=sourceraname, dec_col=sourcedecname, ra_units='deg', dec_units='deg',
                                        g1_col=e1name, g2_col=e2name, w_col=sourcewname+'_sq')
    
            # Define the binning based on command line input
        
            # Average shear around lenses
            ls_wsq = treecorr.NGCorrelation(config=config, bin_slop=inbinslop_NG)
    
            # Calculate the weighted square 2pt correlation function
            ls_wsq.process(lenscat_wsq, sourcecat_wsq)
        
            # Calculate the weighted Npairs = sum(weight_r*weight_s)^2 / [N_rnd**2 * sum(weight_l^2*weight_s^2)]
            npairs_weighted = (rs.weight)*(rs.weight)/(N_oversample**2 * ls_wsq.weight)
    
            #The exact version is with a few percent of the simple alternative
            #npairs_weighted_simple = (ls.weight)*(ls.weight)/(ls_wsq.weight)
    
            #Use treecorr to write out the output file and praise-be once more for Jarvis and his well documented code
            with treecorr.util.make_writer(outfile, precision=12) as writer:
                writer.write(
                    ['r_nom','meanr','meanlogr','gamT','gamX','sigma','weight','npairs_weighted', 'nocor_gamT', 'nocor_gamX',
                    'rangamT','rangamX','ransigma'],
                    np.nan_to_num([ ls.rnom,ls.meanr, ls.meanlogr, gamma_t, gamma_x, np.sqrt(ls.varxi), npairs_weighted, ls.npairs,
                    ls.xi, ls.xi_im, rs.xi, rs.xi_im, np.sqrt(rs.varxi)], nan=0.0, posinf=0.0, neginf=0.0))
    
        else:
            #Use treecorr to write out the output file and praise-be once more for Jarvis and his well documented code
            with treecorr.util.make_writer(outfile, precision=12) as writer:
                writer.write(
                    ['r_nom','meanr','meanlogr','gamT','gamX','sigma','weight', 'nocor_gamT', 'nocor_gamX',
                    'rangamT','rangamX','ransigma','npairs_weighted'],
                    np.nan_to_num([ ls.rnom,ls.meanr, ls.meanlogr, gamma_t, gamma_x, np.sqrt(ls.varxi), ls.weight,
                    ls.xi, ls.xi_im, rs.xi, rs.xi_im, np.sqrt(rs.varxi), ls.npairs], nan=0.0, posinf=0.0, neginf=0.0))
            
    if clustering:
        # We will use the Landy-Szalay estimator:
        # It is given by
        # wt = (DD-DR-RD+RR)/RR
    
        # Treecorr does this for us automatically, provided we pass the required pair counts
        wt, varxi = dd.calculateXi(rr=rr,dr=dr,rd=rd)
        
        # TODO: ADD WEIGHTED PAIR COUNT CALCULATION HERE!
        
        #Use treecorr to write out the output file and praise-be once more for Jarvis and his well documented code
        with treecorr.util.make_writer(outfile, precision=12) as writer:
            writer.write(
                ['r_nom','meanr','meanlogr','wtheta','sigma','weight', 'nocor_wtheta', 'npairs_weighted'],
                np.nan_to_num([ dd.rnom, dd.meanr, dd.meanlogr, wt, np.sqrt(dd.varxi), dd.weight, dd.xi, dd.npairs],
                               nan=0.0, posinf=0.0, neginf=0.0))
                
        if center_file is not None:
            cov_wt = dd.estimate_cov(method='jackknife')
            samples_wt, w_wt = dd.build_cov_design_matrix(method='jackknife')
            np.savetxt(covoutfile, cov_wt)
            #np.savetxt(outfile+'_wt_cov_samples_new.txt', samples_wt)
            #np.savetxt(outfile+'_wt_cov_w_new.txt', w_wt)

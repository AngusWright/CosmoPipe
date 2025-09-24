
    ######################################
    ##  save_and_check_Phase1.py        ##
    ##  Marika Asgari                   ##
    ##  Version 2020.04.21              ##
    ######################################

# This is based on Linc's save_and_check_twopoint. 
# It has been adapted to make .fits files for the Phase1 real data

import sys

import numpy as np
import scipy.interpolate as itp
import astropy.io.fits as fits
import os
from argparse import ArgumentParser

# set the path to scale_cuts here
sys.path.append("@RUNROOT@/INSTALL/kcap/modules/scale_cuts_new/")
sys.path.append("@RUNROOT@/@SCRIPTPATH@/")
import wrapper_twopoint as wtp
import wrapper_twopoint2 as wtp2

###############################################################################
## Main functions
#{{{
def saveFitsTwoPoint(
        nbTomoN=2,
        nbTomoG=5,
        N_theta=9,
        theta_min=0.5,
        theta_max=300,
        N_ell=8,
        ell_min=100,
        ell_max=1500,
        nbModes=5,
        prefix_Flinc='',
        prefix_CosmoSIS='',
        scDict={},
        meanTag=None,
        meanName=None,
        covTag=None,
        covName=None,
        nOfZNameList=None,
        nGalList=None,
        sigmaEpsList=None,
        saveName=None
    ):
    """
    This is a general function to save twopoint file.
    
    Parameters
    ----------
    nbTomoN : int, optional
        Number of lens bins
    nbTomoG : int, optional
        Number of source bins
    N_theta : int, optional
        Number of theta bins
    theta_min : float, optional
        Lower limit of theta bins
    theta_max : float, optional
        Upper limit of theta bins
    N_ell : int, optional
        Number of ell bins
    ell_min : float, optional
        Lower limit of ell bins
    ell_max : float, optional
        Upper limit of ell bins
    nbModes : int, optional
        Number of COSEBIs modes
    prefix_Flinc : string, optional
        Prefix of Flinc input directory; only concerned if meanTag = 'Flinc'
    prefix_CosmoSIS : string, optional
        Prefix of CosmoSIS theory input directory
        Only concerned if meanTag = 'CosmoSIS'
    scDict : dict, optional
        Dictionary containing scale-cut arguments
        Same format as in kcap ini files
        All dictionary keys & values have to be in lower case
    meanTag : {None, 'Flinc', 'CosmoSIS', 'variable', 'file'}, optional
        Method of mean input. One of
        
        None
            No mean vector
        
        ``Flinc``
            Calculate Flinc means specified by `prefix_Flinc`
            `meanName` is then interpreted as the bird tag to be used
        
        ``CosmoSIS``
            Read theory outputs specified by `prefix_CosmoSIS`
            `meanName` is then ignored
        
        ``variable``
            Read `meanName` directly as a python object,
            supposed to be a list or an array
            Should already be ordered
          
        ``file``
            Read `meanName` as the path to a single column file
            If the file does not have '.npy' or '.fits' as extension,
            it is interpreted as an ASCII file.
    meanName : object, optional
        See `meanTag`
    covTag : {None, 'Flinc', 'list', 'variable', 'file'}, optional
        Method of covariance input. One of
        
        None
            No covariance
        
        ``Flinc``
            Calculate Flinc covariance specified by `prefix_Flinc`
            `covName` is then interpreted as the bird tag to be used
        
        ``list``
            Read theory covariance specified by `covName` as under Benjamin's 
            list format
            If the file has several terms (G, NG, SSC, etc.), it sums up all 
            terms automatically.
            All nan values are automatically replaced with 0
            Should not already apply scale cuts in the file
        
        ``variable``
            Read `covName` directly as a python object,
            supposed to be a squared 2D-array
            Should already be ordered
          
        ``file``
            Read `covName` as the path to a file containing a squared matrix
            If the file does not have '.npy' or '.fits' as extension,
            it is interpreted as an ASCII file.
    nOfZNameList : None or string list
        List of n(z) file names
        One file for each tomographic bin
        Has to be ASCII
        Should share the same z bins
        If None, no n(z) will be saved
    nGalList : float list
        List of n_gal
    sigmaEpsList : float list
        List of sigma_eps
        The length can be nbTomoG or nbTomoN+nbTomoG
    savename : string
        Path of the twopoint file to be saved
        
    Returns
    -------
    Nothing, but output a file
    """
    
    wtp2.saveFitsTwoPoint(
        nbTomoN=nbTomoN,
        nbTomoG=nbTomoG,
        N_theta_ee=N_theta,
        theta_min_ee=theta_min,
        theta_max_ee=theta_max,
        N_ell_ee=N_ell,
        ell_min_ee=ell_min,
        ell_max_ee=ell_max,
        nbModes_ee=nbModes,
        prefix_Flinc=prefix_Flinc,
        prefix_CosmoSIS=prefix_CosmoSIS,
        scDict=scDict,
        meanTag=meanTag,
        meanName=meanName,
        covTag=covTag,
        covName=covName,
        nOfZNameList=nOfZNameList,
        nGalList=nGalList,
        sigmaEpsList=sigmaEpsList,
        saveName=saveName
    )
    return


# copied from cosmosis
def load_histogram_form(ext):
    # Load the various z columns.
    # The cosmosis code is expecting something it can spline
    # so  we need to give it more points than this - we will
    # give it the intermediate z values (which just look like a step
    # function)
    zlow = ext.data['Z_LOW']
    zhigh = ext.data['Z_HIGH']
    # First bin.
    i = 1
    bin_name = 'BIN{0}'.format(i)
    nz = []
    z = ext.data['Z_MID']
    # Load the n(z) columns, bin1, bin2, ...
    while bin_name in ext.data.names:
        col = ext.data[bin_name]
        nz.append(col)
        i += 1
        bin_name = 'BIN{0}'.format(i)
    # First bin.
    i = 1
    ngal_name = "NGAL_"+str(i)
    n_bar= []
    while ngal_name in ext.header.keys():
        n_b = ext.header[ngal_name]
        n_bar.append(n_b)
        i += 1
        ngal_name = "NGAL_"+str(i)
    nbin = len(nz)
    print("        Found {0} bins".format(nbin))
    nz = np.array(nz)
    # z, nz = ensure_starts_at_zero(z, nz)
    for col in nz:
        norm = np.trapz(col, z)
        col /= norm
    return z, nz, n_bar


def mkdir_mine(dirName):
    try:
        # Create target Directory
        os.mkdir(dirName)
        print("Directory " , dirName ,  " Created ") 
    except FileExistsError:
        print("Directory " , dirName ,  " already exists")

def saveFitsCOSEBIs(datavec,covariance, outputFilename):
    scDict = {
        # 'use_stats': 'En'.lower()
        'use_stats': 'En Bn'.lower()
    }

    nOfZNameList=list(nz.values())

    nGalList     = nGal_source#.tolist()
    sigmaEpsList = sigma_e#.tolist()
    print(len(nGalList))
    print(len(nOfZNameList))
    print(nOfZNameList)
    print(nz.values())
    saveFitsTwoPoint(
        nbTomoN=0,
        nbTomoG=len(nOfZNameList),
        nbModes=args.nmaxcosebis,
        prefix_Flinc=None,
        prefix_CosmoSIS=None,
        scDict=scDict,
        meanTag='file', 
        meanName=datavec,
        covTag='file', 
        covName=covariance,
        nOfZNameList=nOfZNameList, 
        nGalList=nGalList, 
        sigmaEpsList=sigmaEpsList,
        saveName=outputFilename
    )
    return

def saveFitsBP(datavec,covariance, outputFilename):
    scDict = {
        'use_stats': 'PeeE PeeB'.lower()
    }

    nOfZNameList=list(nz.values())

    nGalList     = nGal_source#.tolist()
    sigmaEpsList = sigma_e#.tolist()
    
    saveFitsTwoPoint(
        nbTomoN=0,
        nbTomoG=len(nOfZNameList),
        N_ell=args.nbandpowers,
        ell_min=args.ellmin, 
        ell_max=args.ellmax,
        # nbModes=5,
        prefix_Flinc=None,
        prefix_CosmoSIS=None,
        scDict=scDict,
        meanTag='file', 
        meanName=datavec,
        covTag='file', 
        covName=covariance,
        nOfZNameList=nOfZNameList, 
        nGalList=nGalList, 
        sigmaEpsList=sigmaEpsList,
        saveName=outputFilename
    )
    return

def saveFitsXipm(datavec,covariance, outputFilename):
    scDict = {
        'use_stats': 'xiP xiM'.lower()
    }

    nOfZNameList=list(nz.values())

    nGalList     = nGal_source#.tolist()
    sigmaEpsList = sigma_e#.tolist()
    
    saveFitsTwoPoint(
        nbTomoN=0,
        nbTomoG=len(nOfZNameList),
        N_theta=args.nxipm,
        theta_min=args.thetamin,
        theta_max=args.thetamax,
        prefix_Flinc=None,
        prefix_CosmoSIS=None,
        scDict=scDict,
        meanTag='file', 
        meanName=datavec,
        covTag='file', 
        covName=covariance,
        nOfZNameList=nOfZNameList, 
        nGalList=nGalList, 
        sigmaEpsList=sigmaEpsList,
        saveName=outputFilename
    )
    return


###############################################################################
## Checks and plots

def plot_redshift(filename,title,savename):
    import matplotlib.pyplot as plt
    F=fits.open(filename)
    ext=F["nz_source"]
    z_source, nz_source, n_bar_source=load_histogram_form(ext)

    try:
        ext=F["nz_lens"]
        z_lens, nz_lens, n_bar_lens=load_histogram_form(ext)
        plot_lenses=True
    except:
        print("no lenses given")
        plot_lenses=False

    F.close()

    if(plot_lenses):
        plt.clf()
        ax=plt.subplot(2,1,1)
        plt.ylabel("P(z)")
        plt.title(title)
        plt.setp(ax.get_xticklabels(),  visible=False)
        plt.subplots_adjust(wspace=0,hspace=0)
        for bin1 in range(len(nz_lens)):
            plt.xlim(0,2.0)
            plt.plot(z_lens,nz_lens[bin1],label='lens '+str(bin1+1))
            plt.legend(loc='best')

        ax=plt.subplot(2,1,2)
        plt.setp(ax.get_xticklabels(),  visible=True)
        for bin1 in range(len(nz_source)):
            plt.xlim(0,2.0)
            plt.plot(z_source,nz_source[bin1],label='source '+str(bin1+1))
            plt.legend(loc='best')

        plt.xlabel("z")
        plt.ylabel("P(z)")
        plt.savefig(savename,bbox_inches='tight')
    else:
        plt.clf()
        ax=plt.subplot(1,1,1)
        plt.setp(ax.get_xticklabels(),  visible=True)
        for bin1 in range(len(nz_source)):
            plt.xlim(0,2.0)
            plt.plot(z_source,nz_source[bin1],label='source '+str(bin1+1))
            plt.legend(loc='best')

        plt.xlabel("z")
        plt.ylabel("P(z)")
        plt.savefig(savename,bbox_inches='tight')


def plot_covariance(filename,title,savename):
    import matplotlib.pyplot as plt
    F=fits.open(filename)
    ext=F["COVMAT"]
    covariance= ext.data
    fig, ax = plt.subplots()
    im = ax.imshow(covariance)
    cbar = ax.figure.colorbar(im, ax=ax)
    plt.title(title)
    plt.savefig(savename)

def plot_correlation_mat(filename,title,savename):
    import matplotlib.pyplot as plt
    F=fits.open(filename)
    ext=F["COVMAT"]
    cov= ext.data
    corr=np.zeros((len(cov),len(cov)))
    for i in range(len(cov)):
        for j in range(len(cov)):
            corr[i,j]=cov[i,j]/np.sqrt(cov[i,i]*cov[j,j])
    fig, ax = plt.subplots()
    im = ax.imshow(corr)
    cbar = ax.figure.colorbar(im, ax=ax)
    plt.title(title)
    plt.savefig(savename)

def plot_data(filename,title,extname,savename):
    import matplotlib.pyplot as plt
    F=fits.open(filename)
    ext=F[extname]
    data=ext.data['VALUE']
    x_index = ext.data['ANGBIN']
    x_val   = ext.data['ANG']
    plt.clf()
    plt.title(title)
    plt.plot(data,'x')
    plt.savefig(savename)


def printTwoPointHDU(name, ind=1):
    """
    Print the content of a given HDU of a twopoint file
    """
    hdr  = fits.getheader(name, ind)
    data = fits.getdata(name, ind)
    
    print()
    print(hdr.tostring(sep='\n'))
    print(data)
    return

def printTwoPoint_fromFile(name):
    """
    Print the summary info of a twopoint file
    """
    HDUList = fits.open(name)
    
    ## Check default HDU
    print()
    print('Check default HDU:')
    
    if 'SIMPLE' in HDUList[0].header:
        HDUList = HDUList[1:]
        print('  Passed.')
    else:
        print('  No default HDU.')
        print('  Means that this file was not generated in the standard way.')
        print('  Will continue.')
    
    hdrList  = [HDU.header for HDU in HDUList]
    dataList = [HDU.data for HDU in HDUList]
    
    print()
    wtp2._checkExtensions_fromFile(hdrList)
    print()
    wtp2._checkCovariance_fromFile(hdrList)
    print()
    wtp2._checkSpectra_fromFile(hdrList)
    print()
    wtp2._checkKernels_fromFile(hdrList, dataList)
    print()
    wtp2._checkNGal_fromFile(hdrList)
    return 

def printTwoPoint(TP, mean=True, cov=True, nOfZ=True):
    """
    Print the summary info of a twopoint object
    Useful when you want to see what is really stocked in the python object
    """
    if mean:
        print()
        print('Spectra:')
        for spectrum in TP.spectra:
            print()
            wtp2._printSpectrum(spectrum)
    
    if cov:
        print()
        print('Covariance:')
        if hasattr(TP, 'covmat_info') and TP.covmat_info is not None:
            print()
            wtp2._printCovMatInfo(TP.covmat_info)
            print('Direct cov.shape = %s' % str(TP.covmat.shape))
        else:
            print()
            print('Did not find `covmat_info` attribute')
    
    if nOfZ:
        print()
        print('Kernels:')
        for kernel in TP.kernels:
            print()
            wtp2._printKernel(kernel)
    
    ##print(TP.windows)
    ##print(TP._spectrum_index)
    return

def printTwoPoint_fromObj(name, mean=True, cov=True, nOfZ=True):
    """
    Print the summary info of a twopoint file by reading it first as an object
    """
    try:
        TP = wtp.TwoPointWrapper.from_fits(name, covmat_name='COVMAT')
    except:
        TP = wtp.TwoPointWrapper.from_fits(name, covmat_name=None)
    printTwoPoint(TP, mean=mean, cov=cov, nOfZ=nOfZ)
    return

def unitaryTest(name1, name2):
    """
    Check if two files are strictly identical
    """
    wtp2.unitaryTest(name1, name2)
    return

#}}}

##################################################################################
### Making fits files for Phase-1 real data

parser = ArgumentParser(description='Construct a cosmosis mcmc input file')
parser.add_argument("--datavector", dest="DataVector",nargs=2,
    help="Full Input file names", metavar="DataVector",required=True)
parser.add_argument("-s", "--statistic", dest="statistic", type=str, required=True, choices = ['cosebis','cosebis_dimless','bandpowers','xipm','xiEB'],
    help="2pt statistic, must be either cosebis, bandpowers, or xipm")
parser.add_argument("--nz", dest="NzList",nargs='+',type=str,
    help="list of Nz per tomographic bin",required=True)
parser.add_argument("--ntomo", dest="nTomo",type=int,
    help="Number of tomographic bins",required=True)
parser.add_argument("--nmaxcosebis", dest="nmaxcosebis",type=int,
    help="maximum n for cosebis")
parser.add_argument("--nbandpowers", dest="nbandpowers",type=int,
    help="number of bandpower bins")
parser.add_argument("--nxipm", dest="nxipm",type=int,
    help="number of xipm bins")
parser.add_argument("--ellmin", dest="ellmin",type=float,
    help="bandpower ell_min")
parser.add_argument("--ellmax", dest="ellmax",type=float,
    help="bandpower ell_max")
parser.add_argument("--thetamin", dest="thetamin",type=float,
    help="xipm theta_min")
parser.add_argument("--thetamax", dest="thetamax",type=float,
    help="xipm theta_max")
parser.add_argument("--neff", dest="NeffFile",nargs='+',
    help="Neff values file",required=True)
parser.add_argument("--sigmae", dest="SigmaeFile",nargs='+',
    help="sigmae values file",required=True)
parser.add_argument("--covariance", dest="covarianceFile",nargs=1,
    help="Covariance file",required=True)
parser.add_argument("-o", "--outputfile", dest="outputFile",
    help="Full Output file name", metavar="outputFile",required=True)
parser.add_argument("-p", "--plotdir", dest="plotdir",
    help="Path for output figures", metavar="plotdir",required=True)

args = parser.parse_args()
statistic = args.statistic
plotdir = args.plotdir
outputfile=args.outputFile

if statistic == 'cosebis_dimless': 
    statistic='cosebis'

# Folder and file names for nofZ, for the sources it will depend on the blind

nzlist=args.NzList

#Check that provided files have compatible dimensions: len(datavec)==len(cov) 
# if not len(args.DataVector_cosebis) == len(args.covarianceFile_cosebis): 
#     raise ValueError('Number of data vectors must be the same as the number of covariances! %s != %s' % 
#             (str(len(args.DataVector_cosebis)),str(len(args.covarianceFile_cosebis))))

nBins_source = len(nzlist)
nz={}
for bin in range(nBins_source):
    nz['source'+str(bin+1)] = nzlist[bin]

# number density of galaxies per arcmin^2
# Sources:
# read from file
#filename = args.NeffFile
#nGal_source = np.loadtxt(filename,comments="#")
nGal_source=[]
for tempval in args.NeffFile:
    if os.path.isfile(tempval):
        data=np.loadtxt(tempval,comments='#')
        if data.ndim == 0:
            data=np.array([data])
        for val in data: 
            nGal_source.append(val)
    else:
        try:
            nGal_source.append(float(tempval))
        except:
            raise ValueError(f"provided neff {tempval} is neither a valid file nor a float?!")

# read from file
#filename = args.SigmaeFile
#sigma_e  = np.loadtxt(filename,comments="#")
sigma_e=[]
for tempval in args.SigmaeFile:
    if os.path.isfile(tempval):
        data=np.loadtxt(tempval,comments='#')
        if data.ndim == 0:
            data=np.array([data])
        for val in data: 
            sigma_e.append(val)
    else:
        try:
            sigma_e.append(float(tempval))
        except:
            raise ValueError(f"provided sigmae {tempval} is neither a valid file nor a float?!")
# Fits files
if statistic == 'cosebis':
    saveFitsCOSEBIs(datavec=args.DataVector[0],covariance=args.covarianceFile[0],outputFilename=outputfile+'.fits')
    saveFitsCOSEBIs(datavec=args.DataVector[1],covariance=args.covarianceFile[0],outputFilename=outputfile+'_no_m_bias.fits')
elif statistic == 'bandpowers':
    saveFitsBP(datavec=args.DataVector[0],covariance=args.covarianceFile[0],outputFilename=outputfile+'.fits')
    saveFitsBP(datavec=args.DataVector[1],covariance=args.covarianceFile[0],outputFilename=outputfile+'_no_m_bias.fits') 
elif statistic =='xipm':
    saveFitsXipm(datavec=args.DataVector[0],covariance=args.covarianceFile[0],outputFilename=outputfile+'.fits')
    saveFitsXipm(datavec=args.DataVector[1],covariance=args.covarianceFile[0],outputFilename=outputfile+'_no_m_bias.fits')
elif statistic =='xiEB':
    saveFitsXipm(datavec=args.DataVector[0],covariance=args.covarianceFile[0],outputFilename=outputfile+'.fits')
    saveFitsXipm(datavec=args.DataVector[1],covariance=args.covarianceFile[0],outputFilename=outputfile+'_no_m_bias.fits')

else:
    raise Exception('Unknown statistic!')

# Plots
title='KiDS-Legacy'
savename=plotdir+'/only_source_Nz.pdf'
plot_redshift(outputfile+'.fits',title,savename)

title=statistic
savename=plotdir+'/'+statistic+'_covariance.pdf'
plot_covariance(outputfile+'.fits',title,savename)

savename=plotdir+'/'+statistic+'_correlation_matrix.pdf'
plot_correlation_mat(outputfile+'.fits',title,savename)

if statistic == 'cosebis': 
    extname='En'
    savename=plotdir+'/'+statistic+'_data_'+extname+'.pdf'
    plot_data(outputfile+'.fits',title,extname,savename)
    extname='Bn'
    savename=plotdir+'/'+statistic+'_data_'+extname+'.pdf'
    plot_data(outputfile+'.fits',title,extname,savename)
elif statistic == 'bandpowers': 
    extname='PeeE'
    savename=plotdir+'/'+statistic+'_data_'+extname+'.pdf'
    plot_data(outputfile+'.fits',title,extname,savename)
    extname='PeeB'
    savename=plotdir+'/'+statistic+'_data_'+extname+'.pdf'
    plot_data(outputfile+'.fits',title,extname,savename)
elif statistic == 'xipm': 
    extname='xiP'
    savename=plotdir+'/'+statistic+'_data_'+extname+'.pdf'
    plot_data(outputfile+'.fits',title,extname,savename)
    extname='xiM'
    savename=plotdir+'/'+statistic+'_data_'+extname+'.pdf'
    plot_data(outputfile+'.fits',title,extname,savename)



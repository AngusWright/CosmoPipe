
    ######################################
    ##  save_and_check_Phase1.py        ##
    ##  Marika Asgari                   ##
    ##  Version 2020.04.21              ##
    ######################################

# This is based on Linc's save_and_check_twopoint. 
# It has been adapted to make .fits files for the Phase1 real data

import sys

import collections as clt
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

def none_or_str(value):
    if value == 'None':
        return None
    return value

###############################################################################
## Main functions
#{{{

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
        
    try:
        ext=F["nz_obs"]
        z_obs, nz_obs, n_bar_obs=load_histogram_form(ext)
        plot_smf=True
    except:
        print("no smfs given")
        plot_smf=False

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
    elif(plot_smf):
        plt.clf()
        ax=plt.subplot(2,1,1)
        plt.ylabel("P(z)")
        plt.title(title)
        plt.setp(ax.get_xticklabels(),  visible=False)
        plt.subplots_adjust(wspace=0,hspace=0)
        for bin1 in range(len(nz_obs)):
            plt.xlim(0,2.0)
            plt.plot(z_obs,nz_obs[bin1],label='obs '+str(bin1+1))
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
    elif(plot_lenses and plot_smf):
        plt.clf()
        ax=plt.subplot(3,1,1)
        plt.ylabel("P(z)")
        plt.title(title)
        plt.setp(ax.get_xticklabels(),  visible=False)
        plt.subplots_adjust(wspace=0,hspace=0)
        for bin1 in range(len(nz_obs)):
            plt.xlim(0,2.0)
            plt.plot(z_obs,nz_obs[bin1],label='obs '+str(bin1+1))
            plt.legend(loc='best')
            
        plt.setp(ax.get_xticklabels(),  visible=False)
    
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
    im = ax.imshow(covariance, interpolation='nearest')
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
    im = ax.imshow(corr, interpolation='nearest')
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
    
def plot_data_1pt(filename,title,extname,savename):
    import matplotlib.pyplot as plt
    F=fits.open(filename)
    ext=F[extname]
    #print(ext.columns)
    plt.clf()
    plt.title(title)
    for i in range(1, 99999):
        try:
            data = ext.data['VALUE{}'.format(i)]
            x_val = ext.data['ANG{}'.format(i)]
            #print(x_val, data)
            plt.plot(x_val,data)
        except:
            break
    plt.yscale('log')
    plt.xscale('log')
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
    
def read_value_or_file(input):
    values = []
    for tempval in input:
        if os.path.isfile(tempval):
            data=np.loadtxt(tempval,comments='#')
            if data.ndim == 0:
                data=np.array([data])
            for val in data:
                values.append(val)
        else:
            try:
                values.append(float(tempval))
            except:
                raise ValueError(f"provided input {tempval} is neither a valid file nor a float?!")
    return values

#}}}

##################################################################################
### Making fits files for Phase-1 real data

parser = ArgumentParser(description='Construct a cosmosis mcmc input file')
parser.add_argument("--datavector_ee", dest="datavector_ee",nargs='*',
    help="Full Input file names", metavar="datavector_ee",required=True, default=None, const=None)
parser.add_argument("--datavector_ne", dest="datavector_ne",nargs='*',
    help="Full Input file names", metavar="datavector_ne",required=True, default=None, const=None)
parser.add_argument("--datavector_nn", dest="datavector_nn",nargs='*',
    help="Full Input file names", metavar="datavector_nn",required=True, default=None, const=None)
parser.add_argument("--smfdatavector", dest="smfvec",nargs='*',
    help="SMF input file name", metavar="smfvec",required=False, default=None, const=None)
parser.add_argument("-s", "--statistic", dest="statistic", type=str, required=True, choices = ['cosebis','cosebis_dimless','bandpowers','2pcf','2pcfEB'],
    help="2pt statistic, must be either cosebis, bandpowers, or xipm")
parser.add_argument("--mode", dest="mode",nargs='+',type=str,
    help="list modes to calculate statistis for (EE, NE, NN or OBS)",required=True, default=['EE'])
    
parser.add_argument("--nzsource", dest="nzlist_source",nargs='*',type=str,
    help="list of Nz per tomographic bin",required=False, default=None, const=None)
parser.add_argument("--nzlens", dest="nzlist_lens",nargs='*',type=str,
    help="list of Nz per tomographic bin",required=False, default=None, const=None)
parser.add_argument("--nzobs", dest="nzlist_obs",nargs='*',type=str,
    help="list of Nz per tomographic bin",required=False, default=None, const=None)
    
parser.add_argument("--ntomo", dest="nTomo",type=int,
    help="Number of tomographic bins",required=False, default=0)
parser.add_argument("--nlens", dest="nLens",type=int,
    help="Number of lens bins",required=False, default=0)
parser.add_argument("--nobs", dest="nObs",type=int,
    help="Number of SMF bins",required=False, default=0)
    
parser.add_argument("--nmaxcosebis_ee", dest="nmaxcosebis_ee",type=int,
    help="maximum n for cosebis",required=False, default=5)
parser.add_argument("--nbandpowers_ee", dest="nbandpowers_ee",type=int,
    help="number of bandpower bins",required=False, default=8)
parser.add_argument("--ellmin_ee", dest="ellmin_ee",type=float,
    help="bandpower ell_min",required=False, default=100)
parser.add_argument("--ellmax_ee", dest="ellmax_ee",type=float,
    help="bandpower ell_max",required=False, default=1500)
    
parser.add_argument("--nmaxcosebis_ne", dest="nmaxcosebis_ne",type=int,
    help="maximum n for cosebis",required=False, default=5)
parser.add_argument("--nbandpowers_ne", dest="nbandpowers_ne",type=int,
    help="number of bandpower bins",required=False, default=8)
parser.add_argument("--ellmin_ne", dest="ellmin_ne",type=float,
    help="bandpower ell_min",required=False, default=100)
parser.add_argument("--ellmax_ne", dest="ellmax_ne",type=float,
    help="bandpower ell_max",required=False, default=1500)
    
parser.add_argument("--nmaxcosebis_nn", dest="nmaxcosebis_nn",type=int,
    help="maximum n for cosebis",required=False, default=5)
parser.add_argument("--nbandpowers_nn", dest="nbandpowers_nn",type=int,
    help="number of bandpower bins",required=False, default=8)
parser.add_argument("--ellmin_nn", dest="ellmin_nn",type=float,
    help="bandpower ell_min",required=False, default=100)
parser.add_argument("--ellmax_nn", dest="ellmax_nn",type=float,
    help="bandpower ell_max",required=False, default=1500)
    
parser.add_argument("--thetamin_ee", dest="thetamin_ee",type=float,
    help="xipm theta_min",required=False, default=0.5)
parser.add_argument("--thetamax_ee", dest="thetamax_ee",type=float,
    help="xipm theta_max",required=False, default=300)
parser.add_argument("--ntheta_ee", dest="ntheta_ee",type=int,
    help="number of xipm bins",required=False, default=9)
    
parser.add_argument("--thetamin_ne", dest="thetamin_ne",type=float,
    help="gt theta_min",required=False, default=0.5)
parser.add_argument("--thetamax_ne", dest="thetamax_ne",type=float,
    help="gt theta_max",required=False, default=300)
parser.add_argument("--ntheta_ne", dest="ntheta_ne",type=int,
    help="number of gt bins",required=False, default=9)
    
parser.add_argument("--thetamin_nn", dest="thetamin_nn",type=float,
    help="wt theta_min",required=False, default=0.5)
parser.add_argument("--thetamax_nn", dest="thetamax_nn",type=float,
    help="wt theta_max",required=False, default=300)
parser.add_argument("--ntheta_nn", dest="ntheta_nn",type=int,
    help="number of wt bins",required=False, default=9)
    
parser.add_argument("--neff_source", dest="NeffFileSource",nargs='*',
    help="Neff values file for sources",required=False, default=None, const=None)
parser.add_argument("--neff_lens", dest="NeffFileLens",nargs='*',
    help="Neff values file for lenses",required=False, default=None, const=None)
parser.add_argument("--neff_obs", dest="NeffFileObs",nargs='*',
    help="Neff values file for SMF",required=False, default=None, const=None)
parser.add_argument("--sigmae", dest="SigmaeFile",nargs='*',
    help="sigmae values file",required=False, default=None)
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
    
if statistic == '2pcfEB':
    statistic='2pcf'

# Folder and file names for nofZ, for the sources it will depend on the blind

nzlist_source = args.nzlist_source
nzlist_lens = args.nzlist_lens
nzlist_obs = args.nzlist_obs
ntomo = args.nTomo
nlens = args.nLens
nobs = args.nObs

#Check that provided files have compatible dimensions: len(datavec)==len(cov)
# if not len(args.DataVector_cosebis) == len(args.covarianceFile_cosebis): 
#     raise ValueError('Number of data vectors must be the same as the number of covariances! %s != %s' % 
#             (str(len(args.DataVector_cosebis)),str(len(args.covarianceFile_cosebis))))

stats_string = ''
#nz={}
nz=clt.OrderedDict()

if 'NE' in args.mode or 'NN' in args.mode:
    if nlens > 0:
        nBins_lens = nlens
        for bin in range(nBins_lens):
            nz['lens'+str(bin+1)] = nzlist_lens[bin]
        
        if args.NeffFileLens is not None:
            nGal_lens = read_value_or_file(args.NeffFileLens)
        else:
            nGal_lens = list(np.zeros(nlens))
    else:
        raise ValueError('At least one lens bin expected!')
else:
    nBins_lens = 0
    nGal_lens = []

if 'EE' in args.mode or 'NE' in args.mode:
    if ntomo > 0:
        nBins_source = ntomo
        for bin in range(nBins_source):
            nz['source'+str(bin+1)] = nzlist_source[bin]
        
        if args.NeffFileSource is not None:
            nGal_source = read_value_or_file(args.NeffFileSource)
        else:
            nGals_source = list(np.zeros(ntomo))
        sigmaEpsList = read_value_or_file(args.SigmaeFile)
    else:
        raise ValueError('At least one source bin expected!')
else:
    nBins_source = 0
    nGal_source = []
    sigmaEpsList = None

if 'OBS' in args.mode:
    if nobs > 0:
        nBins_obs = nobs
        for bin in range(nBins_obs):
            nz['obs'+str(bin+1)] = nzlist_obs[bin]

        if args.NeffFileLens is not None:
            nGal_obs = read_value_or_file(args.NeffFileObs)
        else:
            nGal_obs = list(np.zeros(nobs))
    else:
        raise ValueError('At least one SMF bin expected!')
else:
    nBins_obs = 0
    nGal_obs = []
    
nGalList = nGal_lens + nGal_source + nGal_obs

if len(args.datavector_ee) == 2:
    datavec_ee = list(np.genfromtxt(args.datavector_ee[0]))
    datavec_ee_no_mbias = list(np.genfromtxt(args.datavector_ee[1]))
    no_m_bias_ee = True
elif len(args.datavector_ee) == 1:
    datavec_ee = list(np.genfromtxt(args.datavector_ee[0]))
    datavec_ee_no_mbias = []
    no_m_bias_ee = False
else:
    datavec_ee = []
    datavec_ee_no_mbias = []
    no_m_bias_ee = False
    
if len(args.datavector_ne) == 2:
    datavec_ne = list(np.genfromtxt(args.datavector_ne[0]))
    datavec_ne_no_mbias = list(np.genfromtxt(args.datavector_ne[1]))
    no_m_bias_ne = True
elif len(args.datavector_ne) == 1:
    datavec_ne = list(np.genfromtxt(args.datavector_ne[0]))
    datavec_ne_no_mbias = []
    no_m_bias_ne = False
else:
    datavec_ne = []
    datavec_ne_no_mbias = []
    no_m_bias_ne = False
    
if len(args.datavector_nn) == 2:
    datavec_nn = list(np.genfromtxt(args.datavector_nn[0]))
    datavec_nn_no_mbias = list(np.genfromtxt(args.datavector_nn[1]))
    no_m_bias_nn = True
elif len(args.datavector_nn) == 1:
    datavec_nn = list(np.genfromtxt(args.datavector_nn[0]))
    datavec_nn_no_mbias = []
    no_m_bias_nn = False
else:
    datavec_nn = []
    datavec_nn_no_mbias = []
    no_m_bias_nn = False
    
if len(args.smfvec) >= 1:
    smfvec = args.smfvec
    smftag = 'file'
else:
    smfvec=[]
    smftag=None
    
covariance = args.covarianceFile[0]
outputFilename = outputfile+'.fits'
outputFilename_no_mbias = outputfile+'_no_m_bias.fits'

# This probably needs to be a list in the first place to preserve order!
nOfZNameList = list(nz.values())

datavec = []
datavec_no_mbias = []
# Fits files
if statistic == 'cosebis':
    if 'NN' in args.mode:
        stats_string = stats_string + 'Psi_gg '
        datavec.extend(datavec_nn)
        datavec_no_mbias.extend(datavec_nn_no_mbias)
    if 'NE' in args.mode:
        stats_string = stats_string + 'Psi_gm '
        datavec.extend(datavec_ne)
        datavec_no_mbias.extend(datavec_ne_no_mbias)
    if 'EE' in args.mode:
        stats_string = stats_string + 'En Bn '
        datavec.extend(datavec_ee)
        datavec_no_mbias.extend(datavec_ee_no_mbias)
    if 'OBS' in args.mode:
        stats_string = stats_string + '1pt '
    scDict = {
        'use_stats': stats_string.lower()
        }
elif statistic == 'bandpowers':
    if 'NN' in args.mode:
        stats_string = stats_string + 'Pnn '
        datavec.extend(datavec_nn)
        datavec_no_mbias.extend(datavec_nn_no_mbias)
    if 'NE' in args.mode:
        #stats_string = stats_string + 'PneE PneB '
        stats_string = stats_string + 'PneE '
        datavec.extend(datavec_ne)
        datavec_no_mbias.extend(datavec_ne_no_mbias)
    if 'EE' in args.mode:
        stats_string = stats_string + 'PeeE PeeB '
        datavec.extend(datavec_ee)
        datavec_no_mbias.extend(datavec_ee_no_mbias)
    if 'OBS' in args.mode:
        stats_string = stats_string + '1pt '
    scDict = {
        'use_stats': stats_string.lower()
        }
elif statistic =='2pcf':
    if 'NN' in args.mode:
        stats_string = stats_string + 'wtheta '
        datavec.extend(datavec_nn)
        datavec_no_mbias.extend(datavec_nn_no_mbias)
    if 'NE' in args.mode:
        #stats_string = stats_string + 'gammat gammax '
        stats_string = stats_string + 'gammat '
        datavec.extend(datavec_ne)
        datavec_no_mbias.extend(datavec_ne_no_mbias)
    if 'EE' in args.mode:
        stats_string = stats_string + 'xip xim '
        datavec.extend(datavec_ee)
        datavec_no_mbias.extend(datavec_ee_no_mbias)
    if 'OBS' in args.mode:
        stats_string = stats_string + '1pt '
    scDict = {
        'use_stats': stats_string.lower()
        }
else:
    raise Exception('Unknown statistic!')
    

wtp2.saveFitsTwoPoint(
        nbTomoN=nBins_lens,
        nbTomoG=nBins_source,
        nbObs=nBins_obs,
        N_theta_ee=args.ntheta_ee,
        theta_min_ee=args.thetamin_ee,
        theta_max_ee=args.thetamax_ee,
        N_ell_ee=args.nbandpowers_ee,
        ell_min_ee=args.ellmin_ee,
        ell_max_ee=args.ellmax_ee,
        nbModes_ee=args.nmaxcosebis_ee,
        N_theta_ne=args.ntheta_ne,
        theta_min_ne=args.thetamin_ne,
        theta_max_ne=args.thetamax_ne,
        N_ell_ne=args.nbandpowers_ne,
        ell_min_ne=args.ellmin_ne,
        ell_max_ne=args.ellmax_ne,
        nbModes_ne=args.nmaxcosebis_ne,
        N_theta_nn=args.ntheta_nn,
        theta_min_nn=args.thetamin_nn,
        theta_max_nn=args.thetamax_nn,
        N_ell_nn=args.nbandpowers_nn,
        ell_min_nn=args.ellmin_nn,
        ell_max_nn=args.ellmax_nn,
        nbModes_nn=args.nmaxcosebis_nn,
        nnAuto=True,
        smbinAuto=True,
        prefix_Flinc=None,
        prefix_CosmoSIS=None,
        scDict=scDict,
        meanTag='variable',
        meanName=np.array(datavec),
        covTag='onecov',
        covName=covariance,
        nobsTag=smftag,
        nobsName=smfvec,
        nOfZNameList=nOfZNameList,
        nGalList=nGalList,
        sigmaEpsList=sigmaEpsList,
        saveName=outputFilename
)

if no_m_bias_ee == True and no_m_bias_ne == True and no_m_bias_nn == True:
    wtp2.saveFitsTwoPoint(
        nbTomoN=nBins_lens,
        nbTomoG=nBins_source,
        nbObs=nBins_obs,
        N_theta_ee=args.ntheta_ee,
        theta_min_ee=args.thetamin_ee,
        theta_max_ee=args.thetamax_ee,
        N_ell_ee=args.nbandpowers_ee,
        ell_min_ee=args.ellmin_ee,
        ell_max_ee=args.ellmax_ee,
        nbModes_ee=args.nmaxcosebis_ee,
        N_theta_ne=args.ntheta_ne,
        theta_min_ne=args.thetamin_ne,
        theta_max_ne=args.thetamax_ne,
        N_ell_ne=args.nbandpowers_ne,
        ell_min_ne=args.ellmin_ne,
        ell_max_ne=args.ellmax_ne,
        nbModes_ne=args.nmaxcosebis_ne,
        N_theta_nn=args.ntheta_nn,
        theta_min_nn=args.thetamin_nn,
        theta_max_nn=args.thetamax_nn,
        N_ell_nn=args.nbandpowers_nn,
        ell_min_nn=args.ellmin_nn,
        ell_max_nn=args.ellmax_nn,
        nbModes_nn=args.nmaxcosebis_nn,
        nnAuto=True,
        smbinAuto=True,
        prefix_Flinc=None,
        prefix_CosmoSIS=None,
        scDict=scDict,
        meanTag='variable',
        meanName=np.array(datavec_no_mbias),
        covTag='onecov',
        covName=covariance,
        nobsTag=smftag,
        nobsName=smfvec,
        nOfZNameList=nOfZNameList,
        nGalList=nGalList,
        sigmaEpsList=sigmaEpsList,
        saveName=outputFilename_no_mbias
    )
    
statsList = stats_string.split()

# Plots
title='KiDS-Legacy'
savename=plotdir+'/only_source_Nz.pdf'
#plot_redshift(outputfile+'.fits',title,savename)

title=statistic
savename=plotdir+'/'+statistic+'_covariance.pdf'
plot_covariance(outputfile+'.fits',title,savename)

savename=plotdir+'/'+statistic+'_correlation_matrix.pdf'
plot_correlation_mat(outputfile+'.fits',title,savename)

for extname in statsList:
    savename=plotdir+'/'+statistic+'_data_'+extname+'.pdf'
    if extname != '1pt':
        plot_data(outputfile+'.fits',title,extname,savename)
    else:
        plot_data_1pt(outputfile+'.fits',title,extname,savename)


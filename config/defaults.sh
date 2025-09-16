##
# 
# KiDS COSMOLOGY PIPELINE Default Configuration Variables 
# Written by A.H. Wright (2019-09-30) 
#
##

# Defaults for runtime variables 

#Survey Identifier 
SURVEY=KiDS
#Patch identification labels 
PATCHLIST="N S"
#Folder containing wide-field shear catalogues 
PATCHPATH=/path/to/patches/           

#Spec-z calibration catalogue 
SPECZCAT=/path/to/SpeczCalibration.cat

#List of magnitudes for use in Nz calibration (Default is KiDS-Legacy)
MAGLIST="MAG_GAAP_u MAG_GAAP_g MAG_GAAP_r MAG_GAAP_i1 MAG_GAAP_i2 MAG_GAAP_Z MAG_GAAP_Y MAG_GAAP_J MAG_GAAP_H MAG_GAAP_Ks"

#Reference magnitude for use in calibration (Default is KiDS-Legacy)
REFMAGNAME="MAG_AUTO"

#Form of the SOM calibration feature space ({ALLMAG,MAG,ALLCOLOUR,COLOUR})
FEATURETYPES="ALLCOLOUR+MAG"

#Blind Character (Default is KiDS-1000) 
BLIND=C                 

#Shape measurement variables: e1 (Default is KiDS-Legacy)
E1NAME=autocal_e1_@BV:BLIND@
#Shape measurement variables: e2 (Default is KiDS-Legacy) 
E2NAME=autocal_e2_@BV:BLIND@

#Uncorrected shape measurement variables: e1 (Default is KiDS-Legacy)
RAWE1NAME=raw_e1
#Uncorrected shape measurement variables: e2 (Default is KiDS-Legacy)
RAWE2NAME=raw_e1

#PSF Shape measurement variables: e1 (Default is KiDS-Legacy)
PSFE1NAME=PSF_e1
#PSF Shape measurement variables: e2 (Default is KiDS-Legacy)
PSFE2NAME=PSF_e2

#RADec names: RA (Default is KiDS-Legacy)
RANAME=ALPHA_J2000
#RADec names: Declination  (Default is KiDS-Legacy)
DECNAME=DELTA_J2000

#Radius for on-sky matching (arcsec)
RADIUS=1

#Number of bootstrap realisations when required 
NBOOT=300

#Specz column name (Default is KiDS-Legacy)
ZSPECNAME='z_spec'

#Photo-z column name (Default is KiDS-Legacy)
ZPHOTNAME='Z_B'

#Number of threads
NTHREADS=180

#Nz delta-z stepsize (Default is KiDS-Legacy)
NZSTEP=0.05

#Nz delta-z stepsize for lenses (Default is KiDS-Legacy)
NZSTEP_LENS=0.01

#Number of spatial splits  (Default is SKILLS)
NSPLIT=5
#Number of spatial splits to retain (Default is SKILLS)
NSPLITKEEP=5

#Do we want to always save TPDs in the chain file (makes files much larger)
SAVE_TPDS=False
#Do we want to split the datavector in any way? 
SPLITMODE=

#List of m-bias values (Default is KiDS-1000 Asgari+ 2021) 
MBIASVALUES="-0.009  -0.011  -0.015  +0.002  +0.007"      #KiDS-1000 
#MBIASVALUES="-0.013 -0.018 -0.008 0.019 0.034"            #SSL K1000  
#List of m-bias uncertainties (Default is KiDS-1000 Asgari+ 2021)
MBIASERRORS="0.019 0.020 0.017 0.012 0.010"               #KiDS-1000
#MBIASERRORS="0.017 0.007 0.007 0.006 0.006"            #SSL K1000  
#Use an Analytic m-bias covariance?
ANALYTIC_MCOV=TRUE
#m-bias correlation  
MBIASCORR=0.99

#List of sigmae values (Default is KiDS-1000 Asgari+ 2021)
SIGMAELIST="0.270 0.258 0.273 0.254 0.270"                      #KiDS-1000

#Limits of the tomographic bins (Default is KiDS-Legacy)
#TOMOLIMS='0.1 0.3 0.5 0.7 0.9 1.2'                        #KiDS-1000
#Limits of the tomographic bins (Default is KiDS-Legacy)
TOMOLIMS='0.10 0.42 0.58 0.71 0.90 1.14 2.00'                        #KiDS-Legacy

#Variable used to define tomographic bins (Default is KiDS-Legacy)
TOMOVAR=Z_B

#lower theta limit for xipm (arcmin; Default is KiDS-Legacy)
THETAMINXI="2.0"
#upper theta limit for xipm (arcmin; Default is KiDS-Legacy)
THETAMAXXI="300.0"
#Number of Theta bins for xipm (can be highres for BP/COSEBIs; default is KiDS-Legacy)
NTHETABINXI="1000"
#Number of Xipm bins used for science (Default is KiDS-Legacy)
NXIPM=9 
#Maximum Theta for analysing Xim (arcmin; )
THETAMAXXIM=300
#Minimum Theta for analysing Xim (arcmin) 
THETAMINXIM=4

#Minimum Number of modes for COSEBIs (Default is KiDS-Legacy)
NMINCOSEBIS=1
#Maximum Number of modes for COSEBIs (Default is KiDS-Legacy)
NMAXCOSEBIS=20


#lower theta limit for gamma_t (arcmin; Default is KiDS-Legacy)
THETAMINGT="2.0"
#upper theta limit for gamma_t (arcmin; Default is KiDS-Legacy)
THETAMAXGT="300.0"
#Number of Theta bins for gamma_t (can be highres for BP/COSEBIs; default is KiDS-Legacy)
NTHETABINGT="1000"
#Number of gamma_t bins used for science (Default is KiDS-Legacy)
NGT=9 

#Minimum Number of modes for Psi_gm (Default is KiDS-Legacy)
NMINCOSEBISNE=1
#Maximum Number of modes for Psi_gm (Default is KiDS-Legacy)
NMAXCOSEBISNE=20


#lower theta limit for w(theta) (arcmin; Default is KiDS-Legacy)
THETAMINWT="2.0"
#upper theta limit for w(theta) (arcmin; Default is KiDS-Legacy)
THETAMAXWT="300.0"
#Number of Theta bins for w(theta) (can be highres for BP/COSEBIs; default is KiDS-Legacy)
NTHETABINWT="1000"
#Number of w(theta) bins used for science (Default is KiDS-Legacy)
NWT=9 

#Minimum Number of modes for Psi_gg (Default is KiDS-Legacy)
NMINCOSEBISNN=1
#Maximum Number of modes for Psi_gg (Default is KiDS-Legacy)
NMAXCOSEBISNN=20


#Name of the lensing weight variable (Default is KiDS-Legacy)
WEIGHTNAME=AlphaRecalC_weight_@BV:BLIND@

#Name of the lensing weight variable (Default is KiDS-Legacy)
CALIBWEIGHTNAME=@BV:WEIGHTNAME@_wPV

#Name to base the Nz labels on 
NZNAME_BASEBLOCK=som_weight_calib_cats

#Name of the base file for cosmosis/onecov
NPAIRBASE_XI=XI_@BV:SURVEY@_NScomb        #Use the combined XIpm counts as fiducial
NPAIRBASE_GT=GT_@BV:SURVEY@_NScomb        #Use the combined XIpm counts as fiducial
NPAIRBASE_WT=WT_@BV:SURVEY@_NScomb        #Use the combined XIpm counts as fiducial

#Statistic of choice for chain (Default is KiDS-Legacy fiducial)
STATISTIC=cosebis

#Sampler (Default is KiDS-Legacy fiducial)
SAMPLER=nautilus

#Nautilus resume 
NAUTILUS_RESUME=false
#Nautilus number of samples 
NAUTILUS_NSAMP=10000

#Boltzmann Code (Default is KiDS-Legacy)
BOLTZMAN=COSMOPOWER_HM2020 

#Simulated spectroscopic calibration sample(s)
SIMSPECZCAT=/path/to/specz/simulations/

#Simulated catalogues with constant shear (Default is KiDS-Legacy)
SIMMAINCAT=/path/to/KiDSLegacy_data/skills_v07D7ten/                                #KiDS-Legacy

#Simulated catalogues with variable shear 
SIMVARCAT=/path/to/KiDSLegacy_data/skills_v07D7p1/

#Catalogue of Blended objects in Simulated catalogues
SIMBLENDCAT=/path/to/KiDSLegacy_data/skills_v07D7p1_lite_blended/

#COSEBI file base name
COSEBISBASE=@BV:COSEBISBASE@

#Patches to use in CosmoSIS calculations
COSMOSIS_PATCHLIST="NS"

#CosmoSIS pipeline specification
COSMOSIS_PIPELINE="default"

#Data Vector Length 
DVLENGTH=75 

#Ellipticity type for m-calibration ('measured' or 'true')
ETYPE='measured'

#Filtering condition 
FILTERCOND=@BV:FILTERCOND@
#Strings to match to columns when reducing catalogue size  
KEEPSTRINGS=@BV:KEEPSTRINGS@


#Input shear variable names: gamma_1
G1NAME=@BV:G1NAME@
#Input shear variable names: gamma_2 
G2NAME=@BV:G2NAME@

#Compute the Gaussian component of the covariance (True or False) 
GAUSS=True 
#Compute the non-gaussian component of the covariance (True or False) 
NONGAUSS=True
#Compute the mixterm component of the covariance (True or False) 
MIXTERM=False
MIXTERM_BASEFILE=main_all_gold_recal_cc_@BV:BLIND@
#Split Gaussian contributions in the output file (True or False; True adds considerable runtime (x2+)!) 
SPLIT_GAUSS=False
#Compute the super-sample component of the covariance (True or False) 
SSC=True
#Second statistic for calculating cross-covariances 
SECONDSTATISTIC=""

#Number of ell bins for covariance computation 
LBINSCOV=100
#Minimum of ell bins for covariance computation 
LMINCOV=2
#Maximum of ell bins for covariance computation 
LMAXCOV=10000

SECONDSTATISTIC=""

#String which determines type of bandpowers correlation function (EE,NE,NN) (shear, GGL, clustering)
MODE='EE'
#Number of Bandpowers for EE
NBANDPOWERS=8
#Minimum of ell bins for bandpowers computation for EE
LMINBANDPOWERS=100.0
#Maximum of ell bins for bandpowers computation for EE
LMAXBANDPOWERS=1500.0

#Number of Bandpowers for NE
NBANDPOWERSNE=8
#Minimum of ell bins for bandpowers computation for NE
LMINBANDPOWERSNE=100.0
#Maximum of ell bins for bandpowers computation for NE
LMAXBANDPOWERSNE=1500.0

#Number of Bandpowers for NN
NBANDPOWERSNN=8
#Minimum of ell bins for bandpowers computation for NN
LMINBANDPOWERSNN=100.0
#Maximum of ell bins for bandpowers computation for NN
LMAXBANDPOWERSNN=1500.0

#Apodisation width for bandpowers 
APODISATIONWIDTH=0.5

#Sampler to use as basis of 'list sampler' 
LIST_INPUT_SAMPLER=nautilus

#name of the m1 column 
M1NAME=@BV:M1NAME@
#name of the m2 column 
M2NAME=@BV:M2NAME@

#m-calibration surface file 
MSURFACE=@BV:MSURFACE@

#Number of Resolution bins for m-surface construction 
NBINR=20
#Number of SNR bins for m-surface construction 
NBINSNR=20

#Existing column name to re-name: 
OLDKEY=@BV:OLDKEY@
#New column name for re-name: 
NEWKEY=@BV:NEWKEY@

#Dimensions of the SOM 
SOMDIM="101 101"
#Number of iterations in SOM construction 
NITER=1000
#Do we want to optimise the number of heirarchical clusters?
OPTIMISE=--optimise
#What is the minium number of allowed HCs
MINNHC=2000 

#Number of sources to use in match sliding redshift window 
MATCH_NIDX=1000
#Do we want to normalise (whiten) the feature space before matching?
MATCHNORMALISE=--norm
#Do we want to allow duplicates in the matching process? 
MATCHDUPLICATES=--duplicates 

#Aspect ratio to use when splitting catalogue 
SPLITASP=1

#Systematic error for Nz bias estimation 
NZSYSERROR=0.01

#PSF Shape coefficient column names: Q11
PSFQ11NAME=@BV:PSFQ11NAME@
#PSF Shape coefficient column names: Q12
PSFQ12NAME=@BV:PSFQ12NAME@
#PSF Shape coefficient column names: Q22
PSFQ22NAME=@BV:PSFQ22NAME@

#Resolution variable column name 
RNAME=R

#Label for simulation tiles 
SIMLABEL=tile_label

#Scale-length variable column name 
SCALELENGTHNAME=@BV:SCALELENGTHNAME@

#Simulation identifier label column name 
SIMLABEL=@BV:SIMLABEL@

#Path to Reference Chain for Figure Construction 
REFCHAIN=/path/to/KiDS1000_data/chain/output_multinest_C.txt

#Priors in cosmosis syntax
#Priors: Omega_m*h^2
PRIOR_OMCH2="0.051 0.11570 0.255"
#Priors: Omega_b*h^2
PRIOR_OMBH2="0.019 0.02233 0.026"
#Priors: H0
PRIOR_H0="0.64 0.68980 0.82"
#Priors: n_s
PRIOR_NS="0.84 0.96900 1.1"
#Priors: S_8
PRIOR_S8INPUT="0.5 0.77700 1.0"
#Priors: Omega_K
PRIOR_W="-1.0"
PRIOR_OMEGAK="0.0"
#Priors: w_0
PRIOR_W="-1.0"
#Priors: w_a
PRIOR_WA="0.0"
#Priors: m_nu
PRIOR_MNU="0.06"
#Priors: log(T_AGN)
PRIOR_LOGTAGN="7.3 8.0 8.3"
#Priors: Baryon feedback Amplitude A (HM2015)
PRIOR_ABARY="2.0 2.6 3.13"

#IA model choice: can be linear, linear_z, massdep or tatt
IAMODEL=massdep
#Linear IA model: Amplitude 
PRIOR_AIA="-6.0 1.0 6.0"
#Linear-z model: IAMODEL=linear_z
#Linear-z IA model: Amplitude 
PRIOR_A_IA="-6.0 1.0 6.0"
#Linear-z IA model: B 
PRIOR_B_IA="gaussian -3.7 4.3"
#Linear IA model: pivot scale factor 
PRIOR_A_PIV=0.769

#Massdep IA model: IAMODEL=massdep A/Beta are controlled by the ia_models parameter files in /config/ia_models 
#Massdep IA model: pivot mass 
PRIOR_LOG10_M_PIV=13.5
#Massdep IA model: mean mass bin 1
PRIOR_LOG10_M_MEAN_1="gaussian 11.732 0.073"
#Massdep IA model: mean mass bin 2
PRIOR_LOG10_M_MEAN_2="gaussian 12.495 0.066"
#Massdep IA model: mean mass bin 3
PRIOR_LOG10_M_MEAN_3="gaussian 12.798 0.063"
#Massdep IA model: mean mass bin 4
PRIOR_LOG10_M_MEAN_4="gaussian 12.964 0.060"
#Massdep IA model: mean mass bin 5
PRIOR_LOG10_M_MEAN_5="gaussian 13.089 0.058"
#Massdep IA model: mean mass bin 6
PRIOR_LOG10_M_MEAN_6="gaussian 13.242 0.055"
#Massdep IA model: red fraction bin 1
PRIOR_F_R_1=0.146
#Massdep IA model: red fraction bin 2
PRIOR_F_R_2=0.197
#Massdep IA model: red fraction bin 3
PRIOR_F_R_3=0.173
#Massdep IA model: red fraction bin 4
PRIOR_F_R_4=0.240
#Massdep IA model: red fraction bin 5
PRIOR_F_R_5=0.192
#Massdep IA model: red fraction bin 6
PRIOR_F_R_6=0.030
#massdep means
MASSDEP_MEANS=@RUNROOT@/INSTALL/ia_models/mass_dependent_ia/massdep_means.txt
#massdep covariance
MASSDEP_COVARIANCE=@RUNROOT@/INSTALL/ia_models/mass_dependent_ia/massdep_cov.txt

#Scale dependent model: IAMODEL=tatt
#scale dep IA model: pivot z 
PRIOR_Z_PIV="0.62"
#scale dep IA model: Amplitude 1 
PRIOR_A1="-5.0 1.0 5.0"
#scale dep IA model: Amplitude 2
PRIOR_A2=0.0
#scale dep IA model: Alpha 1
PRIOR_ALPHA1=0.0
#scale dep IA model: Alpha 2
PRIOR_ALPHA2=0.0
#scale dep IA model: Bias 
PRIOR_BIAS_TA="-0.5 0.0 1.5"

#Magnitude limits for the wide field sample (effective after weighting)
MAGLIMITS="20 23.5"
#Magnitude threshold for for the definition of the field sample (hard-cut before weighting)
MAGTHRESH="20 25.5"

#Filter for defining the magnitude limits for the wide field sample (effective after weighting)
MAGLIMIT_FILTER="r"

#Input Values for the Nz bias in each tomographic bin (SHOULD BE dz = EST - TRUTH)
#NZBIAS="0.000 +0.002 +0.013 +0.011 -0.006"               #KiDS-1000
#NZBIAS="0.000 +0.002 +0.013 +0.011 -0.006"               #SSL KiDS-1000
NZBIAS="-0.0258348876411008 0.0134629476830202 -0.00130607068876168 0.00825655331002634 -0.0112282260145437 -0.0541954439985493" #KiDS-Legacy

#Input Nz covariance matrix
#NZCOVFILE=/net/home/fohlen13/stoelzner/Cat_to_Obs_K1000_P1/data/kids/nofz/SOM_cov_multiplied.asc    #KiDS-1000
NZCOVFILE=/path/to/legacy/Nz_covariance.txt

#Number of cores to use for Covariance Calculation
COVNCORES=@BV:NTHREADS@
#Number of threads to use for Covariance Calculation
COVNTHREADS=1

#Bin slop
BINSLOP=1.5
BINSLOPNN=""
BINSLOPNG=""

#Remove SNR-R-Z_B c-term during shape recalibration
SHAPECAL_CTERM=True

#Multiple to include in Bmode significance computation (Ask Benjmain)
MULT=1.0

#Decorrelated Values for the Nz bias in each tomographic bin
NZBIAS_UNCORR=

#Survey Area in arcmin for the combined patches
SURVEYAREA_NS=3.12120e+06     #KiDS-1000
#Survey Area in arcmin for the combined patches
SURVEYAREADEG_NS=867.0        #KiDS-1000

#Survey Mask File 
SURVEYMASKFILE_NS=
#Survey Area in arcmin for the combined patches
SURVEYMASKFILE_N=
#Survey Area in arcmin for the combined patches
SURVEYMASKFILE_S=


#Remove SNR-R-Z_B c-term during shape recalibration 
SHAPECAL_CTERM=True


#Filename suffix for chain 
CHAINSUFFIX=
#Number of mock data vectors to analyse (empty if not required)
NMOCKS=
#Number of iterative-covariance iterations (empty if not required)
ITERATION=
#Filename for centers of patches for jackknife covariance (empty if not required)
PATCH_CENTERFILE=

#Data point in data vector to mask out (i.e. not use)(empty if not required)
MASKDATAPOINT=

#Tomographic bin to remove in chain (empty if not required)
REMOVETOMOBIN=

#Statistics to use for summary plot construction (if available) 
SUMMARY_STATISTICS='cosebis bandpowers 2pcf'


# 3x2pt bright setting
# Input LePhare cosmology
H0_IN=1.0
OMEGAM_IN=0.3
OMEGAV_IN=0.7
  
# Some limits for SMF function
MAXMASS=12.1
MINMASS=7.0
MAXZ=0.7
MINZ=0.0

# Lens photo-z properties for stacked n(z)
STACKED_NZ="True"
ZSIGMA=0.018
ZDEPERR="True"
  
# Default lens binning in stellar mass
LENSLIMSX="9.1 9.6 9.95 10.25 10.5 10.7 11.3"
LENSLIMSY="0.0 1.0"
  
# One SMF bin
SMFLENSLIMSX="7.0 12.5"
SMFLENSLIMSY="0.0 0.7"
NSMFBINS=30

# lens catalogue (default is Bright)
LENSMAINCAT=/path/to/bright/cat.fits
LENSRANAME=RAJ2000
LENSDECNAME=DECJ2000
LENSWEIGHTNAME=None

# lens randoms (default is Bright)
RANDMAINCAT=/path/to/bright/randoms.fits
RANDRANAME=RA
RANDDECNAME=DEC
  
# 3x2pt values and priors file
VALUESINI=/path/to/3x2pt/values.ini
PRIORSINI=/path/to/3x2pt/priors.ini

# Default modes for 3x2pt + SMF
MODES="EE NE NN OBS"

# Quantities needed to create red/blue statistics for IA halo model
IA_OBSERVABLE=mstar_bestfit
IA_OBSERVABLE_LOG=False
IA_SPLIT=T_B
IA_SPLIT_VAL=3.0

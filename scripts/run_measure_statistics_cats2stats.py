import numpy as np
import os
from scipy.interpolate import interp1d
from measure_statistics import tplus, tminus, gplus, gminus, T, str2bool, h, f, rebin, psi_filter
from argparse import ArgumentParser
import treecorr

# Written by Marika Asgari (ma@roe.ac.uk), bandpowers implementation by B.Stoelzner
# Python script to return COSEBIS E and B modes and Bandpowers (EE, NE, NN) given a measured 2pt correlation function
# Note that the input correlation function needs to contain data that 
# exactly spans the required ${tmin}-${tmax} range

# example run:
# tmin=0.50
# tmax=100.00
# python run_measure_cosebis_cats2stats.py -i xi_nBins_1_Bin1_Bin1 -o nBins_1_Bin1_Bin1 --norm ./TLogsRootsAndNorms/Normalization_${tmin}-${tmax}.table -r 
# ./TLogsRootsAndNorms/Root_${tmin}-${tmax}.table -b lin --thetamin ${tmin} --thetamax ${tmax} -n 20

# Specify the input arguments
parser = ArgumentParser(description='Take input 2pcfs files and calculate 2pt statistics')
parser.add_argument("-d", "--statistic", dest="statistic", type=str, required=True, choices = ['cosebis', 'bandpowers_ee', 'bandpowers_ne', 'bandpowers_nn', 'xipm', 'psi_gg', 'psi_gm', 'gt', 'wt'],
    help="Desired 2pt statistic, must be either cosebis, bandpowers_ee, bandpowers_ne, bandpowers_nn, xipm, or psi")

# Input file, columns, theta range, and other options
parser.add_argument("-i", "--inputfile", dest="inputfile", required=True,
    help="Full Input file name", metavar="inputFile")
parser.add_argument('-t','--theta_col', dest="theta_col", type=str,nargs='?', required=True,
    help='column for theta')
parser.add_argument('-p','--xip_col', dest="xip_col", type=str,nargs='?', required=False,
    help='column for xi_plus')
parser.add_argument('-m','--xim_col', dest="xim_col", type=str, nargs='?', required=False,
    help='column for xi_minus')
parser.add_argument('-g','--gamma_t_col', dest="gamma_t_col", type=str, nargs='?', required=False,
    help='column for gamma_t')
parser.add_argument('-q','--gamma_x_col', dest="gamma_x_col", type=str, nargs='?', required=False,
    help='column for gamma_x')
parser.add_argument('-j','--w_theta_col', dest="w_theta_col", type=str, nargs='?', required=False,
    help='column for clustering correlation function')
parser.add_argument('-s','--thetamin', dest="thetamin", type=str, default=0.5, nargs='?', 
    help='value of thetamin in arcmins, default is 0.5')
parser.add_argument('-l','--thetamax', dest="thetamax", type=str, default=300.0, nargs='?', 
    help='value of thetamax, in arcmins, default is 300')
parser.add_argument('--cfoldername', dest="cfoldername", default="./2pt_results",required=False,
    help='full name and address of the folder for output files, default is 2pt_results')
parser.add_argument("-o", "--outputfile", dest="outputfile", metavar="outputFile",required=True,
    help="output file name suffix. The outputs are cfoldername/En_${outputfile}.ascii and cfoldername/Bn_${outputfile}.ascii")
parser.add_argument('-b','--binning', dest="binning", default="log",required=False,
    help='log or lin binning, default is log')
parser.add_argument('-f','--force',dest="force",nargs='?',default=False,required=False,
    help='Do not check if the bin edges match. Default is FALSE.')
parser.add_argument('--save_kernels',dest="save_kernels",nargs='?',default=False,required=False,
    help='Write kernels to disk. Default is FALSE.')

# COSEBIs options
parser.add_argument('-n','--nCOSEBIs', dest="nCOSEBIs", type=int, default=10, nargs='?', required=False,
    help='number of COSEBIs modes to produce, default is 10')
parser.add_argument('--tfoldername', dest="tfoldername", default="Tplus_minus", required=False,
    help='name and full address of the folder for Tplus Tminus files for COSEBIs, will make it if it does not exist')
parser.add_argument('--tplusfile', dest="tplusfile", default="Tplus", required=False,
    help='name of Tplus file for COSEBIs, will look for it before running the code')
parser.add_argument('--tminusfile', dest="tminusfile", default="Tminus", required=False,
    help='name of Tplus file for COSEBIs, will look for it before running the code')
parser.add_argument('-c','--norm', dest="normfile", metavar="norm",required=False,
    help='normalisation file name and address for T_plus/minus for COSEBIs')
parser.add_argument('-r','--root', dest="rootfile", metavar="root",required=False,
    help='roots file name and address for T_plus/minus for COSEBIs')
    

# Bandpowers options
parser.add_argument('-w','--logwidth', dest="logwidth", type=float,default=0.5, nargs='?', 
    help='width of apodisation window for bandpowers')
parser.add_argument('--thetamin_apod', dest="thetamin_apod", type=str, nargs='?', 
    help='value of apodisation thetamin in arcmins. By default the apodisation window will go to zero at thetamin and thetamax.')
parser.add_argument('--thetamax_apod', dest="thetamax_apod", type=str, nargs='?', 
    help='value of apodisation thetamax, in arcmins. By default the apodisation window will go to zero at thetamin and thetamax.')
parser.add_argument('-z','--ellmin', dest="ellmin", type=float,default=100, nargs='?', 
    help='value of ellmin for bandpowers')
parser.add_argument('-x','--ellmax', dest="ellmax", type=float,default=1500, nargs='?', 
    help='value of ellmax for bandpowers')
parser.add_argument('-k','--nbins_bp', dest="nbins_bp", type=int,default=8, nargs='?',
    help='number of logarithmic bandpowers bins between ellmin and ellmax to produce, default is 8')

# 2pcf options
parser.add_argument('--nbins_2pcf', dest="nbins_2pcf", type=int,default=9, nargs='?',
    help='number of xipm bins to produce, default is 9')

# psi options
parser.add_argument('--filterfoldername', dest="filterfoldername", 
    help='name and full address of the folder for the psi filters U_n or Q_n, will make it if it does not exist',
    default="psi_filters",required=False)
parser.add_argument('--ufilename', dest="ufile", help='name of U file, default is U',default="U",required=False)
parser.add_argument('--qfilename', dest="qfile", help='name of Q file, default is Q',default="Q",required=False)
parser.add_argument('--psifoldername', dest="psifoldername", 
    help='full name and address of the folder for the output files, default is psi_results',default="./psi_results")
parser.add_argument('--nPsi', dest="nModes_psi", type=int,default=10, nargs='?',
    help='number of Psi modes to produce, default is 10')


args = parser.parse_args()
# Mode
mode=args.statistic 
# General options
inputfile=args.inputfile
theta_col=args.theta_col
xip_col=args.xip_col
xim_col=args.xim_col
gamma_t_col=args.gamma_t_col
gamma_x_col=args.gamma_x_col
w_theta_col=args.w_theta_col
thetamin=float(args.thetamin)
thetamax=float(args.thetamax)
cfoldername=args.cfoldername
outputfile=args.outputfile
binning=args.binning
DontCheckBinEdges=str2bool(args.force)
# COSEBIs options
nModes=args.nCOSEBIs
tfoldername=args.tfoldername
tplusfile=args.tplusfile
tminusfile=args.tminusfile
normfile=args.normfile
rootfile=args.rootfile
# Bandpower options
logwidth=args.logwidth
thetamin_apod=args.thetamin_apod
thetamax_apod=args.thetamax_apod
if thetamin_apod: 
    thetamin_apod=float(thetamin_apod)
if thetamax_apod: 
    thetamax_apod=float(thetamax_apod)
ellmin=args.ellmin
ellmax=args.ellmax
nbins_bp=args.nbins_bp
save_kernels=args.save_kernels
# xipm options
nbins_2pcf=args.nbins_2pcf
# psi options
ufile=args.ufile
qfile=args.qfile
filterfoldername=args.filterfoldername
psifoldername=args.psifoldername
nModes_psi=args.nModes_psi
if(mode=='psi_gg'):
    corr_type = 'gg'
    correlation = " (galaxy clustering)"
    filename = ufile
elif(mode=='psi_gm'):
    corr_type = 'gm'
    correlation = " (galaxy-galaxy lensing)"
    filename = qfile

print('Input file is '+inputfile+', making '+str(mode)+' for theta in ['+'%.2f' %thetamin+"'," 
    +'%.2f' %thetamax+"'], outputfiles are: "+cfoldername+"/En_"+outputfile+'.ascii and '+cfoldername+'/Bn_'+outputfile+'.ascii')


# Load the input 2pt correlation function data
file=open(inputfile)
header=file.readline().strip('#').split()
tpcf_in=np.loadtxt(file,comments='#')
tpcf_data={}
for i, col in enumerate(header):
    tpcf_data[col]=tpcf_in[:,i]

theta=tpcf_data[theta_col]
if xip_col:
    xip=tpcf_data[xip_col]
    xim=tpcf_data[xim_col]
if gamma_t_col:
    gamma_t=tpcf_data[gamma_t_col]
if gamma_x_col:
    gamma_x=tpcf_data[gamma_x_col]
if w_theta_col:
    w_theta=tpcf_data[w_theta_col]

# Yell at the user if the normalisation and roots files aren't provided when calculating COSEBIs
if mode=='cosebis':
    if not ((normfile != None) and (rootfile != None)):
        raise Exception('Normfile and rootfile need to be provided when calculating COSEBIs!')
if mode.startswith('bandpowers'):
    if ellmin>ellmax:
        raise Exception('ell_min must be smaller than ell_max!')
    try:
        thetamin_apod=float(args.thetamin_apod)
        thetamax_apod=float(args.thetamax_apod)
        print('You have set explicitly set thetamin_apod = %.2f and thetamax_apod = %.2f. This means that scales outside this range will leak into the apodisation window. You have been warned!'%(thetamin_apod, thetamax_apod))
    except: 
        thetamin_apod = np.exp(np.log(thetamin)+logwidth/2)
        thetamax_apod = np.exp(np.log(thetamax)-logwidth/2)

# Conversion from xi_pm to COSEBIS depends on linear or log binning in the 2pt output
# Check that the data exactly spans the theta_min -theta_max range that has been defined
if(binning=='log'):
    good_args=np.squeeze(np.argwhere((theta>thetamin) & (theta<thetamax)))
    nbins_within_range=len(theta[good_args])
    ix=np.linspace(0,nbins_within_range-1,nbins_within_range)
    theta_mid=np.exp(np.log(thetamin)+(np.log(thetamax)-np.log(thetamin))/(nbins_within_range)*(ix+0.5))
# 
    theta_edges=np.logspace(np.log10(thetamin),np.log10(thetamax),nbins_within_range+1)
    # 
    theta_low=theta_edges[0:-1]
    theta_high=theta_edges[1::]
    delta_theta=theta_high-theta_low
# 
    #If asked to check, check if the mid points are close enough
    if(DontCheckBinEdges==False):
        if((abs(theta_mid/theta[good_args]-1)>(delta_theta/10.)).all()):
            print(theta_mid)
            print(theta[good_args])
            raise ValueError("The input thetas of the 2pt correlation function data must exactly span the user defined theta_min/max.   This data is incompatible, exiting now ...")
#
elif(binning=='lin'):
    good_args=np.squeeze(np.argwhere((theta>thetamin) & (theta<thetamax)))
    nbins_within_range=len(theta[good_args])
    delta_theta=np.zeros(nbins_within_range)
    delta_theta[1::]=(theta[1]-theta[0])
    delta_theta[0]=(theta[1]-theta[0])/2.
    delta_theta[-1]=(theta[1]-theta[0])/2.
    theta_mid=np.linspace(thetamin+delta_theta[0],thetamax-delta_theta[-1],nbins_within_range)
else:
    raise ValueError('Please choose either lin or log with the --binning option, exiting now ...')

#Lets check that the user has provided enough bins
"""
if(binning=='log'):
    if(nbins_within_range<100):
        raise ValueError("The low number of bins in the input 2pt correlation function data will result in low accuracy.  Provide finer log binned data with bins>100, exiting now ...")
elif(binning=='lin'):
    if(nbins_within_range<1000):
        raise ValueError("The low number of bins in the input 2pt correlation function data will result in low accuracy.  Provide finer linear binned data with bins>100, exiting now ...")
"""
        
#OK now we can perform the integrals
arcmin=180*60/np.pi
arcmin2rad = 2*np.pi/360/60

if not os.path.exists(cfoldername):
    os.makedirs(cfoldername)

if mode == 'cosebis':
    if not os.path.exists(tfoldername):
        os.makedirs(tfoldername)

    En=np.zeros(nModes)
    Bn=np.zeros(nModes)
    integ_plus = np.zeros((nModes,len(theta_mid)))
    integ_minus = np.zeros((nModes,len(theta_mid)))
    filter_plus = np.zeros((nModes,len(theta_mid)))
    filter_minus = np.zeros((nModes,len(theta_mid)))

    #Define theta-strings for Tplus/minus filename
    tmin='%.2f' % thetamin
    tmax='%.2f' % thetamax
    thetaRange=args.thetamin+'-'+args.thetamax

    for n in range(1,nModes+1):
        #define Tplus and Tminus file names for this mode

        TplusFileName= tfoldername+'/'+tplusfile+'_n'+str(n)+'_'+thetaRange+'.table'
        TminusFileName= tfoldername+'/'+tminusfile+'_n'+str(n)+'_'+thetaRange+'.table'

        if(os.path.isfile(TplusFileName)):
            print('T_plus file: %s found!'%TplusFileName)
            file = open(TplusFileName)
            tp=np.loadtxt(file,comments='#')
        else:
            print('T_plus file: %s not found! Calculating now!'%TplusFileName)
            file = open(normfile)
            norm_all=np.loadtxt(file,comments='#')
            norm_in=norm_all[n-1]
            norm=norm_in[1]
            # 
            roots_all = [line.strip().split() for line in open(rootfile)]
            root_in=np.double(np.asarray(roots_all[n-1]))
            root=root_in[1::]
            # 
            tp=tplus(thetamin,thetamax,n,norm,root,ntheta=10000)
            np.savetxt(TplusFileName,tp)
    # 
        if(os.path.isfile(TminusFileName)):
            print('T_minus file: %s found!'%TminusFileName)
            file = open(TminusFileName)
            tm=np.loadtxt(file,comments='#')
        else:
            file = open(normfile)
            print('T_minus file: %s not found! Calculating now!'%TminusFileName)
            norm_all=np.loadtxt(file,comments='#')
            norm_in=norm_all[n-1]
            norm=norm_in[1]
        # 
            roots_all = [line.strip().split() for line in open(rootfile)]
            root_in=np.double(np.asarray(roots_all[n-1]))
            root=root_in[1::]
            # 
            tm=tminus(thetamin,thetamax,n,norm,root,tp,ntheta=10000)
            np.savetxt(TminusFileName,tm)

        tp_func=interp1d(tp[:,0], tp[:,1])
        tm_func=interp1d(tm[:,0], tm[:,1])
        # 
        integ_plus[n-1]=tp_func(theta_mid)*theta_mid*xip[good_args]
        integ_minus[n-1]=tm_func(theta_mid)*theta_mid*xim[good_args]
        filter_plus[n-1]=tp_func(theta_mid)*theta_mid
        filter_minus[n-1]=tm_func(theta_mid)*theta_mid
        # 
        Integral_plus=sum(integ_plus[n-1]*delta_theta)
        Integral_minus=sum(integ_minus[n-1]*delta_theta)
        En[n-1]=0.5*(Integral_plus+Integral_minus)/arcmin/arcmin
        Bn[n-1]=0.5*(Integral_plus-Integral_minus)/arcmin/arcmin

    EnfileName=cfoldername+"/En_"+outputfile+".asc"
    BnfileName=cfoldername+"/Bn_"+outputfile+".asc"
    np.savetxt(EnfileName,En)
    np.savetxt(BnfileName,Bn)
    if save_kernels:
        IntegPlusFileName=cfoldername+"/FilterPlus_"+outputfile+".asc"
        IntegMinusFileName=cfoldername+"/FilterMinus_"+outputfile+".asc"
        np.savetxt(IntegPlusFileName,filter_plus)
        np.savetxt(IntegMinusFileName,filter_minus)

elif (mode == 'psi_gg') or (mode == 'psi_gm'):
    if not os.path.exists(filterfoldername):
        os.makedirs(filterfoldername)

    if not os.path.exists(psifoldername):
        os.makedirs(psifoldername)
    psi=np.zeros(nModes_psi)
    #Define theta-strings for Tplus/minus filename
    tmin='%.2f' % thetamin
    tmax='%.2f' % thetamax
    thetaRange=args.thetamin+'-'+args.thetamax

    for n in range(1,nModes_psi+1):
        #define the filter file names for this mode
        filterFileName= filterfoldername+'/'+filename+'_n'+str(n)+'_'+thetaRange
        # read from file if it exists otherwise create new filters and save to file
        if(os.path.isfile(filterFileName)):
            file = open(filterFileName)
            filt=np.loadtxt(file,comments='#')
        else:
            filt=psi_filter(thetamin,thetamax,n,corr_type=corr_type,ntheta=1000)
            np.savetxt(filterFileName,filt)

        filter_func=interp1d(filt[:,0], filt[:,1])
        # 
        if corr_type == 'gm':
            integ=filter_func(theta_mid)*theta_mid*gamma_t[good_args]
        if corr_type == 'gg':
            integ=filter_func(theta_mid)*theta_mid*w_theta[good_args]
        # 
        Integral=sum(integ*delta_theta)
        psi[n-1] = Integral


    psifileName=psifoldername+"/psi_"+corr_type+"_"+outputfile+".asc"
    np.savetxt(psifileName,psi,header=" theta_min = " + tmin + ", theta_max = "+ tmax)

elif mode == 'bandpowers_ee':
    CE = np.zeros(nbins_bp)
    CB = np.zeros(nbins_bp)
    filter_plus = np.zeros((nbins_bp,len(theta_mid)))
    filter_minus = np.zeros((nbins_bp,len(theta_mid)))
    ell = np.logspace(np.log10(ellmin), np.log10(ellmax), nbins_bp+1)

    for i in range(len(ell)-1):
        filter_plus[i]=gplus(theta_mid*arcmin2rad, ell[i], ell[i+1])*theta_mid*arcmin2rad*T(theta_mid, thetamin_apod, thetamax_apod, logwidth)
        filter_minus[i]=gminus(theta_mid*arcmin2rad, ell[i], ell[i+1])*theta_mid*arcmin2rad*T(theta_mid, thetamin_apod, thetamax_apod, logwidth)
        N = np.log(ell[i+1]/ell[i])
        Integral_plus=sum(filter_plus[i]*xip[good_args]*delta_theta)
        Integral_minus=sum(filter_minus[i]*xim[good_args]*delta_theta)
        CE[i]=(Integral_plus+Integral_minus)*np.pi/N*arcmin2rad
        CB[i]=(Integral_plus-Integral_minus)*np.pi/N*arcmin2rad

    CEfileName=cfoldername+"/CEE_"+outputfile+".asc"
    CBfileName=cfoldername+"/CBB_"+outputfile+".asc"
    np.savetxt(CEfileName,CE)
    np.savetxt(CBfileName,CB)
    if save_kernels:
        FilterPlusFileName=cfoldername+"/FilterEEPlus_"+outputfile+".asc"
        FilterMinusFileName=cfoldername+"/FilterEEMinus_"+outputfile+".asc"
        np.savetxt(FilterPlusFileName,filter_plus)
        np.savetxt(FilterMinusFileName,filter_minus)

elif mode == 'bandpowers_ne':
    CnE = np.zeros(nbins_bp)
    CnB = np.zeros(nbins_bp)
    filter = np.zeros((nbins_bp,len(theta_mid)))
    ell = np.logspace(np.log10(ellmin), np.log10(ellmax), nbins_bp+1)

    for i in range(len(ell)-1):
        filter[i]=h(theta_mid*arcmin2rad, ell[i], ell[i+1])*theta_mid*arcmin2rad*T(theta_mid, thetamin_apod, thetamax_apod, logwidth)
        N = np.log(ell[i+1]/ell[i])
        IntegralE=sum(filter[i]*gamma_t*delta_theta)
        IntegralB=sum(filter[i]*gamma_x*delta_theta)
        CnE[i]=IntegralE*2*np.pi/N*arcmin2rad
        CnB[i]=IntegralB*2*np.pi/N*arcmin2rad

    CnEfileName=cfoldername+"/CnE_"+outputfile+".asc"
    CnBfileName=cfoldername+"/CnB_"+outputfile+".asc"
    np.savetxt(CnEfileName,CnE)
    np.savetxt(CnBfileName,CnB)
    if save_kernels:
        FilterFileName=cfoldername+"/FilterNE_"+outputfile+".asc"
        np.savetxt(FilterFileName,filter)

elif mode == 'bandpowers_nn':
    Cnn = np.zeros(nbins_bp)
    filter = np.zeros((nbins_bp,len(theta_mid)))
    ell = np.logspace(np.log10(ellmin), np.log10(ellmax), nbins_bp+1)

    for i in range(len(ell)-1):
        filter[i]=f(theta_mid*arcmin2rad, ell[i], ell[i+1])*T(theta_mid, thetamin_apod, thetamax_apod, logwidth)
        N = np.log(ell[i+1]/ell[i])
        Integral=sum(filter[i]*w_theta*delta_theta)
        Cnn[i]=Integral*2*np.pi/N*arcmin2rad
    CnnfileName=cfoldername+"/Cnn_"+outputfile+".asc"
    np.savetxt(CnnfileName,Cnn)
    if save_kernels:
        FilterFileName=cfoldername+"/FilterNN_"+outputfile+".asc"
        np.savetxt(FilterFileName,filter)

elif mode == 'xipm':
    if binning=='lin':
        lin_not_log = True
    else:
        lin_not_log = False
    meanr = tpcf_data['meanr']
    meanlnr = tpcf_data['meanlogr']
    weight = tpcf_data['weight']
    keys = tpcf_data.keys()
    
    wgtBlock_keys = ['weight', 'npairs', 'npairs_weighted']
    valueBlock_keys = [k for k in keys if (k not in wgtBlock_keys) and (k not in ['r_nom','meanr', 'meanlogr'])]

    valueBlock = np.array([tpcf_data[key] for key in valueBlock_keys])
    wgtBlock = np.array([tpcf_data[key] for key in wgtBlock_keys])

    xipmfileName=cfoldername+"/xipm_binned_"+outputfile+".asc"

    ## Turn sigma into sigma^2
    sigma_idx = [i for i,k in enumerate(valueBlock_keys) if k.startswith('sigma')]
    valueBlock[sigma_idx] = valueBlock[sigma_idx]**2

    ## Rebin
    ctrBin, binned_r, binned_lnr, binned_valueBlock, binned_wgtBlock = rebin(thetamin, thetamax, nbins_2pcf, lin_not_log, meanr, meanlnr, weight, valueBlock, wgtBlock)

    ## Turn sigma^2 into sigma
    valueBlock[sigma_idx] = np.sqrt(valueBlock[sigma_idx])

    all_keys = np.concatenate((['r_nom','meanr', 'meanlogr'], valueBlock_keys, wgtBlock_keys))
    print(all_keys)
    print(ctrBin.shape)
    print(binned_valueBlock.shape)
    print(binned_wgtBlock.shape)
    all_binned_data = np.vstack((ctrBin, binned_r, binned_lnr, binned_valueBlock, binned_wgtBlock))
    print(all_binned_data.shape)
    # Write it out to a file and praise-be for Jarvis and his well documented code
    #treecorr.util.gen_write(xipmfileName, all_keys, all_binned_data, precision=12)
    with treecorr.util.make_writer(xipmfileName, precision=12) as writer:
        writer.write(all_keys, all_binned_data)
    
elif mode == 'gt':
    if binning=='lin':
        lin_not_log = True
    else:
        lin_not_log = False
    meanr = tpcf_data['meanr']
    meanlnr = tpcf_data['meanlogr']
    weight = tpcf_data['weight']
    keys = tpcf_data.keys()
    
    wgtBlock_keys = ['weight', 'npairs_weighted']#, 'npairs_weighted']
    valueBlock_keys = [k for k in keys if (k not in wgtBlock_keys) and (k not in ['r_nom','meanr', 'meanlogr'])]

    valueBlock = np.array([tpcf_data[key] for key in valueBlock_keys])
    wgtBlock = np.array([tpcf_data[key] for key in wgtBlock_keys])

    gtfileName=cfoldername+"/gt_binned_"+outputfile+".asc"

    ## Turn sigma into sigma^2
    sigma_idx = [i for i,k in enumerate(valueBlock_keys) if k.startswith('sigma')]
    valueBlock[sigma_idx] = valueBlock[sigma_idx]**2

    ## Rebin
    ctrBin, binned_r, binned_lnr, binned_valueBlock, binned_wgtBlock = rebin(thetamin, thetamax, nbins_2pcf, lin_not_log, meanr, meanlnr, weight, valueBlock, wgtBlock)

    ## Turn sigma^2 into sigma
    valueBlock[sigma_idx] = np.sqrt(valueBlock[sigma_idx])

    all_keys = np.concatenate((['r_nom','meanr', 'meanlogr'], valueBlock_keys, wgtBlock_keys))
    print(all_keys)
    print(ctrBin.shape)
    print(binned_valueBlock.shape)
    print(binned_wgtBlock.shape)
    all_binned_data = np.vstack((ctrBin, binned_r, binned_lnr, binned_valueBlock, binned_wgtBlock))
    print(all_binned_data.shape)
    # Write it out to a file and praise-be for Jarvis and his well documented code
    #treecorr.util.gen_write(gtfileName, all_keys, all_binned_data, precision=12)
    with treecorr.util.make_writer(gtfileName, precision=12) as writer:
        writer.write(all_keys, all_binned_data)
    
elif mode == 'wt':
    if binning=='lin':
        lin_not_log = True
    else:
        lin_not_log = False
    meanr = tpcf_data['meanr']
    meanlnr = tpcf_data['meanlogr']
    weight = tpcf_data['weight']
    keys = tpcf_data.keys()
    
    wgtBlock_keys = ['weight', 'npairs_weighted']#, 'npairs_weighted']
    valueBlock_keys = [k for k in keys if (k not in wgtBlock_keys) and (k not in ['r_nom','meanr', 'meanlogr'])]

    valueBlock = np.array([tpcf_data[key] for key in valueBlock_keys])
    wgtBlock = np.array([tpcf_data[key] for key in wgtBlock_keys])

    wtfileName=cfoldername+"/wt_binned_"+outputfile+".asc"

    ## Turn sigma into sigma^2
    sigma_idx = [i for i,k in enumerate(valueBlock_keys) if k.startswith('sigma')]
    valueBlock[sigma_idx] = valueBlock[sigma_idx]**2

    ## Rebin
    ctrBin, binned_r, binned_lnr, binned_valueBlock, binned_wgtBlock = rebin(thetamin, thetamax, nbins_2pcf, lin_not_log, meanr, meanlnr, weight, valueBlock, wgtBlock)

    ## Turn sigma^2 into sigma
    valueBlock[sigma_idx] = np.sqrt(valueBlock[sigma_idx])

    all_keys = np.concatenate((['r_nom','meanr', 'meanlogr'], valueBlock_keys, wgtBlock_keys))
    print(all_keys)
    print(ctrBin.shape)
    print(binned_valueBlock.shape)
    print(binned_wgtBlock.shape)
    all_binned_data = np.vstack((ctrBin, binned_r, binned_lnr, binned_valueBlock, binned_wgtBlock))
    print(all_binned_data.shape)
    # Write it out to a file and praise-be for Jarvis and his well documented code
    #treecorr.util.gen_write(wtfileName, all_keys, all_binned_data, precision=12)
    with treecorr.util.make_writer(wtfileName, precision=12) as writer:
        writer.write(all_keys, all_binned_data)
    
else:
    raise Exception('Unknown mode!')

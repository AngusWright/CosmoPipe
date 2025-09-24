import numpy as np
import os
from scipy.interpolate import interp1d
from measure_cosebis import tplus,tminus, str2bool
from argparse import ArgumentParser

# Written by Marika Asgari (ma@roe.ac.uk)
# Python script to return COSEBIS E and B modes given a measured 2pt correlation function
# Note that the input correlation function needs to contain data that 
# exactly spans the required ${tmin}-${tmax} range

# example run:
# tmin=0.50
# tmax=100.00
# python run_measure_cosebis_cats2stats.py -i xi_nBins_1_Bin1_Bin1 -o nBins_1_Bin1_Bin1 --norm ./TLogsRootsAndNorms/Normalization_${tmin}-${tmax}.table -r 
# ./TLogsRootsAndNorms/Root_${tmin}-${tmax}.table -b lin --thetamin ${tmin} --thetamax ${tmax} -n 20

# Specify the input arguments
parser = ArgumentParser(description='Take input 2pcfs files and calculate COSEBIs')
parser.add_argument("-i", "--inputfile", dest="inputfile",
    help="Full Input file name", metavar="inputFile",required=True)

parser.add_argument('-t','--theta_col', dest="theta_col", type=str,nargs='?',required=True,
         help='column for theta, default is 0')

parser.add_argument('-p','--xip_col', dest="xip_col", type=str,nargs='?',required=True,
         help='column for xi_plus, default is 1')

parser.add_argument('-m','--xim_col', dest="xim_col", type=str, nargs='?',required=True,
         help='column for xi_minus, default is 2')


parser.add_argument('--cfoldername', dest="cfoldername", 
    help='full name and address of the folder for En/Bn files, default is cosebis_results',default="./cosebis_results",required=False)

parser.add_argument("-o", "--outputfile", dest="outputfile"
                    ,help="output file name suffix. The outputs are cfoldername/En_${outputfile}.ascii and cfoldername/Bn_${outputfile}.ascii"
                    ,metavar="outputFile",required=True)


parser.add_argument('-b','--binning', dest="binning", help='log or lin binning, default is log',default="log",required=False)
parser.add_argument('-f','--force',dest="force",nargs='?', help='Do not check if the bin edges match. Default is FALSE.',default=False,required=False)

parser.add_argument('-n','--nCOSEBIs', dest="nModes", type=int,default=10, nargs='?',
         help='number of COSEBIs modes to produce, default is 10')

parser.add_argument('-s','--thetamin', dest="thetamin", type=float,default=0.5, 
    nargs='?', help='value of thetamin in arcmins')

parser.add_argument('-l','--thetamax', dest="thetamax", type=float,default=300.0, 
    nargs='?', help='value of thetamax, in arcmins')

parser.add_argument('--tfoldername', dest="tfoldername", help='name and full address of the folder for Tplus Tminus files, will make it if it does not exist',default="Tplus_minus",required=False)
parser.add_argument('--tplusfile', dest="tplusfile", help='name of Tplus file, will look for it before running the code',default="Tplus",required=False)
parser.add_argument('--tminusfile', dest="tminusfile", help='name of Tplus file, will look for it before running the code',default="Tminus",required=False)

parser.add_argument('-c','--norm', dest="normfile", help='normalisation file name and address for T_plus/minus', metavar="norm",required=True)
parser.add_argument('-r','--root', dest="rootfile", help='roots file name and address for T_plus/minus', metavar="root",required=True)


args = parser.parse_args()

inputfile=args.inputfile
theta_col=args.theta_col
xip_col=args.xip_col
xim_col=args.xim_col
outputfile=args.outputfile
nModes=args.nModes
thetamin=args.thetamin
thetamax=args.thetamax
normfile=args.normfile
rootfile=args.rootfile
tplusfile=args.tplusfile
tminusfile=args.tminusfile
tfoldername=args.tfoldername
cfoldername=args.cfoldername
binning=args.binning
DontCheckBinEdges=str2bool(args.force)

print('input file is '+inputfile+', making COSEBIs for '+str(nModes)+' modes and theta in ['+'%.2f' %thetamin+"'," 
    +'%.2f' %thetamax+"'], outputfiles are: "+cfoldername+"/En_"+outputfile+'.ascii and '+cfoldername+'/Bn_'+outputfile+'.ascii')


# Load the input 2pt correlation function data
file=open(inputfile)
header=file.readline().strip('#').split()
xipm_in=np.loadtxt(file,comments='#')
xipm_data={}
for i, col in enumerate(header):
    xipm_data[col]=xipm_in[:,i]

theta=xipm_data[theta_col]
xip=xipm_data[xip_col]
xim=xipm_data[xim_col]

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
if(binning=='log'):
    if(nbins_within_range<100):
        raise ValueError("The low number of bins in the input 2pt correlation function data will result in low accuracy.  Provide finer log binned data with bins>100, exiting now ...")
elif(binning=='lin'):
    if(nbins_within_range<1000):
        raise ValueError("The low number of bins in the input 2pt correlation function data will result in low accuracy.  Provide finer linear binned data with bins>100, exiting now ...")

#OK now we can perform the COSEBI integrals
arcmin=180*60/np.pi

if not os.path.exists(tfoldername):
    os.makedirs(tfoldername)

if not os.path.exists(cfoldername):
    os.makedirs(cfoldername)

En=np.zeros(nModes)
Bn=np.zeros(nModes)

#Define theta-strings for Tplus/minus filename
tmin='%.2f' % thetamin
tmax='%.2f' % thetamax
thetaRange=tmin+'-'+tmax

for n in range(1,nModes+1):
    #define Tplus and Tminus file names for this mode

    TplusFileName= tfoldername+'/'+tplusfile+'_n'+str(n)+'_'+thetaRange
    TminusFileName= tfoldername+'/'+tminusfile+'_n'+str(n)+'_'+thetaRange

    if(os.path.isfile(TplusFileName)):
        file = open(TplusFileName)
        tp=np.loadtxt(file,comments='#')
    else:
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
        file = open(TminusFileName)
        tm=np.loadtxt(file,comments='#')
    else:
        file = open(normfile)
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
    integ_plus=tp_func(theta_mid)*theta_mid*xip[good_args]
    integ_minus=tm_func(theta_mid)*theta_mid*xim[good_args]
    # 
    Integral_plus=sum(integ_plus*delta_theta)
    Integral_minus=sum(integ_minus*delta_theta)
    En[n-1]=0.5*(Integral_plus+Integral_minus)/arcmin/arcmin
    Bn[n-1]=0.5*(Integral_plus-Integral_minus)/arcmin/arcmin

EnfileName=cfoldername+"/En_"+outputfile+".asc"
BnfileName=cfoldername+"/Bn_"+outputfile+".asc"
np.savetxt(EnfileName,En)
np.savetxt(BnfileName,Bn)




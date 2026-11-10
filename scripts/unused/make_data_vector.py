import re
import os
import numpy as np
from argparse import ArgumentParser

# Reads in from the list of input_files and puts them all into a long vector. 
# Make sure that the ordering is correct, col starts from 1 instead of 0
def make_2pt_vector(input_files, m_corr,col=1):
    for rp in range(len(input_files)):
        file= open(input_files[rp])
        data=np.loadtxt(file,comments='#')
        if data.ndim==1:
            if rp==0:
                data_all      = data.copy()
                data_all_corr = data/m_corr[rp]
            else:
                data_all      = np.hstack((data_all,data))
                data_all_corr = np.hstack((data_all_corr,data/m_corr[rp]))
        else:
            if rp==0:
                data_all      = data[:,col-1].copy()
                data_all_corr = data[:,col-1]/m_corr[rp]
            else:
                data_all      = np.hstack((data_all,data[:,col-1]))
                data_all_corr = np.hstack((data_all_corr,data[:,col-1]/m_corr[rp]))
    return data_all,data_all_corr

def rebin(x,signal,weight,x_min,x_max,nbins):
    # print('rebinning now')
    binned_output=np.zeros((nbins,3))
    for ibins in range(nbins):
        x_binned=np.exp(np.log(x_min)+np.log(x_max/x_min)/(nbins)*(ibins+0.5))
        upperEdge=np.exp(np.log(x_min)+np.log(x_max/x_min)/(nbins)*(ibins+1.0))
        lowerEdge=np.exp(np.log(x_min)+np.log(x_max/x_min)/(nbins)*(ibins))
        good=((x<upperEdge) & (x>lowerEdge))
        # print(x_binned)
        if(good.any()):
            weight_sum=weight[good].sum()
            x_binned_weighted=(x[good]*weight[good]).sum()/weight_sum
            binned_output[ibins,0]=x_binned
            binned_output[ibins,1]=x_binned_weighted
            binned_output[ibins,2]=(signal[good]*weight[good]).sum()/weight_sum
            # print(ibins,weight_sum,len(weight[good]))
        else:
            print("WARNING: not enough bins to rebin to "+str(nbins)+" log bins")
    return binned_output


##################################################################################
### Making data vectors for Phase-1 real data

parser = ArgumentParser(description='Construct an input cosebi data vector for cosmosis mcmc')
parser.add_argument("-i", "--inputfiles", dest="DataFiles",nargs='+',
    help="Full Input file names", metavar="inputFile",required=True)
parser.add_argument("-m", "--mbias", dest="mbias",nargs='+',
    help="multiplicative bias per tomographic bin",required=True)
parser.add_argument("-t", "--tomobins", dest="tomoBins",nargs='+',
    help="tomographic bin limits",required=True)
parser.add_argument("-o", "--outputfile", dest="outputFile",
    help="Full Output file name", metavar="outputFile",required=True)

args = parser.parse_args()
    
# This is were the raw 2pt data is saved 
print(args.DataFiles)
matches = np.array([ "En_" in i for i in args.DataFiles ])
print(matches)
EnDataFiles = np.array(args.DataFiles)[matches]
print(EnDataFiles)
nBins_source = len(args.tomoBins)-1
print(args.tomoBins)
print(nBins_source)
tomoBins = [ str(i).replace(".","p") for i in args.tomoBins ]

ZBstr = {}
for bin in range(nBins_source):
    ZBstr[bin] = "ZB"+str(tomoBins[bin])+"t"+str(tomoBins[bin+1])


#####################################################################################################
# COSEBIs
input_files = []
m_corr_all  = []
m = args.mbias
#Check if mbias is a file or list of files or float 
mout=[]
for mval in m:
    if os.path.isfile(mval):
        data=np.loadtxt(mval,comments='#')
        for val in data: 
            mout.append(val)
    else:
        try:
            mout.append(float(mval))
        except:
            raise ValueError(f"provided m {mval} is neither a valid file nor a float?!")

print(mout)

for bin1 in range(nBins_source):
    for bin2 in range(bin1,nBins_source):
        #fileNameInput=name+str(bin1+1)+'_'+str(bin2+1)+'.asc'
        tomoxcorrstr="_"+ZBstr[bin1]+"_"+ZBstr[bin2]+'_cosebis.asc'
        #tomoxcorrstr=""+ZBstr[bin1]+""+ZBstr[bin2]+'_cosebis.asc'
        print(tomoxcorrstr)
        match=np.array([tomoxcorrstr in i for i in EnDataFiles])
        fileNameInput=EnDataFiles[match][0]
        input_files.append(fileNameInput)
        m_corr= (1.+mout[bin2])*(1.+mout[bin1])
        m_corr_all.append(m_corr)

print(input_files)

m_corr_arr=np.asarray(m_corr_all)

COSEBIs_vector_no_m_bias, COSEBIs_vector_with_m_bias  = make_2pt_vector(input_files,m_corr_arr)

np.savetxt(args.outputFile,COSEBIs_vector_with_m_bias)


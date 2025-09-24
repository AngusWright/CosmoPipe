import re
import os
import numpy as np
from argparse import ArgumentParser
import pandas as pd

# Reads in from the list of input_files and puts them all into a long vector. 
# Make sure that the ordering is correct, col starts from 1 instead of 0
def make_2pt_vector(input_files, m_corr,col=1, xipm=False, correlations='EE'):
    if xipm==False:
        for rp in range(len(input_files)):
            file= open(input_files[rp])
            #print(input_files[rp])
            data=np.loadtxt(file,comments='#')
            #print(m_corr[rp])
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
    else:
        # for xipm assume that the input data file is in treecorr format
        for rp in range(len(input_files)):
            with open(input_files[rp]) as f:
                header=f.readline().strip('#').split()
            data = pd.read_csv(input_files[rp], delim_whitespace=True, comment = '#', names = header)
            if correlations == 'EE':
                data_xip = data['xip']
                data_xim = data['xim']
                if rp==0:
                    data_xip_all      = data_xip.copy()
                    data_xip_all_corr = data_xip/m_corr[rp]
                    data_xim_all      = data_xim.copy()
                    data_xim_all_corr = data_xim/m_corr[rp]
                else:
                    data_xip_all      = np.hstack((data_xip_all,data_xip))
                    data_xip_all_corr = np.hstack((data_xip_all_corr,data_xip/m_corr[rp]))
                    data_xim_all      = np.hstack((data_xim_all,data_xim))
                    data_xim_all_corr = np.hstack((data_xim_all_corr,data_xim/m_corr[rp]))
                data_all = np.concatenate((data_xip_all,data_xim_all))
                data_all_corr = np.concatenate((data_xip_all_corr,data_xim_all_corr))
            if correlations == 'NE':
                data_gt = data['gamT']
                #data_gx = data['gamX']
                if rp==0:
                    data_gt_all      = data_gt.copy()
                    data_gt_all_corr = data_gt/m_corr[rp]
                    #data_gx_all      = data_gx.copy()
                    #data_gx_all_corr = data_gx/m_corr[rp]
                else:
                    data_gt_all      = np.hstack((data_gt_all,data_gt))
                    data_gt_all_corr = np.hstack((data_gt_all_corr,data_gt/m_corr[rp]))
                    #data_gx_all      = np.hstack((data_gx_all,data_gx))
                    #data_gx_all_corr = np.hstack((data_gx_all_corr,data_gx/m_corr[rp]))
                #data_all = np.concatenate((data_gt_all,data_gx_all))
                #data_all_corr = np.concatenate((data_gt_all_corr,data_gx_all_corr))
                data_all = data_gt_all
                data_all_corr = data_gt_all_corr
            if correlations == 'NN':
                data_wt = data['wtheta']
                if rp==0:
                    data_wt_all      = data_wt.copy()
                    data_wt_all_corr = data_wt/m_corr[rp]
                else:
                    data_wt_all      = np.hstack((data_wt_all,data_wt))
                    data_wt_all_corr = np.hstack((data_wt_all_corr,data_wt/m_corr[rp]))
                data_all = data_wt_all
                data_all_corr = data_wt_all_corr

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
parser.add_argument("-s", "--statistic", dest="statistic", type=str, required=True, choices = ['cosebis','cosebis_dimless','psi_stats_gg','psi_stats_gm','bandpowers_ee','bandpowers_ne','bandpowers_nn','xipm','xipsf','xigpsf','gt','wt'],
    help="2pt statistic, must be either cosebis, psi_stats, bandpowers, or xipm")
parser.add_argument("-m", "--mbias", dest="mbias",nargs='+',
    help="multiplicative bias per tomographic bin",required=True)
parser.add_argument("-t", "--tomobins", dest="tomoBins",nargs='+',
    help="tomographic bin limits",required=False, default=0)
parser.add_argument("-l", "--lensbins", dest="lensBins",type=int,
    help="number of lens bins",required=False, default=0)
parser.add_argument("-o", "--outputfile", dest="outputFile",
    help="Full Output file name", metavar="outputFile",required=True)

args = parser.parse_args()
statistic = args.statistic
label = statistic

if statistic == 'xipsf' or statistic == 'xigpsf':
    statistic='xipm'
if statistic == 'cosebis_dimless': 
    statistic='cosebis'
    
if statistic in ['bandpowers_ee', 'bandpowers_ne', 'cosebis', 'psi_stats_gm', 'xipm', 'gt']:
    nBins_source = len(args.tomoBins)-1
    tomoBins = [ str(i).replace(".","p") for i in args.tomoBins ]

    ZBstr = {}
    for bin in range(nBins_source):
        ZBstr[bin] = "ZB"+str(tomoBins[bin])+"t"+str(tomoBins[bin+1])
    
if statistic in ['bandpowers_ne', 'bandpowers_nn', 'psi_stats_gm', 'psi_stats_gg', 'gt', 'wt']:
    nBins_lens = args.lensBins

    LBstr = {}
    for bin in range(nBins_lens):
        LBstr[bin] = "LB"+str(bin+1)
        
# m-bias
m = args.mbias
#Check if mbias is a file or list of files or float 
mout=[]
for mval in m:
    if os.path.isfile(mval):
        data=np.loadtxt(mval,comments='#')
        if data.ndim == 0:
            data=np.array([data])
        for val in data: 
            mout.append(val)
    else:
        try:
            mout.append(float(mval))
        except:
            raise ValueError(f"provided m {mval} is neither a valid file nor a float?!")

#print(mout)
if statistic in ['bandpowers_ee', 'cosebis', 'xipm']:
    m_corr_e  = []
    for bin1 in range(nBins_source):
        for bin2 in range(bin1,nBins_source):
            m_corr = (1.+mout[bin2])*(1.+mout[bin1])
            m_corr_e.append(m_corr)
    m_corr_e = np.asarray(m_corr_e)
    #print(m_corr_e)
    # no b-bias correction for b-modes. Just fill an array with ones
    m_corr_b=np.ones(m_corr_e.shape)

    m_corr_arr = np.concatenate((m_corr_e,m_corr_b))

    m_corr_arr_all = np.concatenate((m_corr_e,m_corr_e))

# m correction for ggl
if statistic in ['bandpowers_ne', 'psi_stats_gm', 'gt']:
    m_corr_ggl  = []
    for bin1 in range(nBins_lens):
        for bin2 in range(nBins_source):
            m_corr = (1.+mout[bin2])
            m_corr_ggl.append(m_corr)
    m_corr_ggl = np.asarray(m_corr_ggl)
    #print(m_corr_ggl)
    
# dummy m correction for clustering
if statistic in ['bandpowers_nn', 'psi_stats_gg', 'wt']:
    m_corr_clustering  = []
    for bin1 in range(nBins_lens):
        m_corr_clustering.append(1.0)
    m_corr_clustering = np.asarray(m_corr_clustering)
    #print(m_corr_clustering)

# This is were the raw 2pt data is saved 
#print(args.DataFiles)
input_files = []
if statistic == 'cosebis':
    matches_cosebis = np.array([ "En_" in i for i in args.DataFiles])
    EnDataFiles = np.array(args.DataFiles)[matches_cosebis]
    try:
        matches_cosebis_b = np.array([ "Bn_" in i for i in args.DataFiles])
        BnDataFiles = np.array(args.DataFiles)[matches_cosebis_b]
    except:
        matches_cosebis_b = np.array([ "En_" in i for i in args.DataFiles])
        BnDataFiles = np.array(args.DataFiles)[matches_cosebis_b]
    #Input file name list: E-modes first, then B-modes. There's probably a smarter way to do this.
    for bin1 in range(nBins_source):
        for bin2 in range(bin1,nBins_source):
            tomoxcorrstr="_"+ZBstr[bin1]+"_"+ZBstr[bin2]+'_cosebis.asc'
            match=np.array([tomoxcorrstr in i for i in EnDataFiles])
            fileNameInput=EnDataFiles[match][0]
            input_files.append(fileNameInput)
    for bin1 in range(nBins_source):
        for bin2 in range(bin1,nBins_source):
            tomoxcorrstr="_"+ZBstr[bin1]+"_"+ZBstr[bin2]+'_cosebis.asc'
            match=np.array([tomoxcorrstr in i for i in BnDataFiles])
            fileNameInput=BnDataFiles[match][0]
            input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias  = make_2pt_vector(input_files,m_corr_arr)
    datavector_no_m_bias_all, datavector_with_m_bias_all  = make_2pt_vector(input_files,m_corr_arr_all)
    
elif statistic == 'psi_stats_gm':
    matches_psi = np.array([ "psi_gm_" in i for i in args.DataFiles])
    PsiDataFiles = np.array(args.DataFiles)[matches_psi]
    #Input file name list:
    for bin1 in range(nBins_lens):
        for bin2 in range(nBins_source):
            tomoxcorrstr="_"+LBstr[bin1]+"_"+ZBstr[bin2]+'_psi_stats.asc'
            match=np.array([tomoxcorrstr in i for i in PsiDataFiles])
            fileNameInput=PsiDataFiles[match][0]
            input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias  = make_2pt_vector(input_files,m_corr_ggl)
    datavector_no_m_bias_all, datavector_with_m_bias_all  = make_2pt_vector(input_files,m_corr_ggl)
    
elif statistic == 'psi_stats_gg':
    matches_psi = np.array([ "psi_gg_" in i for i in args.DataFiles])
    PsiDataFiles = np.array(args.DataFiles)[matches_psi]
    #Input file name list:
    for bin1 in range(nBins_lens):
        tomoxcorrstr="_"+LBstr[bin1]+'_psi_stats.asc'
        match=np.array([tomoxcorrstr in i for i in PsiDataFiles])
        fileNameInput=PsiDataFiles[match][0]
        input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias  = make_2pt_vector(input_files,m_corr_clustering)
    datavector_no_m_bias_all, datavector_with_m_bias_all  = make_2pt_vector(input_files,m_corr_clustering)

elif statistic == 'bandpowers_ee':
    matches_bandpowers = np.array([ "CEE_" in i for i in args.DataFiles])
    CEEDataFiles = np.array(args.DataFiles)[matches_bandpowers]
    try:
        matches_bandpowers_B = np.array([ "CBB_" in i for i in args.DataFiles])
        CBBDataFiles = np.array(args.DataFiles)[matches_bandpowers_B]
    except:
        matches_bandpowers_B = np.array([ "CEE_" in i for i in args.DataFiles])
        CBBDataFiles = np.array(args.DataFiles)[matches_bandpowers_B]
    #Input file name list: E-modes first, then B-modes. There's probably a smarter way to do this.
    for bin1 in range(nBins_source):
        for bin2 in range(bin1,nBins_source):
            tomoxcorrstr="_"+ZBstr[bin1]+"_"+ZBstr[bin2]+'_bandpowers.asc'
            match=np.array([tomoxcorrstr in i for i in CEEDataFiles])
            fileNameInput=CEEDataFiles[match][0]
            input_files.append(fileNameInput)
    for bin1 in range(nBins_source):
        for bin2 in range(bin1,nBins_source):
            tomoxcorrstr="_"+ZBstr[bin1]+"_"+ZBstr[bin2]+'_bandpowers.asc'
            match=np.array([tomoxcorrstr in i for i in CBBDataFiles])
            fileNameInput=CBBDataFiles[match][0]
            input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias = make_2pt_vector(input_files,m_corr_arr)
    datavector_no_m_bias_all, datavector_with_m_bias_all = make_2pt_vector(input_files,m_corr_arr_all)

elif statistic == 'bandpowers_ne':
    matches_bandpowers = np.array([ "CnE_" in i for i in args.DataFiles])
    CnEDataFiles = np.array(args.DataFiles)[matches_bandpowers]
    #try:
    #    matches_bandpowers_B = np.array([ "CnB_" in i for i in args.DataFiles])
    #    CnBDataFiles = np.array(args.DataFiles)[matches_bandpowers_B]
    #except:
    #    matches_bandpowers_B = np.array([ "CnE_" in i for i in args.DataFiles])
    #    CnBDataFiles = np.array(args.DataFiles)[matches_bandpowers_B]
    #Input file name list:
    for bin1 in range(nBins_lens):
        for bin2 in range(nBins_source):
            tomoxcorrstr="_"+LBstr[bin1]+"_"+ZBstr[bin2]+'_bandpowers.asc'
            match=np.array([tomoxcorrstr in i for i in CnEDataFiles])
            fileNameInput=CnEDataFiles[match][0]
            input_files.append(fileNameInput)
    #for bin1 in range(nBins_lens):
    #    for bin2 in range(nBins_source):
    #        tomoxcorrstr="_"+LBstr[bin1]+"_"+ZBstr[bin2]+'_bandpowers.asc'
    #        match=np.array([tomoxcorrstr in i for i in CnBDataFiles])
    #        fileNameInput=CnBDataFiles[match][0]
    #        input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias = make_2pt_vector(input_files,np.concatenate((m_corr_ggl,m_corr_ggl)))
    datavector_no_m_bias_all, datavector_with_m_bias_all  = make_2pt_vector(input_files,np.concatenate((m_corr_ggl,m_corr_ggl)))
        
elif statistic == 'bandpowers_nn':
    matches_bandpowers = np.array([ "Cnn_" in i for i in args.DataFiles])
    CnnDataFiles = np.array(args.DataFiles)[matches_bandpowers]
    print(args.DataFiles)
    print(CnnDataFiles)
    #Input file name list:
    for bin1 in range(nBins_lens):
        tomoxcorrstr="_"+LBstr[bin1]+'_bandpowers.asc'
        match=np.array([tomoxcorrstr in i for i in CnnDataFiles])
        fileNameInput=CnnDataFiles[match][0]
        input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias = make_2pt_vector(input_files,m_corr_clustering)
    datavector_no_m_bias_all, datavector_with_m_bias_all  = make_2pt_vector(input_files,m_corr_clustering)

elif statistic == 'xipm':
    matches_xipm = np.array([ "xipm_binned_" in i for i in args.DataFiles])
    XipmDataFiles = np.array(args.DataFiles)[matches_xipm]
    for bin1 in range(nBins_source):
        for bin2 in range(bin1,nBins_source):
            tomoxcorrstr="_"+ZBstr[bin1]+"_"+ZBstr[bin2]+'_'+label+'_binned.asc'
            match=np.array([tomoxcorrstr in i for i in XipmDataFiles])
            fileNameInput=XipmDataFiles[match][0]
            input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias = make_2pt_vector(input_files,m_corr_e, xipm=True, correlations='EE')
    
elif statistic == 'gt':
    matches_gt = np.array([ "gt_binned_" in i for i in args.DataFiles])
    gtDataFiles = np.array(args.DataFiles)[matches_gt]
    for bin1 in range(nBins_lens):
        for bin2 in range(nBins_source):
            tomoxcorrstr="_"+LBstr[bin1]+"_"+ZBstr[bin2]+'_'+label+'_binned.asc'
            match=np.array([tomoxcorrstr in i for i in gtDataFiles])
            fileNameInput=gtDataFiles[match][0]
            input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias = make_2pt_vector(input_files,m_corr_ggl, xipm=True, correlations='NE')
    
elif statistic == 'wt':
    matches_wt = np.array([ "wt_binned_" in i for i in args.DataFiles])
    wtDataFiles = np.array(args.DataFiles)[matches_wt]
    for bin1 in range(nBins_lens):
        tomoxcorrstr="_"+LBstr[bin1]+'_'+label+'_binned.asc'
        match=np.array([tomoxcorrstr in i for i in wtDataFiles])
        fileNameInput=wtDataFiles[match][0]
        input_files.append(fileNameInput)
    datavector_no_m_bias, datavector_with_m_bias = make_2pt_vector(input_files,m_corr_clustering, xipm=True, correlations='NN')
else:
    raise Exception('Unknown statistic!')

# Save output files
if statistic in ['xipm','gt','wt']:
    np.savetxt(args.outputFile+'.txt',datavector_with_m_bias)
    np.savetxt(args.outputFile+'_no_m_bias.txt',datavector_no_m_bias)
else:
    np.savetxt(args.outputFile+'_m_E_only.txt',datavector_with_m_bias)
    np.savetxt(args.outputFile+'.txt',datavector_with_m_bias_all)
    np.savetxt(args.outputFile+'_no_m_bias.txt',datavector_no_m_bias)

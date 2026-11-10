#=========================================
#
# Makes the correlated covariance for m_bias prior
# Note this is not the same as the m_cov that is part of the 2pt cov
#
#=========================================

import numpy as np
from argparse import ArgumentParser
# make m_cov based on sigma_m values for each redshift bin 
# and assume that there is 'corr' correlation between the bins. corr=1 is full correlation.
# m = np.asarray("@MBIASVALUES@".split())

parser = ArgumentParser(description='Construct the Nz file needed by cosmosis')
parser.add_argument('--msigm', dest='sigma_m_file', type=str, required=True, help="sigma values file")
parser.add_argument('--mcorr', dest='sigma_corr_file', type=str, required=True, help="sigma correlation file")
parser.add_argument('--output', dest='output_base', type=str, required=True, help="output file base")

args = parser.parse_args()

sigma_m_file = args.sigma_m_file
corr_file = args.sigma_corr_file

sigma_m = np.loadtxt(sigma_m_file,comments='#')
corr = np.loadtxt(corr_file,comments='#')
if sigma_m.ndim == 0:
    sigma_m=np.array([sigma_m])
#Input M bias uncertainty
#Fixed 2% mbias uncertainty 
sigma_m_0p02=np.ones(len(sigma_m))*0.02
##Correlation between m's (string version for output names)
#str_corr = '%0.2f' % corr

#Construct m cov matrix for input m uncertainties {{{
m_cov=np.diag(sigma_m**2)
nbins=len(sigma_m)
#Loop over bin combinations
for i in range(nbins):
    for j in range(nbins):
        if not i==j:
            m_cov[i,j]=sigma_m[i]*sigma_m[j]*corr
#Output matrix
#np.savetxt(args.output_base+str_corr+'.ascii',m_cov,fmt='%.4e')
np.savetxt(args.output_base+'.ascii',m_cov,fmt='%.4e')
#}}}

#Construct m cov matrix for fixed 2% m uncertainties {{{
m_cov=np.diag(sigma_m_0p02**2)
for i in range(nbins):
    for j in range(nbins):
        if not i==j:
            m_cov[i,j]=sigma_m_0p02[i]*sigma_m_0p02[j]*corr
#Output matrix 
#np.savetxt(args.output_base+str_corr+'_0p02.ascii',m_cov,fmt='%.4e')
np.savetxt(args.output_base+'_0p02.ascii',m_cov,fmt='%.4e')
#}}}

#Construct correlation matrix for input m uncertianties {{{
m_corr=np.zeros((nbins,nbins))
for i in range(nbins):
    for j in range(nbins):
        m_corr[i,j]=m_cov[i,j]/np.sqrt(m_cov[i,i]*m_cov[j,j])
#np.savetxt(args.output_base+str_corr+'_correl.ascii',m_corr,fmt='%.4e')
np.savetxt(args.output_base+'_correl.ascii',m_corr,fmt='%.4e')
#}}}

# Here we make an uncorrelated m covariance which encompasses 
# all possible correlations that the original m_cov could have
# based on Hoyle et al.2018, appendix A: https://arxiv.org/pdf/1708.01532.pdf
#For the input m uncertainties {{{
m_cov = np.diag(len(sigma_m)*sigma_m**2)
np.savetxt(args.output_base+'_uncorrelated_inflated.ascii',m_cov,fmt='%.4e')
#}}}
#For the 2% m uncertainties {{{
m_cov = np.diag(len(sigma_m)*sigma_m_0p02**2)
np.savetxt(args.output_base+'_uncorrelated_inflated_0p02.ascii',m_cov,fmt='%.4e')
#}}}


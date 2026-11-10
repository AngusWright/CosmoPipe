# ----------------------------------------------------------------
# File Name:           correct_ecliptic_cterm.py
# Author:              Angus H Wright (awright@astro.rub.de)
# Author:              Catherine Heymans (heymans@roe.ac.uk)
# Description:         short python script to apply a c-correction as a function of ecliptic latitude
# ----------------------------------------------------------------
# import sys
import ldac
import numpy as np
# from astropy.io import fits
from astropy import units as u
from astropy.coordinates import SkyCoord
import scipy.stats as stats
import statsmodels.api as sm
from argparse import ArgumentParser

parser = ArgumentParser(description='Take input information and correct c-term')
parser.add_argument("-i", "--inputfile", dest="inputfile",
    help="Full Input file name", metavar="inputFile",required=True)
parser.add_argument("-o", "--outputfile", dest="outputfile",
    help="Full Output file name", metavar="outputFile",required=True)
parser.add_argument("-e1", "--e1name", dest="e1colname",
    help="Column name for the e1 variable", required=True)
parser.add_argument("-e2", "--e2name", dest="e2colname",
    help="Column name for the e2 variable", required=True)
parser.add_argument("-w", "--weightname", dest="wtcolname",
    help="Column name for the weight variable", required=True)
parser.add_argument("-ra", "--raname", dest="racolname",
    help="Column name for the RA variable", required=True)
parser.add_argument("-dec", "--decname", dest="deccolname",
    help="Column name for the Dec variable", required=True)
parser.add_argument("-nb", "--nboot", dest="nboot", type=int,
    help="Number of bootstrap realisations for uncertainty estimation", default=200)
parser.add_argument("-vc", "--varcheck", dest="varcheck", type=bool,default=False,
    help="Do we want to select linear vs constant model based on residuals?")

args = parser.parse_args()
    
# Define the bootstrap error function to calculate the error on the c-terms
def Bootstrap_Error(nboot, samples, weights):
	N = len(samples)
	bt_samples = np.zeros(nboot)		 		# Will store mean of nboot resamples
	for i in range(nboot):
		idx = np.random.randint(0,N,N)			# Picks N random indicies with replacement
		bt_samples[i] = np.sum( weights[idx]*samples[idx] ) / np.sum( weights[idx])
	return np.std(bt_samples)

# Define the bootstrap error function to calculate the error on the c1^2 + c2^2 terms
def Bootstrap_Error_csq(nboot, e1, e2, weights):
    N = len(e1)
    bt_e1 = np.zeros(nboot)		 		# Will store mean of nboot resamples
    bt_e2 = np.zeros(nboot)
    for i in range(nboot):
        idx = np.random.randint(0,N,N)			# Picks N random indicies with replacement
        bt_e1[i] = np.sum( weights[idx]*e1[idx] ) / np.sum( weights[idx])
        bt_e2[i] = np.sum( weights[idx]*e2[idx] ) / np.sum( weights[idx])
    c1=np.average(bt_e1)
    c2=np.average(bt_e2)
    return np.std(bt_e1),np.std(bt_e2), np.std(bt_e1*bt_e1 + bt_e2*bt_e2), np.std((bt_e1-c1)**2 + (bt_e2-c2)**2)

#open the ldac catalogue using functions in ldac.py
#tests have shown ldac.py is much faster than using astropy
ldac_cat = ldac.LDACCat(args.inputfile)
ldac_table = ldac_cat['OBJECTS']


#Select required columns 
e1=ldac_table[args.e1colname]
e2=ldac_table[args.e2colname]
RA=ldac_table[args.racolname]
Dec=ldac_table[args.deccolname]
weight=ldac_table[args.wtcolname]

#Get ecliptic coordinates 
c = SkyCoord(ra=RA*u.degree, dec=Dec*u.degree, frame='icrs')
eclc=c.ecliptic

#Fit linear trend to e1/e2 
# calculate linear fit weighted least squares
## e1
mod_e1 = sm.WLS(e1, sm.add_constant(eclc.b.value), weights=weight)
res_e1 = mod_e1.fit()
pred_e1 = res_e1.predict()
## e2
mod_e2 = sm.WLS(e2, sm.add_constant(eclc.b.value), weights=weight)
res_e2 = mod_e2.fit()
pred_e2 = res_e2.predict()

def weighted_avg_var(values, weights): 
    average=np.average(values,weights=weights)
    variance=np.average((values-average)**2, weights=weights)
    return average, variance

if args.varcheck: 
    
    #Calculate variance test e1: 
    #Variance of residuals from constant and linear models 
    avg_const_e1,var_const_e1 = weighted_avg_var(e1,weights=weight)
    avg_lin_e1,var_lin_e1 = weighted_avg_var(e1-pred_e1,weights=weight)
    
    #F-statistic
    f_value = var_const_e1 / var_lin_e1
    # Calculate the degrees of freedom
    df1 = np.sum(weight) - 1
    df2 = np.sum(weight) - 2
    #Critical F value 
    threshold=0.05
    f_critical = stats.f.ppf(1 - threshold, df1, df2)
    # Calculate the p-value
    p_value_e1 = stats.f.cdf(f_value, df1, df2)
    
    print("e2: F Fcrit df1 df2 p_value ")
    print("%10.3e %10.3e %10.3e %10.3e %10.3e"  % (f_value, f_critical, df1, df2, p_value_e1))
    
    #Use linear fit if F-test p<0.05
    if p_value_e1 < 0.05: 
        e1_corr=e1 - pred_e1
        c1=np.average(pred_e1,weights=weight)
        errc1=np.sqrt(var_lin_e1)/np.sqrt(np.sum(weight))
    else: 
        e1_corr=e1 - avg_const_e1
        c1=avg_const_e1
        errc1=np.sqrt(var_const_e1)/np.sqrt(np.sum(weight))
    
    #Calculate variance test e2: 
    #Variance of residuals from constant and linear models 
    avg_const_e2,var_const_e2 = weighted_avg_var(e2,weights=weight)
    avg_lin_e2,var_lin_e2 = weighted_avg_var(e2-pred_e2,weights=weight)
    
    #F-statistic
    f_value = var_const_e2 / var_lin_e2
    # Calculate the degrees of freedom
    df1 = np.sum(weight) - 1
    df2 = np.sum(weight) - 2
    #Critical F value 
    threshold=0.05
    f_critical = stats.f.ppf(1 - threshold, df1, df2)
    # Calculate the p-value
    p_value_e2 = stats.f.cdf(f_value, df1, df2)
    
    print("e2: F Fcrit df1 df2 p_value ")
    print("%10.3e %10.3e %10.3e %10.3e %10.3e"  % (f_value, f_critical, df1, df2, p_value_e1))
    
    #Use linear fit if F-test p<0.05
    if p_value_e2 < 0.05: 
        e2_corr=e2 - pred_e2
        c2=np.average(pred_e2,weights=weight)
        errc2=np.sqrt(var_lin_e2)/np.sqrt(len(e2))
    else: 
        e2_corr=e2 - avg_const_e2
        c2=avg_const_e2
        errc2=np.sqrt(var_const_e2)/np.sqrt(len(e2))

else: 
    e1_corr=e1 - pred_e1
    avg_lin_e1,var_lin_e1 = weighted_avg_var(e1-pred_e1,weights=weight)
    c1=np.average(pred_e1,weights=weight)
    errc1=np.sqrt(var_lin_e1)/np.sqrt(len(e1))
    e2_corr=e2 - pred_e2
    avg_lin_e2,var_lin_e2 = weighted_avg_var(e2-pred_e2,weights=weight)
    c2=np.average(pred_e2,weights=weight)
    errc2=np.sqrt(var_lin_e2)/np.sqrt(len(e2))
    p_value_e1=-1
    p_value_e2=-1

print("c1 errc1 c2 errc2 p_e1 p_e2")
print("%10.3e %10.3e %10.3e %10.3e %10.3e %10.3e"  % (c1, errc1, c2, errc2,p_value_e1,p_value_e2))

#Save the output to ldac columns 
ldac_table[args.e1colname]=e1_corr
ldac_table[args.e2colname]=e2_corr

#Write out the ldac file 
ldac_cat['OBJECTS']=ldac_table
ldac_cat.saveas(args.outputfile,clobber=False)

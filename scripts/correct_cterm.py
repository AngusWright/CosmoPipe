# ----------------------------------------------------------------
# File Name:           correct_cterm.py
# Author:              Angus H Wright (awright@astro.rub.de)
# Author:              Catherine Heymans (heymans@roe.ac.uk)
# Description:         short python script to apply a c-correction
# ----------------------------------------------------------------
# import sys
import ldac
import numpy as np
# from astropy.io import fits
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
parser.add_argument("-nb", "--nboot", dest="nboot", type=int,
    help="Number of bootstrap realisations for uncertainty estimation", default=200)

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
weight=ldac_table[args.wtcolname]

# weighted mean   
c1=np.average(e1,weights=weight)
c2=np.average(e2,weights=weight)

## Bootstrap error on the mean
#errc1=Bootstrap_Error(nboot, e1, weight)
#errc2=Bootstrap_Error(nboot, e2, weight)

#Bootstrap error on c1^2 + c2^2
errc1,errc2, errcsq, errdcsq= Bootstrap_Error_csq(args.nboot, e1, e2, weight) 

print("c1 errc1 c2 errc2 errcsq errdcsq")
print("%10.3e %10.3e %10.3e %10.3e %10.3e %10.3e"  % (c1, errc1, c2, errc2, errcsq, errdcsq))

#Apply correction
e1_corr = e1 - c1
e2_corr = e2 - c2

#Save the output to ldac columns 
ldac_table[args.e1colname]=e1_corr
ldac_table[args.e2colname]=e2_corr

#Write out the ldac file 
ldac_cat['OBJECTS']=ldac_table
ldac_cat.saveas(args.outputfile,clobber=False)

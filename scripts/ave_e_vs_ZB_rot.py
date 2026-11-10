#
import sys
import numpy as np
import ldac

"""This script takes an input LDAC catalogue
[FIX] And does what?
"""
#

# Read in user input
if len(sys.argv) <4: 
    print ("Usage:", sys.argv[0], "InputCat Weightname Grid")
    sys.exit(1)
else:
    infile="@PATCHPATH@/@SURVEY@_%s_%s@FILESUFFIX@.cat" % (sys.argv[1], sys.argv[3])
    weight = sys.argv[2]
    grid = sys.argv[3]

#open the ldac catalogue using functions in ldac.py
ldac_cat = ldac.LDACCat(infile)
ldac_table = ldac_cat['OBJECTS']

# read in the ellipticity columns to be blinded
#blind='_A'
e1colname='@E1VAR@'
e2colname='@E2VAR@'
wtcolname=weight

e1_in=ldac_table[e1colname]
e2_in=ldac_table[e2colname]
wt_in=ldac_table[wtcolname]

fitclass=ldac_table['fitclass']
cradius_in=ldac_table['contamination_radius']
Strehl_in=ldac_table['PSF_Strehl_ratio']
ZB_in=ldac_table['Z_B']
SNR_in=ldac_table['model_SNratio']
PSFe1_in=ldac_table['PSF_e1']
PSFe2_in=ldac_table['PSF_e2']
scalelength=ldac_table['bias_corrected_scalelength_pixels']
KVbandflag=ldac_table['@GAAPFLAG@']

ngals_all = len(e1_in)

nboot=30
tomolims="@TOMOLIMS@"
tomolims=tomolims.split()
#Ncut is nTOMO + 1 (ALL) = len(tomolims)-1+1
ncut=len(tomolims)

e1w=np.zeros(nboot)
e2w=np.zeros(nboot)

e1_ave=np.zeros(ncut)
e1_err=np.zeros(ncut)
e2_ave=np.zeros(ncut)
e2_err=np.zeros(ncut)
ngals_frac=np.zeros(ncut)

goodgal = ( KVbandflag < 1)

wt_gz=wt_in[goodgal]
e1_gz=e1_in[goodgal]
e2_gz=e2_in[goodgal]
cradius=cradius_in[goodgal]
Strehl=Strehl_in[goodgal]
ZB=ZB_in[goodgal]

PSFe1=PSFe1_in[goodgal]
PSFe2=PSFe2_in[goodgal]

ngals_all = len(e1_gz)

print ("# z_select ngals_frac e1_ave e1_err e2_ave e2_err ngals sum_weight")

for j in range(ncut):
  # Testing dependence on ZB
  if (j<ncut-1) :
    zlo = float(tomolims[j])+0.001
    zhi = float(tomolims[j+1])+0.001
  else:
    zlo = float(tomolims[0])+0.001
    zhi = float(tomolims[ncut-1])+0.001
  cutselect = ((ZB>zlo) & (ZB<=zhi))

  wt = wt_gz[cutselect]
  e1 = e1_gz[cutselect]
  e2 = e2_gz[cutselect]
  eabs = np.sqrt(e1*e1 + e2*e2)
  
  ngals = len(e1)
  ngals_frac[j]=(np.sum(wt)/np.sum(wt_gz)) *100.0

  sow=np.sum(wt)
  me1w=np.dot(e1,wt)/sow
  me2w=np.dot(e2,wt)/sow
  dum=np.ones(ngals)

  for i in range(nboot): 
      idx = np.random.randint(0,ngals,ngals)   # random array of length ngals
      sow = np.dot(dum[idx],wt[idx])
      e1w[i] = np.dot(e1[idx], wt[idx]) / sow 
      e2w[i] = np.dot(e2[idx], wt[idx]) / sow

  e1_ave[j]=np.mean(e1w)
  e1_err[j]=np.std(e1w)
  e2_ave[j]=np.mean(e2w)
  e2_err[j]=np.std(e2w)

  print (zlo+zhi-0.002)/2.0, ngals_frac[j], e1_ave[j],e1_err[j], e2_ave[j],e2_err[j], ngals, sow


#implement the coefficients of the filter functions needed for COSEBIs
#based on arxiv:1002.2136
#written by Agnes Ferte

import numpy as np 
from mpmath import mp
import mpmath
import argparse

# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"Compute COSEBI weight root/normalisation files in log space", 
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "--thetamin", type=str,required=True,
    help="minimum theta for computation")
parser.add_argument(
    "--thetamax", type=str,required=True,
    help="maximum theta for computation")
parser.add_argument(
    "--nmax", type=int,required=True,
    help="maximum N for cosebis modes")
parser.add_argument(
    "--outputbase", type=str,required=True,
    help="base path for output of weights/roots/normalisations")
parser.add_argument(
    "--dimless", type=bool,required=False, default=False,
    help="Flag for dimensionless cosebis")

## arg parser
args = parser.parse_args()
dimless = args.dimless
mp.dps = 160

#define constants
Nmax = args.nmax
tmin = float(args.thetamin)
tmax = float(args.thetamax)
zmax = mp.log(tmax/tmin)

tbar = (tmax + tmin)/2
BB = (tmax - tmin)/(tmax + tmin)

file_name_prefix = 'tmin'+args.thetamin+'_tmax'+args.thetamax+'_Nmax'+str(Nmax)

### CASE FOR LN(THETA) EVENLY SPACED

##We here compute the c_nj
#compute the Js
def J(k,j,zmax):
    # using the lower gamma function returns an error
    #J = mp.gammainc(j+1,0,-k*zmax)
    # so instead we use the full gamma - gamma upper incomplete
    J = mp.gamma(j+1) - mp.gammainc(j+1,-k*zmax)
    k_power = mp.power(-k,j+1.)
    J = mp.fdiv(J,k_power)
    return J


# matrix of all the coefficient cs 
coeff_j = mp.matrix(Nmax+1,Nmax+2)
# add the constraint that c_n(n+1) is = 1
for i in range(Nmax+1):
    coeff_j[i,i+1] = mp.mpf(1.)


# determining c_10 and c_11
nn = 1
aa = [J(2,0,zmax),J(2,1,zmax)],[J(4,0,zmax),J(4,1,zmax)]
bb = [-J(2,nn+1,zmax),-J(4,nn+1,zmax)]
coeff_j_ini = mp.lu_solve(aa,bb)

coeff_j[1,0] = coeff_j_ini[0]
coeff_j[1,1] = coeff_j_ini[1]

# generalised for all N
# iteration over j up to Nmax solving a system of N+1 equation at each step
# to compute the next coefficient
# using the N-1 orthogonal equations Eq34 and the 2 equations 33

#we start from nn = 2 because we compute the coefficients for nn = 1 above
for nn in np.arange(2,Nmax+1):
    aa = mp.matrix(int(nn+1))
    bb = mp.matrix(int(nn+1),1)
    #orthogonality conditions: equations (34) 
    for m in np.arange(1,nn): 
        #doing a matrix multiplication (seems the easiest this way in mpmath)
        for j in range(0,nn+1):           
            for i in range(0,m+2): 
                if dimless:
                    aa[m-1,j] += J(2,i+j,zmax)*coeff_j[m,i] 
                else:
                    aa[m-1,j] += J(1,i+j,zmax)*coeff_j[m,i] 
            
        for i in range(0,m+2): 
            if dimless:
                bb[int(m-1)] -= J(2,i+nn+1,zmax)*coeff_j[m,i]
            else:    
                bb[int(m-1)] -= J(1,i+nn+1,zmax)*coeff_j[m,i]

    #adding equations (33)
    for j in range(nn+1):
        aa[nn-1,j] = J(2,j,zmax) 
        aa[nn,j]   = J(4,j,zmax) 
        bb[int(nn-1)] = -J(2,nn+1,zmax)
        bb[int(nn)]   = -J(4,nn+1,zmax)

    temp_coeff = mp.lu_solve(aa,bb)
    coeff_j[nn,:len(temp_coeff)] = temp_coeff[:,0].T

#remove the n = 0 line - so now he n^th row is the n-1 mode.
coeff_j = coeff_j[1:,:]
#np.save(file_name_prefix+'_coefficients_tlog',coeff_j)

##We here compute the normalization N_nm, solving equation (35)
Nn = []
for nn in np.arange(1,Nmax+1):
    temp_sum = mp.mpf(0)
    for i in range(nn+2):
        for j in range(nn+2):
            if dimless:
                temp_sum += coeff_j[nn-1,i]*coeff_j[nn-1,j]*J(2,i+j,zmax)
            else:
                temp_sum += coeff_j[nn-1,i]*coeff_j[nn-1,j]*J(1,i+j,zmax)
    if dimless:
        temp_Nn = 1/(temp_sum)
        #N_n chosen to be > 0.  
        temp_Nn = mp.sqrt(mp.fabs(temp_Nn)) * mp.sqrt(tbar**2 * BB / (tmin**2))
    else:
        temp_Nn = (mp.expm1(zmax))/(temp_sum)
        #N_n chosen to be > 0.  
        temp_Nn = mp.sqrt(mp.fabs(temp_Nn))
    Nn.append(temp_Nn)

np.save(args.outputbase+file_name_prefix+'_normalisations_tlog',Nn)

##We now want the root of the filter t_+n^log 
#the filter is: 
rn = []
for nn in range(1,Nmax+1):
    rn.append(mpmath.polyroots(coeff_j[nn-1,:nn+2][::-1],maxsteps=500,extraprec=100))
    #[::-1])
    
rn=np.array(rn,dtype='object')
np.save(args.outputbase+file_name_prefix+'_roots',np.array(rn))

out_norms = 'Normalization_%s-%s.table'%(args.thetamin,args.thetamax)
out_roots = 'Root_%s-%s.table'%(args.thetamin,args.thetamax)

np.set_printoptions(precision=50)

data = rn 

# Output roots file
out_roots = open(args.outputbase+out_roots,'w')
for idx in range(Nmax):
    out_roots.write(
        '%d\t'%(idx+1)+'%0.50f\t'*len(data[idx])%tuple(data[idx])+'\n')

data = Nn

# Output text file
out_norms = open(args.outputbase+out_norms,'w')
for idx in range(Nmax):
    out_norms.write('%d\t%0.50f\n'%(idx+1,data[idx]))



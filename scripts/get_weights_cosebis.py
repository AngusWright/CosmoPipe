import numpy as np
import levin
import matplotlib.pyplot as plt
from mpmath import mp
import mpmath
from scipy.interpolate import interp1d
import multiprocessing as mpi
from scipy.signal import argrelextrema
from numpy import pi,sqrt,exp
from scipy.special import p_roots
from numpy.polynomial.legendre import legcompanion, legval, legder
import numpy.linalg as la

from argparse import ArgumentParser

parser = ArgumentParser(description='Construct Cosebis files for given theta scales')
parser.add_argument("-o", "--outputdir", dest="outputdir",
    help="Output base directory", metavar="outputDir",required=True)
parser.add_argument("-nc", "--ncores", dest="num_cores",type=int,
    help="Number of cores to use in parallelisation", default=8)
parser.add_argument("-nt", "--ntheta", dest="Ntheta",
    help="Number of theta bins", default=1000)
parser.add_argument("-tm", "--tmin", dest="tmin",type=str,
    help="Minimum theta in arcmin", required=True)
parser.add_argument("-tx", "--tmax", dest="tmax",type=str,
    help="Maximum theta in arcmin", required=True)
parser.add_argument("-lm", "--lmin", dest="ell_min",type=float,
    help="Minimum multipole ell in arcmin", default=1)
parser.add_argument("-lx", "--lmax", dest="ell_max",type=float,
    help="Maximum multipole ell in arcmin", default=1e6)
parser.add_argument("-nl", "--nell", dest="Nell",type=int,
    help="Number of multipole ell bins", default=int(1e5))
parser.add_argument("-n", "--nmax", dest="Nmax",type=int,
    help="Maximum number of COSEBIs modes", default=20)
parser.add_argument("-W", "--computeWn", dest="get_W_ell_as_well",type=str,
    help="Compute the Wn's as well?", default="False")
parser.add_argument("-R", "--ReFactor", dest="remove_half",type=str,
    help="Remove the factor of one half from Tn computation?", default="False")
parser.add_argument("-r", "--radians", dest="convert_to_radians",type=str,
    help="Remove the factor of one half from Tn computation?", default="False")
parser.add_argument("-nb", "--nboot", dest="nboot", type=int,
    help="Number of bootstrap realisations for uncertainty estimation", default=200)

args = parser.parse_args()
outputdir = args.outputdir
num_cores = args.num_cores
Ntheta = args.Ntheta
tmin_s = args.tmin
tmax_s = args.tmax
tmin = float(tmin_s)
tmax = float(tmax_s)
ell_min = args.ell_min
ell_max = args.ell_max
Nell = args.Nell
Nmax = args.Nmax
get_W_ell_as_well = args.get_W_ell_as_well == 'True'
remove_half = args.remove_half == 'True'
convert_to_rad = args.convert_to_radians == 'True'

mpi.set_start_method("fork")
mp.dps = 160
arcmintorad = np.pi/180/60

#Convert to radians (needed for Wn!!)
tmin *= arcmintorad
tmax *= arcmintorad


#####################
zmax = mp.log(tmax/tmin)
ell = np.geomspace(ell_min, ell_max, Nell)

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
                aa[m-1,j] += J(1,i+j,zmax)*coeff_j[m,i] 
            
        for i in range(0,m+2): 
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

##We here compute the normalization N_nm, solving equation (35)
Nn = []
for nn in np.arange(1,Nmax+1):
    temp_sum = mp.mpf(0)
    for i in range(nn+2):
        for j in range(nn+2):
            temp_sum += coeff_j[nn-1,i]*coeff_j[nn-1,j]*J(1,i+j,zmax)

    temp_Nn = (mp.expm1(zmax))/(temp_sum)
    #N_n chosen to be > 0.  
    temp_Nn = mp.sqrt(mp.fabs(temp_Nn))
    Nn.append(temp_Nn)


##We now want the root of the filter t_+n^log 
#the filter is: 
rn = []
for nn in range(1,Nmax+1):
    rn.append(mpmath.polyroots(coeff_j[nn-1,:nn+2][::-1],maxsteps=500,extraprec=100))
    #[::-1])



def tplus(tmin,tmax,n,norm,root,ntheta=10000):
    theta=np.logspace(np.log10(tmin),np.log10(tmax),ntheta)
    tplus=np.zeros((ntheta,2))
    tplus[:,0]=theta
    z=np.log(theta/tmin)
    result=1.
    for r in range(n+1):
        result*=(z-root[r])
    result*=norm
    tplus[:,1]=result
    return tplus

def tminus(tmin,tmax,n,norm,root,tp,ntheta=10000):
    tplus_func=interp1d(np.log(tp[:,0]/tmin),tp[:,1])
    rtminus = np.zeros_like(tp)
    rtminus[:,0] = tp[:,0]
    z=np.log(theta/tmin)
    rtminus[:,1]= tplus_func(z)
    lev = levin.Levin(0, 16, 32, 1e-8, 200, num_cores)
    wide_theta = np.linspace(theta[0]*0.999, theta[-1]*1.001,int(1e4))
    lev.init_w_ell(np.log(wide_theta/tmin), np.ones_like(wide_theta)[:,None])
    z=np.log(theta/tmin)
    for i_z, val_z in enumerate(z[1:]):
        y = np.linspace(z[0],val_z, 1000)
        integrand = tplus_func(y)*(np.exp(2*(y-val_z)) - 3*np.exp(4*(y-val_z)))
        limits_at_mode = np.array(y[argrelextrema(integrand, np.less)[0][:]])
        limits_at_mode_append = np.zeros(len(limits_at_mode) + 2)
        if len(limits_at_mode) != 0:
            limits_at_mode_append[1:-1] = limits_at_mode
        limits_at_mode_append[0] = y[0]
        limits_at_mode_append[-1] = y[-1]
        lev.init_integral(y,integrand[:,None],False,False)
        rtminus[i_z, 1] +=  4*lev.cquad_integrate_single_well(limits_at_mode_append,0)[0]
    return rtminus

def get_W_ell(theta, tp):
    lev_w = levin.Levin(0, 16, 32, 1e-8, 200, num_cores)
    lev_w.init_integral(theta,(theta*tp)[:,None]*np.ones(num_cores)[None,:],True,True)
    return lev_w.single_bessel_many_args(ell,0,theta[0],theta[-1])


for nn in range(1,Nmax+1):
    print("At mode",nn)
    n = nn-1
    print("> tplus")
    tpn = tplus(tmin,tmax,nn,Nn[n],rn[n])
    theta = tpn[:,0]
    print("> tminus")
    tmn = tminus(tmin,tmax,1,Nn[n],rn[n], tpn)
    #Convert the radian back to arcmin 
    tpn[:,0] /= arcmintorad
    tmn[:,0] /= arcmintorad

    #If needed, get W_ell
    if get_W_ell_as_well:
        print("> get_W_ell ")
        result_Well = get_W_ell(theta,tpn[:,1])
    if remove_half: 
        print("  > remove half")
        tpn[:,1] /= 2
        tmn[:,1] /= 2 

    #Setup output file names 
    if remove_half: 
        file_tpn = "%s/Tplus/Tp_%s-%s_%d.table"%(outputdir,tmin_s,tmax_s,nn)
        file_tmn = "%s/Tminus/Tm_%s-%s_%d.table"%(outputdir,tmin_s,tmax_s,nn)
    else: 
        file_tpn = "%s/Tplus/Tp_%s-%s_%d.table"%(outputdir,tmin_s,tmax_s,nn)
        file_tmn = "%s/Tminus/Tm_%s-%s_%d.table"%(outputdir,tmin_s,tmax_s,nn)
    file_Wn = "%s/WnLog/WnLog_%s-%s_%d.table"%(outputdir,tmin_s,tmax_s,nn)
    file_Wn2 = "%s/WnLog/WnLog%d-%s-%s.table"%(outputdir,nn,tmin_s,tmax_s)

    print("> save Tplus")
    np.savetxt(file_tpn,tpn)
    print("> save Tminus")
    np.savetxt(file_tmn,tmn)    
    if get_W_ell_as_well:
        print("> save Wn")
        np.savetxt(file_Wn, np.array([np.log(ell),result_Well]).T)
        print("> save Wn2")
        np.savetxt(file_Wn2, np.array([np.log(ell),result_Well]).T)
        

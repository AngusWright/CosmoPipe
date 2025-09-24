import numpy as np
from scipy.interpolate import interp1d
from scipy.special.orthogonal import p_roots
from scipy.integrate import quad


def str2bool(v):
    if isinstance(v, bool):
       return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

# calculates T_plus logarithmic functions for COSEBIs
def tplus(tmin,tmax,n,norm,root,ntheta=10000):
    theta=np.logspace(np.log10(tmin),np.log10(tmax),ntheta)
    # 
    tplus=np.zeros((ntheta,2))
    tplus[:,0]=theta
    z=np.log(theta/tmin)
    result=1.
    for r in range(n+1):
        result*=(z-root[r])
# 
    result*=norm
    tplus[:,1]=result
    return tplus

# integrant for T_minus
def tminus_integ(y,z,tplus_func):
    return 4.*tplus_func(y)*(np.exp(2.*(y-z))-3.*np.exp(4.*(y-z)))

# T_minus using Gauss-Legendre integration
def tminus(tmin,tmax,n,norm,root,tp,ntheta=10000,nG=20):
    tplus_func=interp1d(np.log(tp[:,0]/tmin),tp[:,1])
    theta=np.logspace(np.log10(tmin),np.log10(tmax),ntheta)
    # 
    tminus=np.zeros((ntheta,2))
    tminus[:,0]=theta
    z=np.log(theta/tmin)
    tminus[:,1]=tplus_func(z)
    [x,w] = p_roots(nG+1)
    integ_limits=np.insert(root/tmin,0,0)
    for iz in range(len(z)):
        result=0.
        good_integ=(integ_limits<=z[iz])
        integ_limits_good=integ_limits[good_integ]
        for il in range(1,len(integ_limits_good)):
            delta_limit=integ_limits_good[il]-integ_limits_good[il-1]
            y_in=0.5*delta_limit*x+0.5*(integ_limits_good[il]+integ_limits_good[il-1])
            y=y_in[y_in>=0.]
            result+=delta_limit*0.5*sum(w[y_in>=0.]*tminus_integ(y,z[iz],tplus_func))
        delta_limit=z[iz]-integ_limits_good[-1]
        y_in=x*(delta_limit*0.5)+(z[iz]+integ_limits_good[-1])*0.5
        y=y_in[y_in>=0.]
        result+=delta_limit*0.5*sum(w[y_in>=0.]*tminus_integ(y,z[iz],tplus_func))
        tminus[iz,1]+=result
    return tminus

# tminus using quad integration
def tminus_quad(tmin,tmax,n,norm,root,tp,ntheta=10000):
    tplus_func=interp1d(np.log(tp[:,0]/tmin),tp[:,1])
    theta=np.logspace(np.log10(tmin),np.log10(tmax),ntheta)
    # 
    tminus=np.zeros((ntheta,2))
    tminus[:,0]=theta
    z=np.log(theta/tmin)
    tminus[:,1]=tplus_func(z)
    integ_limits=np.insert(root,0,0)
    for iz in range(len(z)):
        good_integ=(integ_limits<=z[iz])
        integ_limits_good=integ_limits[good_integ]
        for il in range(1,len(integ_limits_good)):
            result=quad(tminus_integ,integ_limits[il-1] , integ_limits[il], args=(z[iz],tplus_func))
            tminus[iz,1]+=result[0]
        result=quad(tminus_integ,integ_limits[len(integ_limits_good)-1] ,z[iz], args=(z[iz],tplus_func))
        tminus[iz,1]+=result[0]
    return tminus

def integ_xi(xi_func,theta_edges, ntheta):
    ix=np.linspace(0,ntheta-1,ntheta)
    xip_integrated=np.zeros(len(theta_edges)-1)
    for tbin in range(len(theta_edges)-1):
        theta_in_range=np.exp(np.log(theta_edges[tbin])+(np.log(theta_edges[tbin+1])-np.log(theta_edges[tbin]))/(ntheta)*(ix+0.5))
        xip_integrated[tbin]=sum(xi_func(theta_in_range)*theta_in_range)/sum(theta_in_range)
    return xip_integrated


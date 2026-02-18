#=========================================
#
# File Name : project_shapes.py
# Created By : awright
# Creation Date : 02-02-2026
# Last Modified : Wed Feb 18 09:51:22 2026
#
#=========================================

import numpy as np
import pandas as pd
import pyarrow.parquet as pq
import astropy.io.fits as aif
from astropy.table import Table
import mcal_functions as mcf 
import argparse

def e_to_g(e1, e2):
    """
    Converts e-type shears to g-type
    
    Parameters
    ==========
    e1: float or np.ndarray
    e2: float or np.ndarray
    
    Returns
    =======
    g1: float or np.ndarray
    g2: float or np.ndarray
    """
    fac = 1 / (1 + np.sqrt(1 - e1**2 - e2**2))
    return e1*fac, e2*fac


def g_to_e(g1, g2):
    """
    Converts g-type shears to e-type
    
    Parameters
    ==========
    g1: float or np.ndarray
    g2: float or np.ndarray
    
    Returns
    =======
    e1: float or np.ndarray
    e2: float or np.ndarray
    """
    
    fac = 2 / (1 + g1**2 + g2**2)
    return g1*fac, g2*fac


def shear_to_matrix(e1, e2):
    """
    Given e1 and e2, returns a shear matrix. If e1 and e2 are np.ndarrays, returns a (nx2x2) array of shear matrices
    """
    
    # Ensure inputs are np.ndarrays
    e1 = np.asarray(e1)
    e2 = np.asarray(e2)
    
    m = np.asarray([[1 + e1, e2], [e2, 1 - e1]])
    if m.ndim not in (2, 3):
                raise ValueError(f"Unexpected number of dimensions of shear matrix: {m.ndim}")
    
    if m.ndim == 3:
                m = np.transpose(m, (2, 0, 1))
    
    return m


def matrix_to_shear(m):
    """
    Given a shear matrix (or nx2x2 ndarray of n shear matrices), returns e1 and e2
    """
    
    # Ensure input is np.ndarray
    m = np.asarray(m)
    
    # the ellipsis here means that if m is nx2x2 it returns a list of length n. If it's 2x2, returns a single value
    m00 = m[..., 0, 0]
    m11 = m[..., 1, 1]
    m01 = m[..., 0, 1]
    
    tr = m00 + m11
    e1 = (m00 - m11) / tr
    e2 = 2 * m01 / tr
    
    return e1, e2


def _jacobian_transpose(j):
    """
    Returns the transpose of a jacobian matrix.
    If it's a list of jacobians, makes sure to only transpose the last two axes
    """
    return j.swapaxes(-1, -2)


def world_to_det(g1, g2, jacobian):
    """Given g1, g2 in world frame, and a jacobian, returns them in detector frame"""
    
    m_world = shear_to_matrix(*g_to_e(g1, g2))
    jinv = np.linalg.inv(jacobian)
    m_det = jinv @ m_world @ _jacobian_transpose(jinv)
    
    return e_to_g(*matrix_to_shear(m_det))


def det_to_world(g1, g2, jacobian):
    """Given g1, g2 in detector frame, and a jacobian, returns them in world frame"""
    
    m_det = shear_to_matrix(*g_to_e(g1, g2))
    m_world = jacobian @ m_det @ _jacobian_transpose(jacobian)
    
    return e_to_g(*matrix_to_shear(m_world))


#  -i ${current} \
#  -o ${outputname} \
#  --e1name_det @BV:E1DETNAME@ \
#  --e2name_det @BV:E2DETNAME@ \
#  --e1name @BV:E1NAME@ \
#  --e2name @BV:E2NAME@ \
#  --jacobians @BV:JACOBIANS@ 2>&1 
# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"Calculate a projected ellipticity from an input catalogue and jacobians",
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "-i", type=str,
    help="the in path for the catalogue.")
parser.add_argument(
    "-o", type=str, 
    help="the output path for the final catalogue") 
parser.add_argument(
    "--e1name", type=str,
    help="column for the e1 variable in world coordinates.")
parser.add_argument(
    "--e2name", type=str,
    help="column for the e2 variable in world coordinates.")
parser.add_argument(
    "--e1name_det", type=str,
    help="column for the e1 variable in detector coordinates.")
parser.add_argument(
    "--e2name_det", type=str,
    help="column for the e2 variable in detector coordinates.")
parser.add_argument(
    "--id", type=str,
    help="column for the id variable in both catalogues")
parser.add_argument(
    "--jacobians", type=str, 
    help="the file containing the jacobians") 

## arg parser
args = parser.parse_args()

print("arguments")
print(args)


datafile_jacobian=args.jacobians #"../TR1_v1.1/intermediate_cats/euclid_tr1_ad_v1.1_24044.parquet"
datafile_shapes=args.i #"../TR1_v1.1/intermediate_cats/euclid_tr1_abd_v1.1_24028_sel.parquet"
datafile_shapes_out=args.o #"../TR1_v1.1/intermediate_cats/euclid_tr1_abd_v1.1_24028_sel_fov.parquet"

#Read catalogue (keeping as LDAC)
data_shapes, ldac_cat = mcf.flexible_read(datafile_shapes,as_df=False)

data_Jacobian=Table.read(datafile_jacobian)
data_Jacobian=data_Jacobian[np.isin(data_Jacobian[args.id],data_shapes[args.id])]
#data_shapes=Table.read(datafile_shapes)
ind1=np.argsort(data_Jacobian[args.id])
ind2=np.argsort(data_shapes[args.id])

stat=np.any(data_Jacobian[args.id][ind1]!=data_shapes[args.id][ind2]) 

if stat == True : 
    raise ValueError("ERROR: object id sort did not work")
else: 
    jacobians = data_Jacobian['jacobian']
    jacobian_matrices = np.array([np.reshape(j, (2, 2)) for j in jacobians])
    print(jacobian_matrices.shape)
    print(len(data_shapes))
    e1_det = data_shapes[args.e1name_det]
    e2_det = data_shapes[args.e2name_det]
    e1_ord, e2_ord = det_to_world(e1_det[ind2], e2_det[ind2], jacobian_matrices[ind1])
    e1=np.zeros(len(e1_ord))
    e1[ind2]=e1_ord
    e2=np.zeros(len(e2_ord))
    e2[ind2]=e2_ord
    
    print(data_shapes[args.e1name_det])
    print(data_shapes[args.e2name_det])
    print(e1)
    print(e2)
    
    df_out = pd.DataFrame(index=range(len(data_shapes['SeqNr'])))
    df_out['SeqNr']=data_shapes['SeqNr']

    df_out[args.e1name]=e1
    df_out[args.e2name]=e2
    
    #data_shapes.write(datafile_shapes_out)
    #mcf.flexible_write(data_shapes,datafile_shapes_out,ldac_cat)
    
    table = Table.from_pandas(df_out)
    hdu=aif.BinTableHDU(data=table, name='OBJECTS')
    hdu.writeto(datafile_shapes_out, overwrite=True)




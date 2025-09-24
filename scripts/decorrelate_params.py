import numpy as np
from argparse import ArgumentParser

parser = ArgumentParser(description='Construct a decorrelated parameter file')
parser.add_argument('--means', dest='means_file', type=str, required=True, help="mean values file")
parser.add_argument('--cov', dest='cov_file', type=str, required=True, help="covariance file")
parser.add_argument('--output', dest='output', type=str, required=True, help="output file")

args = parser.parse_args()

file=open(args.means_file)
delta_p=np.loadtxt(file,comments='#')


file=open(args.cov_file)
cov_p=np.atleast_2d(np.loadtxt(file,comments='#'))

L = np.linalg.cholesky(cov_p)
inv_L = np.linalg.inv(L)
delta_x = np.dot(inv_L,delta_p)

np.savetxt(args.output,delta_x)

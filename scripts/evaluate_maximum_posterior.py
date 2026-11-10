from argparse import ArgumentParser
import numpy as np
# import pandas as pd
# import scipy.optimize
from mcmc_tools import load_chain_simple
from cosmosis.runtime.pipeline import LikelihoodPipeline
from cosmosis.runtime.config import Inifile

parser = ArgumentParser(description='Check maximum posterior')
parser.add_argument("--inputchain", dest="inputchain",
    help="Input chain ",required=False, type=str)
parser.add_argument("--inifile", dest="inifile",
    help="Cosmosis ini file",required=True, type=str)
parser.add_argument("--data_file_iterative", dest="data_file_iterative",
    help="Fits file containing iterative covariance matrix",required=True, type=str)
parser.add_argument("--outputdir", dest="outputdir",
    help="Output directory",required=True, type=str)
parser.add_argument("--iteration", dest="iteration",
    help="Number of covariance iteration",required=True, type=int)
parser.add_argument("--chainsuffix", dest="chainsuffix",
    help="Chainsuffix",required=False, default='', type=str)

args = parser.parse_args()
inifile = args.inifile
outputdir = args.outputdir
data_file_iterative = args.data_file_iterative
inputchain = args.inputchain
iteration = args.iteration
chainsuffix=args.chainsuffix

ini_default = Inifile(inifile)
ini_iterative = Inifile(inifile)
ini_iterative.set('DEFAULT', 'data_file', data_file_iterative)
# Set up cosmosis pipeline
pipeline = LikelihoodPipeline(ini_default) 
pipeline_iterative = LikelihoodPipeline(ini_iterative) 
# Get varied parameters
varied_parameters = pipeline.varied_params
varied_params = ['%s--%s'%(p.section, p.name) for p in varied_parameters]

if inputchain:
    chain = load_chain_simple(inputchain)
    # Find maximum posterior
    maxpost = np.argmax(chain['post'])
    start_values = chain[varied_params].loc[maxpost].to_numpy()
else:
    print('Starting optimisation from values file')
    start_values = pipeline.start_vector()

results = pipeline.run_results(start_values)
results_iterative = pipeline_iterative.run_results(start_values)

# Evaluate with fiducial covariance
chi2 = -2*results.like
post = -2*results.post
# Evaluate with iterative covariance
chi2_iterative = -2*results_iterative.like
post_iterative = -2*results_iterative.post

print('Best fit chi2: %f'%chi2)
print('Best fit chi2 with iterative covariance: %f'%chi2_iterative)

np.savetxt(outputdir+'bestfit%s_chi2_post_iterative_evaluated_%d.txt'%(chainsuffix,iteration), np.array([[chi2, post],[chi2_iterative, post_iterative]]))

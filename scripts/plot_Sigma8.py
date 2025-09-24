from argparse import ArgumentParser
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from mcmc_tools import load_chain, cosmosis_names, latex_names
from matplotlib.patches import Rectangle
from chainconsumer import ChainConsumer
from matplotlib import colors as mcolors
from scipy.optimize import curve_fit
from statsmodels.stats.weightstats import DescrStatsW
colors = dict(mcolors.BASE_COLORS, **mcolors.CSS4_COLORS)

def sigma8_func(Om, alpha,Sig_8):
    return (0.3/Om)**alpha*Sig_8
def Sig8_func(Om, sigma8,alpha):
    return (Om/0.3)**alpha*sigma8

parser = ArgumentParser(description='Plot Sigma_8')
parser.add_argument("--inputfile", dest="inputfile",
    help="Input file", required=False, type=str)
parser.add_argument("--outputfile", dest="outputfile",
    help="Output file", required=True, type=str)
parser.add_argument("--statistic", dest="statistic",
    help="Summary statistic", required=True, type=str)

args = parser.parse_args()
inputfile = args.inputfile
outputfile = args.outputfile
statistic = args.statistic
chain = load_chain(inputfile)
idx = chain[0]['weight']>0.
chain = chain[0][idx].reset_index(),chain[1]

parameters = ['Omega_m', 'sigma_8']
cosmosis_parameters = [cosmosis_names[p] for p in parameters]
latex_parameters = [latex_names[p] for p in parameters]

# some plotting settings
leg1=Rectangle((0,0),0,0,alpha=0.0)
if statistic == 'cosebis':
    colour = colors['darkorange']
elif statistic == 'bandpowers':
    colour = colors['hotpink']
elif statistic == 'xipm':
    colour = colors['darkturquoise']
else:
    raise Exception('Statistic not implemented: %s'%statistic)

fig, ax = plt.subplots(nrows=2, ncols=1, figsize=(5, 8), sharex=True, sharey='row')
plt.subplots_adjust(wspace=0, hspace=0)
plt.locator_params(axis='y', nbins=5)
plt.locator_params(axis='x', nbins=4)

c = ChainConsumer()
c.add_chain(chain[0][cosmosis_parameters].to_numpy(),weights=chain[0]['weight'],color=colour, parameters=latex_parameters,kde=1.5 ,shade=True,name='',shade_alpha=0.8)
c.configure(plot_hists=False,shade_gradient=1.0,diagonal_tick_labels=False,label_font_size=14,tick_font_size=13,serif=True,legend_color_text=True,linewidths=1.5,statistics="mean")
c.plotter.plot_contour(ax[0],latex_parameters[0],latex_parameters[1])

omegam = chain[0][cosmosis_names['Omega_m']]
sigma8 = chain[0][cosmosis_names['sigma_8']]
stats_omegam = DescrStatsW(data=omegam, weights=chain[0]['weight'])
stats_sigma8 = DescrStatsW(data=sigma8, weights=chain[0]['weight'])
OmRange = stats_omegam.quantile(probs=np.array([0.01, 0.99]), return_pandas=False)
sigma8Range = stats_sigma8.quantile(probs=np.array([0.01, 0.99]), return_pandas=False)
# find a fit to the cosmic banana and draw the fittted line
sigma = 1/chain[0]['weight']
N=2
M=len(sigma)
popt, pcov = curve_fit(sigma8_func, omegam, sigma8,sigma=sigma)
alpha=popt[0]
perr=np.sqrt(np.diag(pcov)) 
print('alpha ='+ '%0.3f' % alpha + ' err = '+ '%0.4f' % perr[0])
xarr=np.linspace(0.9*OmRange[0] , 1.1*OmRange[1] , 50)
yarr=sigma8_func(xarr,popt[0],popt[1])
ax[0].set_xlim(0.9*OmRange[0],1.1*OmRange[1])
ax[0].set_ylim(0.9*sigma8Range[0],1.1*sigma8Range[1])
ax[0].plot(xarr,yarr,'k--',label=r'$\alpha=$'+ '%0.3f' % alpha)
ax[0].set_ylabel(latex_parameters[1])
ax[0].legend(loc='best')

# Plot Sigma_8
Sig8 = Sig8_func(omegam,sigma8,alpha)
stats_Sig8 = DescrStatsW(data=Sig8, weights=chain[0]['weight'])
Sig8Range = stats_Sig8.quantile(probs=np.array([0.01, 0.99]), return_pandas=False)
chain_Sig8 = np.transpose(np.vstack((omegam,Sig8)))
c = ChainConsumer()
c.add_chain(chain_Sig8,weights=chain[0]['weight'],color=colour, parameters=[latex_parameters[0],r'$\Sigma_8$'],kde=1.5 ,shade=True,name='',shade_alpha=0.8)
c.configure(plot_hists=False,shade_gradient=1.0,diagonal_tick_labels=False,label_font_size=14,tick_font_size=13,serif=True,legend_color_text=True,linewidths=1.5,statistics="mean")
c.plotter.plot_contour(ax[1],latex_parameters[0],r'$\Sigma_8$')
ax[1].set_xlabel(latex_parameters[0])
ax[1].set_ylim(0.98*Sig8Range[0],1.02*Sig8Range[1])
ax[1].set_ylabel(r'$\Sigma_8=\sigma_8(\Omega_{\rm m}/0.3)^\alpha$')

plt.savefig(outputfile)
plt.close()



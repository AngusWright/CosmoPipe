from argparse import ArgumentParser
import numpy as np
import astropy.io.fits as fits
from scipy import stats
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
import matplotlib.pylab as pl
from matplotlib.font_manager import FontProperties
from matplotlib.ticker import ScalarFormatter


if __name__ == '__main__':

    parser = ArgumentParser(description='Plot data vectors with python')
    parser.add_argument("--inputfile", dest="inputfile",
        help="Input file", required=True)
    parser.add_argument("--statistic", dest="statistic",
        help="Statistic", required=True)
    parser.add_argument("--ntomo", dest="ntomo", type=int,
        help="Number of tomographic bins", metavar="output",required=True)
    parser.add_argument("--nlens", dest="nlens", type=int,
        help="Number of lens bins", metavar="output",required=True)
    parser.add_argument("--nobs", dest="nobs", type=int,
        help="Number of observable bins", metavar="output",required=True)
    parser.add_argument("--thetamin_ee", dest="thetamin_ee", type=float,
        help="Minimum theta", metavar="output",required=True)
    parser.add_argument("--thetamax_ee", dest="thetamax_ee", type=float,
        help="Maximum theta", metavar="output",required=True)
    parser.add_argument("--thetamin_ne", dest="thetamin_ne", type=float,
        help="Minimum theta", metavar="output",required=True)
    parser.add_argument("--thetamax_ne", dest="thetamax_ne", type=float,
        help="Maximum theta", metavar="output",required=True)
    parser.add_argument("--thetamin_nn", dest="thetamin_nn", type=float,
        help="Minimum theta", metavar="output",required=True)
    parser.add_argument("--thetamax_nn", dest="thetamax_nn", type=float,
        help="Maximum theta", metavar="output",required=True)
    parser.add_argument("--output_dir", dest="output_dir",
        help="Output directory", metavar="output",required=True)
    parser.add_argument("--title", dest="title",
        help="Plot title", metavar="title",required=True)
    parser.add_argument("--suffix", dest="suffix",
        help="Plot title suffix", metavar="suffix",required=True)
    parser.add_argument("--ee", dest="ee",
        help="shear-shear", metavar="ee", type=str, required=True)
    parser.add_argument("--ne", dest="ne",
        help="shear-shear", metavar="ne", type=str, required=True)
    parser.add_argument("--nn", dest="nn",
        help="shear-shear", metavar="nn", type=str, required=True)
    parser.add_argument("--obs", dest="obs",
        help="shear-shear", metavar="obs", type=str, required=True)
    
    args = parser.parse_args()
    inputfile = args.inputfile
    statistic = args.statistic
    ntomo = args.ntomo
    nlens = args.nlens
    nobs = args.nobs
    thetamin_ee = args.thetamin_ee
    thetamax_ee = args.thetamax_ee
    thetamin_ne = args.thetamin_ne
    thetamax_ne = args.thetamax_ne
    thetamin_nn = args.thetamin_nn
    thetamax_nn = args.thetamax_nn
    output_dir = args.output_dir
    title = args.title
    suffix = args.suffix
    ee = args.ee
    ne = args.ne
    nn = args.nn
    obs = args.obs
    
    ee = ee.lower() in ["true","t","1","y","yes"]
    ne = ne.lower() in ["true","t","1","y","yes"]
    nn = nn.lower() in ["true","t","1","y","yes"]
    obs = obs.lower() in ["true","t","1","y","yes"]
    
    if statistic == 'cosebis':
        if ee:
            extension_eeE = 'En'
            extension_eeB = 'Bn'
            ylabel_eeE = r'$E_{\mathrm{n}}[10^{-10}{\mathrm{rad}}^2]$'
            ylabel_eeB = r'$B_{\mathrm{n}}[10^{-10}{\mathrm{rad}}^2]$'
            xlabel = r'n'
            xscale = 'linear'
            scaling_ee = 1e10
            statistic_mm = 'cosebis'
        if ne:
            extension_neE = 'Psi_gm'
            extension_neB = ''
            ylabel_neE = r'$\Psi_{\mathrm{gm,n}}[10^{-10}{\mathrm{rad}}^2]$'
            ylabel_neB = r'$\Psi_{\mathrm{gm,n}}[10^{-10}{\mathrm{rad}}^2]$'
            xlabel = r'n'
            xscale = 'linear'
            scaling_ne = 1e8
            statistic_gm = 'psi stats'
        if nn:
            extension_nn = 'Psi_gg'
            ylabel_nn = r'$\Psi_{\mathrm{gg,n}}[10^{-10}{\mathrm{rad}}^2]$'
            xlabel = r'n'
            xscale = 'linear'
            scaling_nn = 1e6
            statistic_gg = 'psi stats'
    if statistic == 'bandpowers':
        if ee:
            extension_eeE = 'PeeE'
            extension_eeB = 'PeeB'
            ylabel_eeE = r'$\mathcal{C}_{\mathrm{EE}}(\ell)/\ell\;[10^{-7}]$'
            ylabel_eeB = r'$\mathcal{C}_{\mathrm{BB}}(\ell)/\ell\;[10^{-7}]$'
            xlabel = r'$\ell$'
            xscale = 'log'
            scaling_ee = 1e7
            statistic_mm = 'bandpowers'
        if ne:
            extension_neE = 'PneE'
            extension_neB = 'PneB'
            ylabel_neE = r'$\mathcal{C}_{\mathrm{NE}}(\ell)/\ell\;[10^{-7}]$'
            ylabel_neB = r'$\mathcal{C}_{\mathrm{NB}}(\ell)/\ell\;[10^{-7}]$'
            xlabel = r'$\ell$'
            xscale = 'log'
            scaling_ne = 1e5
            statistic_gm = 'bandpowers'
        if nn:
            extension_nn = 'Pnn'
            ylabel_nn = r'$\mathcal{C}_{\mathrm{NN}}(\ell)/\ell\;[10^{-7}]$'
            xlabel = r'$\ell$'
            xscale = 'log'
            scaling_nn = 1e3
            statistic_gg = 'bandpowers'
    if (statistic == 'xiE') or (statistic == 'xiB') or (statistic == '2pcf'):
        if ee:
            extension_eeE = 'xip'
            extension_eeB = 'xim'
            if statistic == '2pcf':
                ylabel_eeE = r'$\theta\xi_+[10^{-4}{\mathrm{arcmin}}]$'
                ylabel_eeB = r'$\theta\xi_-[10^{-4}{\mathrm{arcmin}}]$'
                statistic_mm = 'xipm'
            if statistic == 'xiE':
                ylabel_eeE = r'$\theta\xi^{\mathrm{E}}_+[10^{-4}{\mathrm{arcmin}}]$'
                ylabel_eeB = r'$\theta\xi^{\mathrm{E}}_-[10^{-4}{\mathrm{arcmin}}]$'
                statistic_mm = 'xiE'
            if statistic == 'xiB':
                ylabel_eeE = r'$\theta\xi^{\mathrm{B}}_+[10^{-4}{\mathrm{arcmin}}]$'
                ylabel_eeB = r'$\theta\xi^{\mathrm{B}}_-[10^{-4}{\mathrm{arcmin}}]$'
                statistic_mm = 'xiB'
            xlabel = r'$\theta$'
            xscale = 'log'
            scaling_ee = 1e4
        if ne:
            extension_neE = 'gammat'
            extension_neB = 'gammax'
            ylabel_neE = r'$\theta\gamma_{\mathrm{t}}[10^{-4}{\mathrm{arcmin}}]$'
            ylabel_neB = r'$\theta\gamma_{\mathrm{x}}[10^{-4}{\mathrm{arcmin}}]$'
            xlabel = r'$\theta$'
            xscale = 'log'
            scaling_ne = 1e4
            statistic_gm = 'gamma_t'
        if nn:
            extension_nn = 'wtheta'
            ylabel_nn = r'$\theta w(\theta)[10^{0}{\mathrm{arcmin}}]$'
            xlabel = r'$\theta$'
            xscale = 'log'
            scaling_nn = 1
            statistic_gg = 'w'
    if obs:
        extension_obs = '1pt'
        ylabel_obs = r'$\phi (\mathrm{dex}^{-1}\,h^{3}\,\mathrm{Mpc}^{-3})$'
        xlabel_obs = r'$\log(M_{\star}/h^{2}M_{\odot})$'
        xscale_obs = 'log'
        yscale_obs = 'log'
        scaling_obs = 1
    
    with fits.open(inputfile) as f:
        n_data_ee = 0
        n_data_bb = 0
        n_data_ne = 0
        n_data_nb = 0
        n_data_nn = 0
        if nn:
            nn_data = f[extension_nn].data
            n_data_nn = len(nn_data)
            nn_cov = f['COVMAT'].data[0:n_data_nn,:][:,0:n_data_nn]
            nn_std = np.sqrt(np.diag(nn_cov))
        if ne:
            neE_data = f[extension_neE].data
            n_data_ne = len(neE_data)
            neE_cov = f['COVMAT'].data[n_data_nn:n_data_nn+n_data_ne,:][:,n_data_nn:n_data_nn+n_data_ne]
            neE_std = np.sqrt(np.diag(neE_cov))
            try:
                neB_data = f[extension_neB].data
                n_data_nb = len(neB_data)
                neB_cov = f['COVMAT'].data[n_data_nn+n_data_ne:n_data_nn+n_data_ne+n_data_nb,:][:,n_data_nn+n_data_ne:n_data_nn+n_data_ne+n_data_nb]
                neB_std = np.sqrt(np.diag(neB_cov))
            except:
                neB_data = None
                neb_cov = None
                neb_std = None
        if ee:
            eeE_data = f[extension_eeE].data
            n_data_ee = len(eeE_data)
            eeE_cov = f['COVMAT'].data[n_data_nn+n_data_ne+n_data_nb:n_data_nn+n_data_ne+n_data_nb+n_data_ee,:][:,n_data_nn+n_data_ne+n_data_nb:n_data_nn+n_data_ne+n_data_nb+n_data_ee]
            eeE_std = np.sqrt(np.diag(eeE_cov))
            try:
                eeB_data = f[extension_eeB].data
                n_data_bb = len(eeB_data)
                eeB_cov = f['COVMAT'].data[n_data_nn+n_data_ne+n_data_nb+n_data_ee:n_data_nn+n_data_ne+n_data_nb+n_data_ee+n_data_bb,:][:,n_data_nn+n_data_ne+n_data_nb+n_data_ee:n_data_nn+n_data_ne+n_data_nb+n_data_ee+n_data_bb]
                eeB_std = np.sqrt(np.diag(eeB_cov))
            except:
                eeB_data = None
                eeB_cov = None
                eeB_std = None
        if obs:
            obs_data = f[extension_obs].data
            bins_obs = np.array([len(obs_data[f'ANG{i+1}']) for i in range(nobs)])
            n_data_obs = np.sum(bins_obs)
            print(bins_obs, n_data_obs)
            obs_cov = f['COVMAT'].data[n_data_nn+n_data_ne+n_data_nb+n_data_ee+n_data_bb:n_data_nn+n_data_ne+n_data_nb+n_data_ee+n_data_bb+n_data_obs,:][:,n_data_nn+n_data_ne+n_data_nb+n_data_ee+n_data_bb:n_data_nn+n_data_ne+n_data_nb+n_data_ee+n_data_bb+n_data_obs]
            obs_std = np.sqrt(np.diag(obs_cov))
            print(obs_cov.shape)
            print(obs_std.shape)

    
    if (statistic == 'xiE') or (statistic == 'xiB'):
        if ee:
            ymax_eeE = np.max(eeE_data['ANG']*eeE_data['VALUE']*scaling_ee*1.3)
            ymin_eeE = np.min(eeE_data['ANG']*eeE_data['VALUE']*scaling_ee*1.3)
            if eeB_data is not None:
                ymax_eeB = np.max(eeB_data['ANG']*eeB_data['VALUE']*scaling_ee*1.3)
                ymin_eeB = np.min(eeB_data['ANG']*eeB_data['VALUE']*scaling_ee*1.3)
    elif statistic == 'bandpowers':
        if ee:
            ymax_eeE = np.max(eeE_data['VALUE']/eeE_data['ANG']*scaling_ee*1.3)
            ymin_eeE = np.min(eeE_data['VALUE']/eeE_data['ANG']*scaling_ee*1.3)
            if eeB_data is not None:
                ymax_eeB = np.max(eeB_data['VALUE']/eeB_data['ANG']*scaling_ee*1.3)
                ymin_eeB = np.min(eeB_data['VALUE']/eeB_data['ANG']*scaling_ee*1.3)
        if ne:
            ymax_neE = np.max(neE_data['VALUE']/neE_data['ANG']*scaling_ne*1.3)
            ymin_neE = np.min(neE_data['VALUE']/neE_data['ANG']*scaling_ne*1.3)
            if neB_data is not None:
                ymax_neB = np.max(neB_data['VALUE']/neB_data['ANG']*scaling_ne*1.3)
                ymin_neB = np.min(neB_data['VALUE']/neB_data['ANG']*scaling_ne*1.3)
        if nn:
            ymax_nn = np.max(nn_data['VALUE']/nn_data['ANG']*scaling_nn*1.3)
            ymin_nb = np.min(nn_data['VALUE']/nn_data['ANG']*scaling_nn*1.3)
    else:
        if ee:
            ymax_eeE = np.max(eeE_data['ANG']*eeE_data['VALUE']*scaling_ee*1.3)
            ymin_eeE = np.min(eeE_data['ANG']*eeE_data['VALUE']*scaling_ee*1.3)
            if eeB_data is not None:
                ymax_eeB = np.max(eeB_data['ANG']*eeB_data['VALUE']*scaling_ee*1.3)
                ymin_eeB = np.min(eeB_data['ANG']*eeB_data['VALUE']*scaling_ee*1.3)
        if ne:
            ymax_neE = np.max(neE_data['ANG']*neE_data['VALUE']*scaling_ne*1.3)
            ymin_neE = np.min(neE_data['ANG']*neE_data['VALUE']*scaling_ne*1.3)
            if neB_data is not None:
                ymax_neB = np.max(neB_data['ANG']*neB_data['VALUE']*scaling_ne*1.3)
                ymin_neB = np.min(neB_data['ANG']*neB_data['VALUE']*scaling_ne*1.3)
        if nn:
            ymax_nn = np.max(nn_data['ANG']*nn_data['VALUE']*scaling_nn*1.3)
            ymin_nn = np.min(nn_data['ANG']*nn_data['VALUE']*scaling_nn*1.3)
    
    if ee:
        n_combinations_ee = int(ntomo*(ntomo+1)/2)
        n_data_per_bin_ee = int(n_data_ee / n_combinations_ee)
    
    if ne:
        n_combinations_ne = nlens*ntomo
        n_data_per_bin_ne = int(n_data_ne / n_combinations_ne)
    
    if nn:
        n_combinations_nn = nlens # Currently only auto correlations
        n_data_per_bin_nn = int(n_data_nn / n_combinations_nn)
    if obs:
        obs_x = []
        obs_y = []
        obs_err = []
        id = 0
        for i in range(nobs):
            obs_x.append(obs_data[f'ANG{i+1}'])
            obs_y.append(obs_data[f'VALUE{i+1}'])
            obs_err.append(obs_std[id:id+bins_obs[i]])
            id += bins_obs[i]
        xmax_obs = np.max(obs_x)
        xmin_obs = np.min(obs_x)
        ymax_obs = np.max(obs_y)
        ymin_obs = np.min(obs_y)
    
    if ee:
        # plotting sizes
        pl.rcParams.update(pl.rcParamsDefault)
        yprops=dict(rotation=90, horizontalalignment='center', verticalalignment='center', x=10, labelpad=20, fontsize=15)
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        formatter = ScalarFormatter(useMathText=True)
        formatter.set_scientific(True)
        fig_width_pt = 246.0*3.5 # Get this from LaTex using \the\columnwidth
        inches_per_pt = 1.0/72.27
        golden_mean = (np.sqrt(5)-1.0)/2.0
        fig_width  = 2.5#fig_width_pt*inches_per_pt # width in inches
        fig_height = fig_width#/golden_mean # height in inches
        fig_size = [fig_width*ntomo, fig_height*ntomo]
        fontsize=15
        params = {'axes.labelsize':15,
                'font.size':10,
                'legend.fontsize':17,
                'xtick.labelsize':12,
                'ytick.labelsize':12,
                'figure.figsize':fig_size,
                'font.family': 'serif'}
        pl.rcParams.update(params)
        pl.rc('text', usetex=True)
        pl.subplots_adjust(wspace=0.075, hspace=0.075) # you can add spaces between the block here
        pl.clf()
        fig = pl.figure()#1, figsize = (fig_width, fig_height*1.5))
        pl.clf()
        # Plotting
        for bin1 in range(1, ntomo+1):
            for bin2 in range(bin1, ntomo+1):
                index = int(ntomo*(bin1-1) - (bin1-1)*(bin1-1 - 1)/2 + (bin2-1) - (bin1-1))
                ax = pl.subplot(ntomo+1, ntomo+1, (bin1-1)*(ntomo+1) + (bin2-1) + 2) # use this for upper triangle
                ax.set_box_aspect(1)
                ax.set_ylim(ymin_eeE,ymax_eeE)
                ax.set_xscale(xscale)
                idx = np.where((eeE_data['BIN1']==bin1) & (eeE_data['BIN2']==bin2))[0]
                # Plot data
                if (statistic == 'bandpowers'):
                    ax.errorbar(eeE_data['ANG'][idx], eeE_data['VALUE'][idx]/eeE_data['ANG'][idx]*scaling_ee, eeE_std[idx]/eeE_data['ANG'][idx]*scaling_ee, linestyle='None', marker='.', markersize=5)
                elif (statistic == 'cosebis'):
                    ax.errorbar(eeE_data['ANG'][idx],eeE_data['VALUE'][idx]*scaling_ee, yerr=eeE_std[idx]*scaling_ee, fmt='d', markeredgecolor='C0', mew=1, markerfacecolor='C0', color='C0', markersize=4)
                elif (statistic == 'xiE') or (statistic == 'xiB') or (statistic == '2pcf'):
                    ax.errorbar(eeE_data['ANG'][idx],eeE_data['ANG'][idx]*eeE_data['VALUE'][idx]*scaling_ee, yerr=eeE_data['ANG'][idx]*eeE_std[idx]*scaling_ee, fmt='d', markeredgecolor='C0', mew=1, markerfacecolor='C0', color='C0', markersize=4)
        
    
                ax.axhline(y=0, color='k', ls=':',label='')
                ax.tick_params(bottom=True, top=False, left=True, right=False, which='both')
                ax.tick_params(labelbottom=False, labeltop=False, labelleft=False, labelright=False)
                if bin1==1:
                    ax.set_xlabel(xlabel)
                    ax.tick_params(bottom=True, top=True, left=True, right=False, which='both')
                    ax.tick_params(labelbottom=False, labeltop=True, labelleft=False, labelright=False)
                    ax.xaxis.set_label_position('top')
                if bin2==ntomo:
                    ax.set_ylabel(ylabel_eeE,**yprops)
                    ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
                    ax.tick_params(labelbottom=False, labeltop=False, labelleft=False, labelright=True)
                    ax.yaxis.set_label_position('right')
                if bin1==1 and bin2==ntomo:
                    ax.tick_params(bottom=True, top=True, left=True, right=True, which='both')
                    ax.tick_params(labelbottom=False, labeltop=True, labelleft=False, labelright=True)
                lg = pl.legend([leg1],[r'$\mathrm{{S}}{{{0}}}-\mathrm{{S}}{{{1}}}$'.format(bin1,bin2)], loc='upper right',
                                        handlelength=0, borderpad=0, labelspacing=0., ncol=3,
                                        prop={'size':fontsize}, columnspacing=0, frameon=None)
                #lg.draw_frame(False)
                # pl.gca().add_artist(lg)
                # if((bin1==1) & (bin2==bin1)):
                #     lg = pl.legend(bbox_to_anchor=(0.0, 1),handlelength=1,borderpad=0,labelspacing=0.1,ncol=1,prop={'size':fontsize}
                #         ,columnspacing=0,frameon=None)
                #     lg.draw_frame(False)
                    
                #################################################################
                # lower triangle for B-modes
                if eeB_data is not None:
                    ax=pl.subplot(ntomo+1,ntomo+1,(bin2-1)*(ntomo+1)+(bin1-1)+ntomo+2)
                    ax.set_box_aspect(1)
                    ax.tick_params(bottom=True, top=False, left=False, right=True, which='both')
                    ax.tick_params(labelbottom=False, labeltop=False, labelleft=False, labelright=False)
                    if bin2==ntomo:
                        ax.set_xlabel(xlabel)
                        ax.tick_params(bottom=True, top=True, left=False, right=True, which='both')
                        ax.tick_params(labelbottom=True, labeltop=False, labelleft=False, labelright=False)
                    if bin1==1:
                        ax.set_ylabel(ylabel_eeB,**yprops)
                        ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
                        ax.tick_params(labelbottom=False, labeltop=False, labelleft=True, labelright=False)
                    if bin1==1 and bin2==ntomo:
                        ax.tick_params(bottom=True, top=True, left=True, right=True, which='both')
                        ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=False)
                    
                    # ax.set_ylim(ymin_eeB,ymax_eeB)
                    ax.set_ylim(ymin_eeE,ymax_eeE)
                    pl.xscale(xscale)
                    
                    idx = np.where((eeE_data['BIN1']==bin1) & (eeE_data['BIN2']==bin2))[0] #??
                    # Plot data
                    if (statistic == 'bandpowers'):
                        ax.errorbar(eeB_data['ANG'][idx], eeB_data['VALUE'][idx]/eeB_data['ANG'][idx]*scaling_ee, eeB_std[idx]/eeB_data['ANG'][idx]*scaling_ee, linestyle='None',   marker='.', markersize=5)
                    elif (statistic == 'cosebis'):
                        ax.errorbar(eeB_data['ANG'][idx],eeB_data['VALUE'][idx]*scaling_ee, yerr=eeB_std[idx]*scaling_ee, fmt='d', markeredgecolor='C0', mew=1, markerfacecolor='C0',   color='C0', markersize=4)
                    elif (statistic == 'xiE') or (statistic == 'xiB') or (statistic == '2pcf'):
                        ax.errorbar(eeB_data['ANG'][idx],eeB_data['ANG'][idx]*eeB_data['VALUE'][idx]*scaling_ee, yerr=eeB_data['ANG'][idx]*eeB_std[idx]*scaling_ee, fmt='d',    markeredgecolor='C0', mew=1, markerfacecolor='C0', color='C0', markersize=4)
                    
                    ax.axhline(y=0, color='k', ls=':')
                    lg = pl.legend([leg1],[r'$\mathrm{{S}}{{{0}}}-\mathrm{{S}}{{{1}}}$'.format(bin1,bin2)], loc='upper right',
                                handlelength=0, borderpad=0, labelspacing=0., ncol=3,
                                prop={'size':fontsize}, columnspacing=0, frameon=None)
                    #lg.draw_frame(False)
                    # pl.gca().add_artist(lg)
                    # if((bin1==1) & (bin2==bin1)):
                    #     lg = pl.legend(bbox_to_anchor=(-0.1, 0.5),handlelength=1,borderpad=0,labelspacing=0.1,ncol=1,prop={'size':fontsize}
                    #         ,columnspacing=0,frameon=None)
                    #     lg.draw_frame(False)
        fig.suptitle(r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic_mm,thetamin_ee,thetamax_ee), fontsize=20)
        if suffix:
            pl.savefig(output_dir+'/cosmic_shear_datavector_%.2f-%.2f_%s.pdf'%(thetamin_ee,thetamax_ee,suffix), bbox_inches="tight")
        else:
            pl.savefig(output_dir+'/cosmic_shear_datavector_%.2f-%.2f.pdf'%(thetamin_ee,thetamax_ee), bbox_inches="tight")
        pl.close()
        pl.clf()
        
    if ne:
        # plotting sizes
        pl.rcParams.update(pl.rcParamsDefault)
        yprops=dict(rotation=90, horizontalalignment='center', verticalalignment='center', x=10, labelpad=20, fontsize=15)
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        formatter = ScalarFormatter(useMathText=True)
        formatter.set_scientific(True)
        fig_width_pt = 246.0*3.5 # Get this from LaTex using \the\columnwidth
        inches_per_pt = 1.0/72.27
        golden_mean = (np.sqrt(5)-1.0)/2.0
        fig_width  = 2.5#fig_width_pt*inches_per_pt # width in inches
        fig_height = fig_width#/golden_mean # height in inches
        fig_size = [fig_width*nlens, fig_height*ntomo]
        fontsize=15
        params = {'axes.labelsize':15,
                'font.size':10,
                'legend.fontsize':17,
                'xtick.labelsize':12,
                'ytick.labelsize':12,
                'figure.figsize':fig_size,
                'font.family': 'serif'}
        pl.rcParams.update(params)
        pl.rc('text', usetex=True)
        pl.subplots_adjust(wspace=0.075, hspace=0.075) # you can add spaces between the block here
        pl.clf()
        fig = pl.figure()
        pl.clf()
        for bin1 in range(1, nlens+1):
            for bin2 in range(1, ntomo+1):
                index = int(ntomo*(bin1-1) - (bin1-1)*(bin1-1 - 1)/2 + (bin2-1))
                ax = pl.subplot(ntomo, nlens, (bin2-1)*(nlens) + (bin1-1) + 1)
                ax.set_box_aspect(1)
                ax.set_ylim(ymin_neE,ymax_neE)
                ax.set_xscale(xscale)
                idx = np.where((neE_data['BIN1']==bin1) & (neE_data['BIN2']==bin2))[0]
                # Plot data
                if (statistic == 'bandpowers'):
                    ax.errorbar(neE_data['ANG'][idx], neE_data['VALUE'][idx]/neE_data['ANG'][idx]*scaling_ne, neE_std[idx]/neE_data['ANG'][idx]*scaling_ne, linestyle='None', marker='.', markersize=5)
                elif (statistic == 'cosebis'):
                    ax.errorbar(neE_data['ANG'][idx],neE_data['VALUE'][idx]*scaling_ne, yerr=neE_std[idx]*scaling_ne, fmt='d', markeredgecolor='C0', mew=1, markerfacecolor='C0', color='C0', markersize=4)
                elif statistic == '2pcf':
                    ax.errorbar(neE_data['ANG'][idx],neE_data['ANG'][idx]*neE_data['VALUE'][idx]*scaling_ne, yerr=neE_data['ANG'][idx]*neE_std[idx]*scaling_ne, fmt='d', markeredgecolor='C0', mew=1, markerfacecolor='C0', color='C0', markersize=4)
        
                ax.axhline(y=0, color='k', ls=':',label='')
                ax.tick_params(bottom=True, top=False, left=True, right=False, which='both')
                ax.tick_params(labelbottom=False, labeltop=False, labelleft=False, labelright=False)
                
                if bin2==ntomo:
                    ax.set_xlabel(xlabel)
                    ax.tick_params(bottom=True, top=False, left=True, right=False, which='both')
                    ax.tick_params(labelbottom=True, labeltop=False, labelleft=False, labelright=False)
                    ax.xaxis.set_label_position('bottom')
                if bin1==1:
                    ax.set_ylabel(ylabel_neE,**yprops)
                    ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
                    ax.tick_params(labelbottom=False, labeltop=False, labelleft=True, labelright=False)
                    ax.yaxis.set_label_position('left')
                if bin1==1 and bin2==ntomo:
                    ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
                    ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=False)
                lg = pl.legend([leg1],[r'$\mathrm{{L}}{{{0}}}-\mathrm{{S}}{{{1}}}$'.format(bin1,bin2)], loc='upper right',
                            handlelength=0, borderpad=0, labelspacing=0., ncol=3,
                            prop={'size':fontsize}, columnspacing=0, frameon=None)
                #lg.draw_frame(False)
                
        fig.suptitle(r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic_gm,thetamin_ne,thetamax_ne), fontsize=20)
        if suffix:
            pl.savefig(output_dir+'/ggl_datavector_%.2f-%.2f_%s.pdf'%(thetamin_ne,thetamax_ne,suffix), bbox_inches="tight")
        else:
            pl.savefig(output_dir+'/ggl_datavector_%.2f-%.2f.pdf'%(thetamin_ne,thetamax_ne), bbox_inches="tight")
        pl.close()
        pl.clf()
        
        if neB_data is not None:
            if (statistic == 'bandpowers') or (statistic == '2pcf'):
                for bin1 in range(1, nlens+1):
                    for bin2 in range(1, ntomo+1):
                        index = int(ntomo*(bin1-1) - (bin1-1)*(bin1-1 - 1)/2 + (bin2-1))
                        ax = pl.subplot(ntomo, nlens, (bin2-1)*(nlens) + (bin1-1) + 1)
                        ax.set_box_aspect(1)
                        ax.set_ylim(ymin_neB,ymax_neB)
                        ax.set_xscale(xscale)
                        idx = np.where((neB_data['BIN1']==bin1) & (neB_data['BIN2']==bin2))[0]
                        # Plot data
                        if (statistic == 'bandpowers'):
                            ax.errorbar(neB_data['ANG'][idx], neB_data['VALUE'][idx]/neB_data['ANG'][idx]*scaling_ne, neB_std[idx]/neB_data['ANG'][idx]*scaling_ne, linestyle='None',      marker='.', markersize=5)
                        elif statistic == '2pcf':
                            ax.errorbar(neB_data['ANG'][idx],neB_data['ANG'][idx]*neB_data['VALUE'][idx]*scaling_ne, yerr=neB_data['ANG'][idx]*neB_std[idx]*scaling_ne, fmt='d',    markeredgecolor='C0', mew=1, markerfacecolor='C0', color='C0', markersize=4)
            
                        ax.axhline(y=0, color='k', ls=':',label='')
                        ax.tick_params(bottom=True, top=False, left=True, right=False, which='both')
                        ax.tick_params(labelbottom=False, labeltop=False, labelleft=False, labelright=False)
            
                        if bin2==ntomo:
                            ax.set_xlabel(xlabel)
                            ax.tick_params(bottom=True, top=False, left=True, right=False, which='both')
                            ax.tick_params(labelbottom=True, labeltop=False, labelleft=False, labelright=False)
                            ax.xaxis.set_label_position('bottom')
                        if bin1==1:
                            ax.set_ylabel(ylabel_neE,**yprops)
                            ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
                            ax.tick_params(labelbottom=False, labeltop=False, labelleft=True, labelright=False)
                            ax.yaxis.set_label_position('left')
                        if bin1==1 and bin2==ntomo:
                            ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
                            ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=False)
                        lg = pl.legend([leg1],[r'$\mathrm{{L}}{{{0}}}-\mathrm{{S}}{{{1}}}$'.format(bin1,bin2)], loc='upper right',
                                handlelength=0, borderpad=0, labelspacing=0., ncol=3,
                                prop={'size':fontsize}, columnspacing=0, frameon=None)
                        #lg.draw_frame(False)
            
                fig.suptitle(r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic_gm,thetamin_ne,thetamax_ne), fontsize=20)
                if suffix:
                    pl.savefig(output_dir+'/ggl_B_datavector_%.2f-%.2f_%s.pdf'%(thetamin_ne,thetamax_ne,suffix), bbox_inches="tight")
                else:
                    pl.savefig(output_dir+'/ggl_B_datavector_%.2f-%.2f.pdf'%(thetamin_ne,thetamax_ne), bbox_inches="tight")
                pl.close()
                pl.clf()
        pl.rcParams.update()
    
    if nn:
        # plotting sizes
        pl.rcParams.update(pl.rcParamsDefault)
        yprops=dict(rotation=90, horizontalalignment='center', verticalalignment='center', x=10, labelpad=20, fontsize=15)
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        formatter = ScalarFormatter(useMathText=True)
        formatter.set_scientific(True)
        fig_width_pt = 246.0*3.5 # Get this from LaTex using \the\columnwidth
        inches_per_pt = 1.0/72.27
        golden_mean = (np.sqrt(5)-1.0)/2.0
        fig_width  = 2.5#fig_width_pt*inches_per_pt # width in inches
        fig_height = fig_width#/golden_mean # height in inches
        fig_size = [fig_width*2, 2*fig_height*nlens]
        fontsize=15
        params = {'axes.labelsize':15,
                'font.size':10,
                'legend.fontsize':17,
                'xtick.labelsize':12,
                'ytick.labelsize':12,
                'figure.figsize':fig_size,
                'font.family': 'serif'}
        pl.rcParams.update(params)
        pl.rc('text', usetex=True)
        pl.subplots_adjust(wspace=0.075, hspace=0.075) # you can add spaces between the block here
        pl.clf()
        fig = pl.figure()
        pl.clf()
        for bin1 in range(1, nlens+1):
            #for bin2 in range(1, nlens+1):
            #    if bin1!=bin2:
            #        continue
            index = int(nlens*(bin1-1) - (bin1-1))
            ax = pl.subplot(nlens, 1, bin1)#(bin1-1)*(nlens) + 1) # use this for upper triangle
            ax.set_box_aspect(1)
            ax.set_ylim(ymin_nn,ymax_nn)
            ax.set_xscale(xscale)
            #idx = np.where((nn_data['BIN1']==bin1) & (nn_data['BIN2']==bin2))[0]
            idx = np.where((nn_data['BIN1']==bin1) & (nn_data['BIN2']==bin1))[0]
            # Plot data
            if (statistic == 'bandpowers'):
                ax.errorbar(nn_data['ANG'][idx], nn_data['VALUE'][idx]/nn_data['ANG'][idx]*scaling_nn, nn_std[idx]/nn_data['ANG'][idx]*scaling_nn, linestyle='None', marker='.', markersize=5)
            elif (statistic == 'cosebis'):
                ax.errorbar(nn_data['ANG'][idx],nn_data['VALUE'][idx]*scaling_nn, yerr=nn_std[idx]*scaling_nn, fmt='d', markeredgecolor='C0', mew=1, markerfacecolor='C0', color='C0', markersize=4)
            elif statistic == '2pcf':
                ax.errorbar(nn_data['ANG'][idx],nn_data['ANG'][idx]*nn_data['VALUE'][idx]*scaling_nn, yerr=nn_data['ANG'][idx]*nn_std[idx]*scaling_nn, fmt='d', markeredgecolor='C0', mew=1, markerfacecolor='C0', color='C0', markersize=4)
        
            ax.axhline(y=0, color='k', ls=':',label='')
            #ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
            #ax.tick_params(labelbottom=False, labeltop=False, labelleft=False, labelright=False)
            ax.set_ylabel(ylabel_nn,**yprops)
            #if bin1==1:
            ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
            ax.tick_params(labelbottom=False, labeltop=False, labelleft=True, labelright=False)
            ax.yaxis.set_label_position('left')
            #if bin2==nlens:
            #    ax.set_xlabel(xlabel)
            #    ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
            #    ax.tick_params(labelbottom=True, labeltop=False, labelleft=False, labelright=False)
            #    ax.xaxis.set_label_position('bottom')
            #if bin1==1 and bin2==nlens:
            if bin1==nlens:
                ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
                ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=False)
                ax.yaxis.set_label_position('left')
                ax.xaxis.set_label_position('bottom')
                ax.set_xlabel(xlabel)
            lg = pl.legend([leg1],[r'$\mathrm{{L}}{{{0}}}-\mathrm{{L}}{{{1}}}$'.format(bin1,bin1)], loc='upper right',
                            handlelength=0, borderpad=0, labelspacing=0., ncol=3,
                            prop={'size':fontsize}, columnspacing=0, frameon=None)
            #lg.draw_frame(False)
                
        fig.suptitle(r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic_gg,thetamin_nn,thetamax_nn), fontsize=20)
        if suffix:
            pl.savefig(output_dir+'/clustering_datavector_%.2f-%.2f_%s.pdf'%(thetamin_nn,thetamax_nn,suffix), bbox_inches="tight")
        else:
            pl.savefig(output_dir+'/clustering_datavector_%.2f-%.2f.pdf'%(thetamin_nn,thetamax_nn), bbox_inches="tight")
        pl.close()
        pl.clf()
        
    if obs:
        # plotting sizes
        pl.rcParams.update(pl.rcParamsDefault)
        yprops=dict(rotation=90, horizontalalignment='center', verticalalignment='center', x=10, labelpad=20, fontsize=15)
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        formatter = ScalarFormatter(useMathText=True)
        formatter.set_scientific(True)
        fig_width_pt = 246.0*3.5 # Get this from LaTex using \the\columnwidth
        inches_per_pt = 1.0/72.27
        golden_mean = (np.sqrt(5)-1.0)/2.0
        fig_width  = 2.5#fig_width_pt*inches_per_pt # width in inches
        fig_height = fig_width#/golden_mean # height in inches
        fig_size = [fig_width*2, fig_height*2]
        fontsize=15
        params = {'axes.labelsize':15,
                'font.size':10,
                'legend.fontsize':17,
                'xtick.labelsize':12,
                'ytick.labelsize':12,
                'figure.figsize':fig_size,
                'font.family': 'serif'}
        pl.rcParams.update(params)
        pl.rc('text', usetex=True)
        pl.subplots_adjust(wspace=0.075, hspace=0.075) # you can add spaces between the block here
        pl.clf()
        fig = pl.figure()
        pl.clf()
        
        ax = pl.subplot(1, 1, 1)
        #ax.set_ylim(ymin_obs/2,ymax_obs*2)
        ax.set_xlim(xmin_obs/2,xmax_obs*2)
        ax.set_xscale(xscale_obs)
        ax.set_yscale(yscale_obs)
        
        for bin1 in range(1, nobs+1):
            
            # Plot data
            ax.errorbar(obs_x[bin1-1], obs_y[bin1-1]*scaling_obs, obs_err[bin1-1]*scaling_obs, linestyle='None', marker='.', markersize=5)
            #ax.axhline(y=0, color='k', ls=':',label='')
        ax.tick_params(bottom=True, top=False, left=True, right=True, which='both')
        ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=False)
        ax.set_ylabel(ylabel_obs,**yprops)
        ax.set_xlabel(xlabel_obs)
        ax.xaxis.set_label_position('bottom')
        ax.yaxis.set_label_position('left')
        ax.set_box_aspect(1)
        lg = pl.legend([leg1],[r'$\mathrm{{O}}{{{0}}}$'.format(bin1)], loc='upper right',
                            handlelength=0, borderpad=0, labelspacing=0., ncol=3,
                            prop={'size':fontsize}, columnspacing=0, frameon=None)
            #lg.draw_frame(False)
                
        fig.suptitle(r'%s %s %s'%(title,suffix,'1pt'), fontsize=20)
        if suffix:
            pl.savefig(output_dir+'/smf_datavector_%s.pdf'%(suffix), bbox_inches="tight")
        else:
            pl.savefig(output_dir+'/smf_datavector.pdf', bbox_inches="tight")
        pl.close()
        pl.clf()












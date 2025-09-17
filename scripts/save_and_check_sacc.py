import sys

import collections as clt
import numpy as np
import os
from argparse import ArgumentParser
import sacc
from astropy.io import fits


sacc_map = {
    "cosebis": {
        "NN": "galaxy_density_cosebi",
        "NE": "galaxy_shearDensity_cosebi_e",
        "NB": "galaxy_shearDensity_cosebi_b",
        "EE": "galaxy_shear_cosebi_ee",
        "BB": "galaxy_shear_cosebi_bb",
    },
    "bandpowers": {
        "NN": "galaxy_density_cl",
        "NE": "galaxy_shearDensity_cl_e",
        "NB": "galaxy_shearDensity_cl_b",
        "EE": "galaxy_shear_cl_ee",
        "BB": "galaxy_shear_cl_bb",
    },
    "2pcf": {
        "NN": "galaxy_density_xi",
        "NE": "galaxy_shearDensity_xi_t",
        "NB": "galaxy_shearDensity_xi_x",
        "EE": "galaxy_shear_xi_plus",
        "BB": "galaxy_shear_xi_minus",
    },
}

tracer_map = {
        "NN": ("lens", "lens"),
        "NE": ("source", "lens"),
        "NB": ("source", "lens"),
        "EE": ("source", "source"),
        "BB": ("source", "source"),
}

def plot_2pt(sacc_data, statistic, type, plotdir):
    import matplotlib.pyplot as plt
    # Now another plot of the second data set that we saved and loaded
    instance = sacc_map[statistic][type]
    for b1, b2 in sacc_data.get_tracer_combinations(instance):
        x, y, covmat = sacc_data._get_2pt(instance, b1, b2, return_cov=True, angle_name='theta' if statistic == '2pcf' else 'ell' if statistic == 'bandpowers' else 'n')
        #plt.errorbar(x, y, yerr=covmat.diagonal()**0.5, fmt='.', label=f'{b1}-{b2}')
        plt.plot(x, y, label=f'{b1}-{b2}')
        plt.xscale('log')
        plt.yscale('log')
    plt.savefig(os.path.join(plotdir, f'{statistic}_{type}.png'))
    plt.clf()
    plt.close()

def plot_1pt(sacc_data, plotdir):
    import matplotlib.pyplot as plt
    # Now another plot of the second data set that we saved and loaded
    for b in sacc_data.get_tracer_combinations('galaxy_stellarmassfunction'):
        ind = sacc_data.indices('galaxy_stellarmassfunction', (b,))
        y = np.array(sacc_data.mean[ind])
        x = np.array(sacc_data._get_tags_by_index(['mass'], ind)[0])
        #covmat = sacc_data.covariance.get_block(ind)
        plt.plot(x, y, label=b)
        plt.xscale('log')
        plt.yscale('log')
    plt.savefig(os.path.join(plotdir, 'smf.png'))
    plt.clf()
    plt.close()

def plot_nz(sacc_data, plotdir):
    import matplotlib.pyplot as plt
    # Now another plot of the second data set that we saved and loaded
    for b in sacc_data.get_tracer_combinations('NZ'):
        ind = sacc_data.indices('NZ', (b,))
        y = np.array(sacc_data.mean[ind])
        x = np.array(sacc_data._get_tags_by_index(['z'], ind)[0])
        plt.plot(x, y, label=b)
        plt.xscale('linear')
        plt.yscale('linear')
    plt.savefig(os.path.join(plotdir, 'nz.png'))
    plt.clf()
    plt.close()
            
def set_ang_bins(min_val, max_val, n, statistic):
    if statistic == 'cosebis':
        return np.arange(n) + 1.0
    if statistic in ['bandpowers', '2pcf']:
        return np.logspace(np.log10(min_val), np.log10(max_val), 2 * n + 1)[1::2] # I guess this picks bin centers? Keeping this as it is for consistency with wraper_twopoint2.py
    raise ValueError(f"Unknown statistic: {statistic}")
        
def set_pairs(n1, n2, type=None):
    if type == 'auto':
        return n1, [(i, i) for i in range(n1)]
    elif type == 'all':
        return n1 * n2, [(i, j) for i in range(n1) for j in range(n2)]
    else:
        return n1 * (n2 + 1) // 2, [(i, j) for i in range(n1) for j in range(i, n2)]
    
def add_nz(sacc_data, nz_files, name):
    # nz can be in txt file or fits file!
    for i, nz_file in enumerate(nz_files):
        # Load n(z)
        if nz_file.endswith('.fits'):
            data = fits.getdata(nz_file, 1)
            z = data.field(0)
            nz = data.field(1)
        else:
            z, nz = np.loadtxt(nz_file).T
    
        # Sacc wants bin centers, whereas this file as bin edges, so convert
        z += 0.5*(z[1]-z[0])
        sacc_data.add_tracer('NZ', f'{name}_{i}', z, nz)
                    
def add_2pt_points(sacc_data, statistic, type, auto, n1, n2, min_val, max_val, nangle, values):
    npairs, pair_list = set_pairs(n1, n2, auto)
    angles = set_ang_bins(min_val, max_val, nangle, statistic)

    bin_idx = 0
    for i, j in pair_list:
        for ang_idx in range(nangle):
            angle = angles[ang_idx]
            value = values[bin_idx]
            tracers = (f"{tracer_map[type][0]}_{i}", f"{tracer_map[type][1]}_{j}")
            dt = sacc_map[statistic][type]

            kwargs = {
                'n': angle,
                'n_bin': ang_idx + 1
            } if statistic == "cosebis" else {
                'ell': angle,
                'ell_bin': ang_idx + 1
            } if statistic == "bandpowers" else {
                'theta': angle,
                'theta_bin': ang_idx + 1
            }

            sacc_data.add_data_point(dt, tracers, value, **kwargs)
            bin_idx += 1
                
                
def add_1pt_points(sacc_data, files):
    for i, file in enumerate(files):
        # Load SMF
        mass, value, extra = np.loadtxt(file).T
        mass_min = mass - 0.5 * (mass[1] - mass[0])
        mass_max = mass + 0.5 * (mass[1] - mass[0])

        for m, mmin, mmax, v in zip(mass, mass_min, mass_max, value):
            tracer_name = f"lens_{i}"
            dt = "galaxy_stellarmassfunction"
            sacc_data.add_data_point(dt, (tracer_name,), v, mass=m, mass_min=mmin, mass_max=mmax)


def process_2pt_data(mode, nangle, min_val, max_val, n1, n2, datavec_files, statistic, sacc_data, sacc_data_no_mbias, auto=None):
    if len(datavec_files) not in [1, 2]:
        raise ValueError(f"Expect 1 or 2 files for {mode}, got {len(datavec_files)}")

    datavec = list(np.genfromtxt(datavec_files[0]))
    datavec_no_mbias = list(np.genfromtxt(datavec_files[1])) if len(datavec_files) == 2 else []

    nbins = set_pairs(n1, n2, auto)[0]
    has_b_modes = len(datavec) == 2 * nangle * nbins

    if has_b_modes:
        mode_b = 'NB' if mode == 'NE' else 'BB'
        vec_e = datavec[:(nangle * nbins)]
        vec_b = datavec[(nangle * nbins):]
        add_2pt_points(sacc_data, statistic, mode, auto, n1, n2, min_val, max_val, nangle, vec_e)
        add_2pt_points(sacc_data, statistic, mode_b, auto, n1, n2, min_val, max_val, nangle, vec_b)

        if datavec_no_mbias:
            vec_e_no = datavec_no_mbias[:(nangle * nbins)]
            vec_b_no = datavec_no_mbias[(nangle * nbins):]
            add_2pt_points(sacc_data_no_mbias, statistic, mode, auto, n1, n2, min_val, max_val, nangle, vec_e_no)
            add_2pt_points(sacc_data_no_mbias, statistic, mode_b, auto, n1, n2, min_val, max_val, nangle, vec_b_no)
    else:
        add_2pt_points(sacc_data, statistic, mode, auto, n1, n2, min_val, max_val, nangle, datavec)
        if datavec_no_mbias:
            add_2pt_points(sacc_data_no_mbias, statistic, mode, auto, n1, n2, min_val, max_val, nangle, datavec_no_mbias)
        

if __name__ == "__main__":

    parser = ArgumentParser(description='Construct a cosmosis mcmc input file')
    parser.add_argument("--datavector_ee", dest="datavector_ee",nargs='*',
        help="Full Input file names", metavar="datavector_ee",required=True, default=None, const=None)
    parser.add_argument("--datavector_ne", dest="datavector_ne",nargs='*',
        help="Full Input file names", metavar="datavector_ne",required=True, default=None, const=None)
    parser.add_argument("--datavector_nn", dest="datavector_nn",nargs='*',
        help="Full Input file names", metavar="datavector_nn",required=True, default=None, const=None)
    parser.add_argument("--smfdatavector", dest="smfvec",nargs='*',
        help="SMF input file name", metavar="smfvec",required=False, default=None, const=None)
    parser.add_argument("-s", "--statistic", dest="statistic", type=str, required=True, choices = ['cosebis','cosebis_dimless','bandpowers','2pcf','2pcfEB'],
        help="2pt statistic, must be either cosebis, bandpowers, or xipm")
    parser.add_argument("--mode", dest="mode",nargs='+',type=str,
        help="list modes to calculate statistis for (EE, NE, NN or OBS)",required=True, default=['EE'])
        
    parser.add_argument("--nzsource", dest="nzlist_source",nargs='*',type=str,
        help="list of Nz per tomographic bin",required=False, default=None, const=None)
    parser.add_argument("--nzlens", dest="nzlist_lens",nargs='*',type=str,
        help="list of Nz per tomographic bin",required=False, default=None, const=None)
    parser.add_argument("--nzobs", dest="nzlist_obs",nargs='*',type=str,
        help="list of Nz per tomographic bin",required=False, default=None, const=None)
        
    parser.add_argument("--ntomo", dest="nTomo",type=int,
        help="Number of tomographic bins",required=False, default=0)
    parser.add_argument("--nlens", dest="nLens",type=int,
        help="Number of lens bins",required=False, default=0)
    parser.add_argument("--nobs", dest="nObs",type=int,
        help="Number of SMF bins",required=False, default=0)
        
    parser.add_argument("--nmaxcosebis_ee", dest="nmaxcosebis_ee",type=int,
        help="maximum n for cosebis",required=False, default=5)
    parser.add_argument("--nbandpowers_ee", dest="nbandpowers_ee",type=int,
        help="number of bandpower bins",required=False, default=8)
    parser.add_argument("--ellmin_ee", dest="ellmin_ee",type=float,
        help="bandpower ell_min",required=False, default=100)
    parser.add_argument("--ellmax_ee", dest="ellmax_ee",type=float,
        help="bandpower ell_max",required=False, default=1500)
        
    parser.add_argument("--nmaxcosebis_ne", dest="nmaxcosebis_ne",type=int,
        help="maximum n for cosebis",required=False, default=5)
    parser.add_argument("--nbandpowers_ne", dest="nbandpowers_ne",type=int,
        help="number of bandpower bins",required=False, default=8)
    parser.add_argument("--ellmin_ne", dest="ellmin_ne",type=float,
        help="bandpower ell_min",required=False, default=100)
    parser.add_argument("--ellmax_ne", dest="ellmax_ne",type=float,
        help="bandpower ell_max",required=False, default=1500)
        
    parser.add_argument("--nmaxcosebis_nn", dest="nmaxcosebis_nn",type=int,
        help="maximum n for cosebis",required=False, default=5)
    parser.add_argument("--nbandpowers_nn", dest="nbandpowers_nn",type=int,
        help="number of bandpower bins",required=False, default=8)
    parser.add_argument("--ellmin_nn", dest="ellmin_nn",type=float,
        help="bandpower ell_min",required=False, default=100)
    parser.add_argument("--ellmax_nn", dest="ellmax_nn",type=float,
        help="bandpower ell_max",required=False, default=1500)
        
    parser.add_argument("--thetamin_ee", dest="thetamin_ee",type=float,
        help="xipm theta_min",required=False, default=0.5)
    parser.add_argument("--thetamax_ee", dest="thetamax_ee",type=float,
        help="xipm theta_max",required=False, default=300)
    parser.add_argument("--ntheta_ee", dest="ntheta_ee",type=int,
        help="number of xipm bins",required=False, default=9)
        
    parser.add_argument("--thetamin_ne", dest="thetamin_ne",type=float,
        help="gt theta_min",required=False, default=0.5)
    parser.add_argument("--thetamax_ne", dest="thetamax_ne",type=float,
        help="gt theta_max",required=False, default=300)
    parser.add_argument("--ntheta_ne", dest="ntheta_ne",type=int,
        help="number of gt bins",required=False, default=9)
        
    parser.add_argument("--thetamin_nn", dest="thetamin_nn",type=float,
        help="wt theta_min",required=False, default=0.5)
    parser.add_argument("--thetamax_nn", dest="thetamax_nn",type=float,
        help="wt theta_max",required=False, default=300)
    parser.add_argument("--ntheta_nn", dest="ntheta_nn",type=int,
        help="number of wt bins",required=False, default=9)
        
    parser.add_argument("--neff_source", dest="NeffFileSource",nargs='*',
        help="Neff values file for sources",required=False, default=None, const=None)
    parser.add_argument("--neff_lens", dest="NeffFileLens",nargs='*',
        help="Neff values file for lenses",required=False, default=None, const=None)
    parser.add_argument("--neff_obs", dest="NeffFileObs",nargs='*',
        help="Neff values file for SMF",required=False, default=None, const=None)
    parser.add_argument("--sigmae", dest="SigmaeFile",nargs='*',
        help="sigmae values file",required=False, default=None)
    parser.add_argument("--covariance", dest="covarianceFile",nargs=1,
        help="Covariance file",required=True)
    parser.add_argument("-o", "--outputfile", dest="outputFile",
        help="Full Output file name", metavar="outputFile",required=True)
    parser.add_argument("-p", "--plotdir", dest="plotdir",
        help="Path for output figures", metavar="plotdir",required=True)
    
    args = parser.parse_args()
    
    statistic = args.statistic.replace("_dimless", "").replace("2pcfEB", "2pcf")
    
    # Folder and file names for nofZ, for the sources it will depend on the blind
    
    plotdir = args.plotdir
    outputfile = args.outputFile
    ntomo = args.nTomo
    nlens = args.nLens
    nobs = args.nObs
    
    sacc_data = sacc.Sacc()
    sacc_data_no_mbias = sacc.Sacc()
    
    if 'NE' in args.mode or 'NN' in args.mode:
        if nlens == 0:
            raise ValueError('At least one lens bin expected!')
        add_nz(sacc_data, args.nzlist_lens, 'lens')
        add_nz(sacc_data_no_mbias, args.nzlist_lens, 'lens')
    
    if 'EE' in args.mode or 'NE' in args.mode:
        if ntomo == 0:
            raise ValueError('At least one source bin expected!')
        add_nz(sacc_data, args.nzlist_source, 'source')
        add_nz(sacc_data_no_mbias, args.nzlist_source, 'source')
    
    if 'OBS' in args.mode:
        if nobs == 0:
            raise ValueError('At least one SMF bin expected!')
        add_nz(sacc_data, args.nzlist_obs, 'obs')
        add_nz(sacc_data_no_mbias, args.nzlist_obs, 'obs')
        
    if statistic == 'cosebis':
        if 'EE' in args.mode:
            nangle_ee = args.nmaxcosebis_ee
            min_ee = args.ellmin_ee
            max_ee = args.ellmax_ee
        if 'NE' in args.mode:
            nangle_ne = args.nmaxcosebis_ne
            min_ne = args.ellmin_ne
            max_ne = args.ellmax_ne
        if 'NN' in args.mode:
            nangle_nn = args.nmaxcosebis_nn
            min_nn = args.ellmin_nn
            max_nn = args.ellmax_nn
    elif statistic == 'bandpowers':
        if 'EE' in args.mode:
            nangle_ee = args.nbandpowers_ee
            min_ee = args.ellmin_ee
            max_ee = args.ellmax_ee
        if 'NE' in args.mode:
            nangle_ne = args.nbandpowers_ne
            min_ne = args.ellmin_ne
            max_ne = args.ellmax_ne
        if 'NN' in args.mode:
            nangle_nn = args.nbandpowers_nn
            min_nn = args.ellmin_nn
            max_nn = args.ellmax_nn
    elif statistic == '2pcf':
        if 'EE' in args.mode:
            nangle_ee = args.ntheta_ee
            min_ee = args.thetamin_ee
            max_ee = args.thetamax_ee
        if 'NE' in args.mode:
            nangle_ne = args.ntheta_ne
            min_ne = args.thetamin_ne
            max_ne = args.thetamax_ne
        if 'NN' in args.mode:
            nangle_nn = args.ntheta_nn
            min_nn = args.thetamin_nn
            max_nn = args.thetamax_nn
    else:
        raise Exception('Unknown statistic!')
    
    no_m_bias_nn = False
    no_m_bias_ne = False
    no_m_bias_ee = False
    
    if 'NN' in args.mode:
        process_2pt_data('NN', nangle_nn, min_nn, max_nn, nlens, nlens, args.datavector_nn,
                     statistic, sacc_data, sacc_data_no_mbias, auto='auto')

    if 'NE' in args.mode:
        process_2pt_data('NE', nangle_ne, min_ne, max_ne, ntomo, nlens, args.datavector_ne,
                     statistic, sacc_data, sacc_data_no_mbias, auto='all')

    if 'EE' in args.mode:
        process_2pt_data('EE', nangle_ee, min_ee, max_ee, ntomo, ntomo, args.datavector_ee,
                     statistic, sacc_data, sacc_data_no_mbias)
                
    if 'OBS' in args.mode:
        if len(args.smfvec) != nobs:
            raise ValueError(f'Expected {nobs} SMF files, but got {len(args.smfvec)}!')
        smfvec = args.smfvec
        add_1pt_points(sacc_data, smfvec)
        add_1pt_points(sacc_data_no_mbias, smfvec)
    
    
    covariance = np.loadtxt(args.covarianceFile[0])
    #covariance = 0.1 * np.eye(len(sacc_data.data))  # Placeholder for covariance matrix, replace with actual loading if needed

    sacc_data.add_covariance(covariance)
    sacc_data_no_mbias.add_covariance(covariance)

    # Save the SACC data to a file
    sacc_data.save_fits(f'{outputfile}.sacc', overwrite=True)
    sacc_data_no_mbias.save_fits(f'{outputfile}_no_m_bias.sacc', overwrite=True)

    """
    # Plotting
    if not os.path.exists(plotdir):
        os.makedirs(plotdir)
        
    for type in args.mode:
        if type != 'OBS':
            plot_2pt(sacc_data, statistic, type, plotdir)
        if type == 'OBS':
            plot_1pt(sacc_data, plotdir)
    plot_nz(sacc_data, plotdir)
    """



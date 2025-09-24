  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import astropy.io.fits as fits

"""
From Blicki et al. 2021 bright sample paper:
Appendix C:
Note 1. All the "MASS" quantities stand for log10(M_star/M_sun).
Note 2. Fluxscale correction: Because the GAaP photometry only 
measures the galaxy magnitude within a specific aperture size,
the stellar mass should be corrected using a “fluxscale” parameter, 
which is the ratio of AUTO and GAaP fluxes:
log10(fluxscale) = (MAG_GAAP_r - MAG_AUTO)/2.5. (C.1)
The "total" stellar mass in then
M_TOT = M_BEST + log10(fluxscale). (C.2)
Similarly, also absolute magnitudes need corrections if total measurements are required:
MAG_ABS_X, total = MAG_ABS_X - 2.5 log10(fluxscale). (C.3)
All the LePhare quantities were computed assuming h = 0.7, 
and the estimated stellar masses are assumed to have a dependence
on h dominated by the h^-2
scaling of luminosities. Therefore, if another Hubble constant value is used, 
the logarithmic stellar mass
in Eq. (C.2) needs to be corrected by -2 log10(h/0.7), 
while the absolute magnitudes in Eq. (C.3) need to have 5 log10(h/0.7) added.
"""

if __name__ == '__main__':
    
    
    parser = argparse.ArgumentParser(description='Apply fluxscale correction to the KiDS Bright catalogue and rescale h0 from user inputs')
    parser.add_argument('--h0', type=float, help='h0 from LePhare or other stellar mass code estimation routine', nargs='?', default=0.7, const=1.0)
    parser.add_argument('--file', type=str, help='Input catalogue', nargs='?', default=None, const=None)
    parser.add_argument('--output_file', type=str, help='Output catalogue', nargs='?', default='fluxscale_fixed.fits', const=None)
    args = parser.parse_args()
    
    h0 = args.h0
    file_in = fits.open(args.file)
    
    data = file_in[1].data
    
    data = data[(data['MASK'] == 0) & (data['MAG_ABS_r'] < -10) & (data['MASS_MED'] != -99) & (data['z_ANNZ_KV'] >= 0.0)
                & (data['z_ANNZ_KV'] <= 6.0) & (data['MASS_BEST'] >= 2.0) & (data['MASS_BEST'] <= 20.0)]
    
    fluxscale = (data['MAG_GAAP_r'] - data['MAG_AUTO_CALIB']) / 2.5

    # We want stellar masses in units of M_sun/h^2 to remove the h dependence
    # data['MASS_BEST'] is in units of M_sun. To make it in units of h^2 we multiply M* by h^2
    # log10(M/M_sun h^2) = log10 (M/M_sun) + 2*log10(h)
    stellar_mass_corrected = data['MASS_BEST'] + fluxscale + 2.0*np.log10(h0)
    # stellar_mass_corrected = data['MASS_BEST'] + fluxscale - 2.0*np.log10(h0/0.7)

    
    
    data_out = np.copy(data)
    new_cols = fits.Column(name='stellar_mass_fluxscale_corrected', format='D', array=stellar_mass_corrected)
    
    cols = fits.ColDefs(data_out)
    hdu  = fits.BinTableHDU.from_columns(cols + new_cols)
    hdu.writeto(args.output_file, overwrite=True)
    print('Fluxscale correction applied to the Bright catalogue')

    
    
    
    
    
    
    

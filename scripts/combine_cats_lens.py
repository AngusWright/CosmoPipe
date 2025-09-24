  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import astropy.io.fits as fits



if __name__ == '__main__':
    
    
	parser = argparse.ArgumentParser(description='Combine 2 or more catalogues to a single catalogue')
	parser.add_argument('--files', type=[], help='Input catalogues', nargs='*', default=None, const=None)
	parser.add_argument('--output_file', type=str, help='Output catalogue', nargs='?', default=None, const=None)
	args = parser.parse_args()
    
    file0 = fits.open(args.files[0])
    data0 = file0[1].data
    nrows = 0
    for f in args.files:
        file_in = fits.open(f)
        data = file_in[1].data
        nrows += data.shape[0]
    
	hdu = fits.BinTableHDU.from_columns(file0[1].columns, nrows=nrows)
    for colname in file_in0[1].columns.names:
        nrows = 0
        for f in args.files:
            file_in = fits.open(f)
            data = file_in[1].data
            nrows_in =  data.shape[0]
            data0[colname][nrows:nrows_in] = data[colname]
            nrows += nrows_in

	
	hdu.writeto(args.output_file, overwrite=True)
	print(f'Input catalogues combined into one!')

    
    
    

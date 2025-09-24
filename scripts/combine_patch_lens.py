  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import astropy.io.fits as fits



if __name__ == '__main__':
    
    
	parser = argparse.ArgumentParser(description='Combine N and S patches to a single lens catalogue')
	parser.add_argument('--files', type=[], help='Input catalogues', nargs=2, default=None, const=None)
	parser.add_argument('--output_file', type=str, help='Output catalogue', nargs='?', default=None, const=None)
	args = parser.parse_args()
    
	file_in1 = fits.open(args.files[0])
	file_in2 = fits.open(args.files[1])
	data1 = file_in1[1].data
	data2 = file_in2[1].data
    
	nrows1 = data1.shape[0]
	nrows2 = data2.shape[0]
	nrows = nrows1 + nrows2
    
	hdu = fits.BinTableHDU.from_columns(file_in1[1].columns, nrows=nrows)
	for colname in file_in1[1].columns.names:
		data1[colname][nrows1:] = data2[colname]

	
	hdu.writeto(args.output_file, overwrite=True)
	print(f'Input catalogue combined into NS patch!')

    
    
    

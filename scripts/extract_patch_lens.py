  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import astropy.io.fits as fits



if __name__ == '__main__':
    
    
	parser = argparse.ArgumentParser(description='Extract N and S patches from lens catalogue')
	parser.add_argument('--c', type=float, help='condition, define the DEC value to split north and sound patches from main catalogue', nargs=1, default=-15.0)
	parser.add_argument('--file', type=str, help='Input catalogue', nargs='?', default=None, const=None)
	parser.add_argument('--output_file', type=str, help='Output catalogue', nargs='?', default=None, const=None)
	parser.add_argument('--patch', type=str, help='Patch designation', nargs='?', default=None, const=None)
	parser.add_argument('--dec_name', type=str, help='DEC column name', nargs='?', default=None, const=None)
	args = parser.parse_args()

	file_in = fits.open(args.file)
	data = file_in[1].data
    
	if args.patch == 'N':
		mask = (data[args.dec_name] >= args.c)
	elif args.patch == 'S':
		mask = (data[args.dec_name] < args.c)
	else:
		raise ValueError('Patch label not recognised, use N or S')
    
	newdata = data[mask]
    
	hdu = fits.BinTableHDU(data=newdata)
	
	hdu.writeto(args.output_file, overwrite=True)
	print(f'Input catalogue split into {args.patch} patch!')

    
    
    
    
    
    
    

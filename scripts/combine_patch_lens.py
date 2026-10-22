  #!/usr/bin/env python
# -*- coding: utf-8 -*-
#=========================================
#
# File Name : combine_patch_lens.py
# Created By : Marika Asgari
# Creation Date : 22-10-2026
# Last Modified : 
#
#=========================================


# Combines two catalogues. Does not matter if they are lens or source catalouges as long as the have the same headings.
# This is relatively slow

from argparse import ArgumentParser
from astropy.table import Table, vstack

# fix this
parser = ArgumentParser(description='Combines two catalogues with the same headings into a single catalogue')
parser.add_argument('-i','--files', help='Input catalogues', nargs=2, default=None, const=None)
parser.add_argument('-o','--output_file', type=str, help='Output catalogue', nargs='?', default=None, const=None)
args = parser.parse_args()
print('input files are:',args.files)

cat_N_name= (args.files)[0]
cat_S_name= (args.files)[1]
print(cat_N_name, cat_S_name)
cat_NS_name = args.output_file
cat_N = Table.read(cat_N_name, format='fits')
cat_S = Table.read(cat_S_name, format='fits')
cat_NS = vstack((cat_N, cat_S))
cat_NS.write(cat_NS_name, format='fits', overwrite=True)


# Old script
# if __name__ == '__main__':
    
# 	parser = argparse.ArgumentParser(description='Combine N and S patches to a single lens catalogue')
# 	parser.add_argument('--files', type=[], help='Input catalogues', nargs=2, default=None, const=None)
# 	parser.add_argument('--output_file', type=str, help='Output catalogue', nargs='?', default=None, const=None)
# 	args = parser.parse_args()
    
# 	file_in1 = fits.open(args.files[0])
# 	file_in2 = fits.open(args.files[1])
# 	data1 = file_in1[1].data
# 	data2 = file_in2[1].data
    
# 	nrows1 = data1.shape[0]
# 	nrows2 = data2.shape[0]
# 	nrows = nrows1 + nrows2
    
# 	hdu = fits.BinTableHDU.from_columns(file_in1[1].columns, nrows=nrows)
# 	for colname in file_in1[1].columns.names:
# 		data1[colname][nrows1:] = data2[colname]

# 	hdu.writeto(args.output_file, overwrite=True)
# 	print(f'Input catalogue combined into NS patch!')

    
    
    

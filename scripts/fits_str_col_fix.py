#!/usr/bin/env python
"""
Convert any variable width string columns to fixed width string columns

Signature: fits_str_col_fix.py $infile $outfile
"""
import sys

import astropandas as apd
import mcal_functions as mcf
import pandas as pd

if len(sys.argv) != 3:
    raise ValueError("input and output file paths are required arguments")

modified=False
data, ldac_cat = mcf.flexible_read(sys.argv[1],as_df=True)
filetype = sys.argv[1].split(".")[-1]
if filetype == 'cat': 
    filetype = 'fits'

#If the data was read as a data frame (and so is not LDAC)
if isinstance(data, pd.DataFrame):
    #Check for bad columns 
    for col, dtype in zip(data.columns, data.dtypes):
        #Convert if needed
        if dtype.kind == "O":  # string columns are represented as python objects
            data[col] = data[col].astype("|S")  # required minimum width is determined automatically
            print("converted column '{:}' to data type '{:}'".format(col, data[col].dtype.str))
            modified=True
    
    #Write out the new catalogue (if needed) 
    if modified or filetype != 'fits': 
        apd.to_fits(data, sys.argv[2])


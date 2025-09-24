# ----------------------------------------------------------------
# File Name:           correct_cterm.py
# Author:              Angus H Wright (awright@astro.rub.de)
# Author:              Catherine Heymans (heymans@roe.ac.uk)
# Description:         short python script to apply a c-correction
# ----------------------------------------------------------------
import sys
import ldac
import numpy as np
from astropy.io import fits
from argparse import ArgumentParser

parser = ArgumentParser(description='Take input information and output a treecorr input catalogue ')
parser.add_argument("-i", "--inputfile", dest="inputfile",
    help="Full Input file name", metavar="inputFile",required=True)
parser.add_argument("-o", "--outputfile", dest="outputfile",
    help="Full Output file name", metavar="outputFile",required=True)
parser.add_argument('--e1name', dest="e1name", type=str,default='e1',
         help='Name of the e1 component in the catalogue')
parser.add_argument('--e2name', dest="e2name", type=str,default='e2',
         help='Name of the e2 component in the catalogue')
parser.add_argument('--psfe1name', dest="psfe1name", type=str,default='PSF_e1',
         help='Name of the PSF e1 component in the catalogue')
parser.add_argument('--psfe2name', dest="psfe2name", type=str,default='PSF_e2',
         help='Name of the PSF e2 component in the catalogue')
parser.add_argument('--wname', dest="wname", type=str,default='weight',
         help='Name of the weight in the catalogue')
parser.add_argument('--raname', dest="raname", type=str,default='ALPHA_J2000',
         help='Name of the RA column in the catalogue')
parser.add_argument('--decname', dest="decname", type=str,default='DELTA_J2000',
         help='Name of the Dec column in the catalogue')

args = parser.parse_args()
    
#open the ldac catalogue using functions in ldac.py
#tests have shown ldac.py is much faster than using astropy
ldac_cat = ldac.LDACCat(args.inputfile)
ldac_table = ldac_cat['OBJECTS']

#Ellipticity names 
e1colname=args.e1name
e2colname=args.e2name
#Weight name 
wtcolname=args.wname
#PSF Ellipticity names 
psfe1colname=args.psfe1name
psfe2colname=args.psfe2name
#RADec Names 
racolname=args.raname
deccolname=args.decname

#Select required columns 
e1=ldac_table[e1colname]
e2=ldac_table[e2colname]
weight=ldac_table[wtcolname]

# Lets also pass through the PSF ellipticity for star-gal-xcorr 
PSF_e1=ldac_table[psfe1colname]
PSF_e2=ldac_table[psfe2colname]

#RAdec names 
ra=ldac_table[racolname]
dec=ldac_table[deccolname]

#carry through the square of the weight for
#Npair calculation hack with Treecorr
wsq=weight*weight

if psfe1colname == e1colname:
    psfe1colname = psfe1colname + 'PSF'
if psfe2colname == e2colname:
    psfe2colname = psfe2colname + 'PSF'

#Write out to output file - crucial that RA/DEC (in degrees) are double precision
#If you don't have that you round to a couple of arcsec for fields with ra > 100
hdulist = fits.BinTableHDU.from_columns(
    [fits.Column(name=racolname, format='1D', unit='deg',array=ra),
     fits.Column(name=deccolname, format='1D', unit='deg',array=dec),
     fits.Column(name=e1colname, format='1E', array=e1),
     fits.Column(name=e2colname, format='1E', array=e2),
     fits.Column(name=psfe1colname, format='1E', array=PSF_e1),
     fits.Column(name=psfe2colname, format='1E', array=PSF_e2),
     fits.Column(name=wtcolname, format='1E', array=weight),
     fits.Column(name=wtcolname+'_sq', format='1E', array=wsq)])
hdulist.writeto(args.outputfile, overwrite=True)

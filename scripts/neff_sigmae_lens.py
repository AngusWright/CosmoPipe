import numpy as np
import sys
import ldac
import astropy.io.fits as pyfits
from argparse import ArgumentParser

parser = ArgumentParser(description='Compute neff and sigmae from user inputs')
parser.add_argument('-i','--input', dest="input", type=str,required=True,
         help='file for input catalogue')
parser.add_argument('--wname', dest="wname", type=str,default='weight',
         help='Name of the weight in the catalogue')
parser.add_argument('--area', dest="area", type=float,required=True,
         help='Area of the survey in square arcmin')

args = parser.parse_args()

wname = args.wname
try:
    catalogue=pyfits.open(args.input)[1].data
    if wname in ["None","none",""]:
        weight=1.0*catalogue.shape[0]
    else:
        weight=catalogue.field(args.wname)
except Exception:
    ldac_cat = ldac.LDACCat(args.input)
    catalogue = ldac_cat['OBJECTS']
    if wname in ["None","none",""]:
        weight=1.0*catalogue.shape[0]
    else:
        weight=catalogue[args.wname]

area=args.area

#m-bias values per tomographic bin
mbias_p1 = 1.0

print("# n_obj n_eff[1/arcmin^2]")

number = catalogue.shape[0]

n_eff = (
    np.sum( weight * mbias_p1    )**2 /
    np.sum((weight * mbias_p1)**2) /
    area)


print(number, n_eff)


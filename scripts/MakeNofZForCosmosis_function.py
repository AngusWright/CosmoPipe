

import sys
import os
import numpy as np
import pylab as plt
from   matplotlib.ticker import ScalarFormatter
import astropy.io.fits as pyfits
from argparse import ArgumentParser

def MakeNofz_fits(input_files,outputfileName,OneBin_nofzFileName,neff=[],single_bin=True,type='lowerEdge',suffix='SAMPLE'):
    #Expected cosmosis Nz file format is: 
    #NZDATA  = T          // This sentinel marks the extension as n(z) data
    #EXTNAME = NAME       // The name of this n(z) kernel.
    #NBIN    = 5          // Integer number of tomographic bins
    #NZ      = 100        // Integer number of histogram bins
    #The extension must then contain these data columns:
    
    #Z_LOW   8-byte real  // Real, the z value for the lower end of each redshift histogram bin
    #Z_MID   8-byte real  // Real, the z value for a middle point of each redshift histogram bin
    #Z_HIGH  8-byte real  // Real, the z value for the upper end of each redshift histogram bin
    #BIN1    8-byte real  // Real, the n(z) value for this histogram bin for the first tomographic bin
    #etc.    BIN2, BIN3, etc.
    nBins=len(input_files)
    print('I got '+str(nBins)+' files from input. Type is set to '+type)
    cols=[]
    for bin1 in range(nBins):
        if (".fits" in input_files[bin1]) == False:
            file= open(input_files[bin1])
            nofZ=np.loadtxt(file,comments='#')
        else: 
            nofZ=pyfits.open(input_files[bin1])[1].data
            nofZ=np.array([nofZ.field(0),nofZ.field(1)])
        if len(nofZ[:,1])<4: 
            nofZ=nofZ.transpose()
        if(bin1==0):
            if(single_bin):
                z_vec=nofZ[:,1]*neff[bin1]
            DeltaZ=nofZ[1,0]-nofZ[0,0]
            if(type=='lowerEdge'):
                Z_LOW=nofZ[:,0]
                Z_HIGH=nofZ[:,0]+DeltaZ
                Z_MID=Z_LOW+DeltaZ/2.
            elif(type=='middle'):
                Z_MID=nofZ[:,0]
                Z_LOW=nofZ[:,0]-DeltaZ/2.
                Z_HIGH=nofZ[:,0]+DeltaZ/2.
            elif(type=='upperEdge'):
                Z_HIGH=nofZ[:,0]
                Z_MID=nofZ[:,0]-DeltaZ/2.
                Z_LOW=nofZ[:,0]-DeltaZ
            else:
                print('not a recognised bin type, exiting now ...')
                exit(1)

            cols.append(pyfits.Column(name='Z_lOW', format='D', array=Z_LOW))
            cols.append(pyfits.Column(name='Z_HIGH', format='D', array=Z_HIGH))
            cols.append(pyfits.Column(name='Z_MID', format='D', array=Z_MID))
        else:
            if(single_bin):
                z_vec+=nofZ[:,1]*neff[bin1]
        cols.append(pyfits.Column(name='BIN'+str(bin1+1), format='D', array=nofZ[:,1]))

    new_cols = pyfits.ColDefs(cols)

    hdulist_new = pyfits.BinTableHDU.from_columns(new_cols)
    hdulist_new.header['NZDATA'] = True
    hdulist_new.header['EXTNAME'] = 'NZ_'+suffix
    hdulist_new.header['NBIN'] = nBins
    hdulist_new.header['NZ'] = len(Z_LOW)
    hdulist_new.writeto(outputfileName)
    # now one bin
    if(single_bin):
        cols = [] 
        cols.append(pyfits.Column(name='Z_lOW', format='D', array=Z_LOW))
        cols.append(pyfits.Column(name='Z_HIGH', format='D', array=Z_HIGH))
        cols.append(pyfits.Column(name='Z_MID', format='D', array=Z_MID))
        cols.append(pyfits.Column(name='BIN1', format='D', array=z_vec))
        new_cols = pyfits.ColDefs(cols)

        hdulist_new = pyfits.BinTableHDU.from_columns(new_cols)
        hdulist_new.header['NZDATA'] = True
        hdulist_new.header['EXTNAME'] = 'NZ_'+suffix
        hdulist_new.header['NBIN'] = 1
        hdulist_new.header['NZ'] = len(Z_LOW)
        outputfileName=OneBin_nofzFileName
        hdulist_new.writeto(outputfileName)


if __name__ == '__main__':

    parser = ArgumentParser(description='Construct the Nz file needed by cosmosis')
    parser.add_argument('--inputs', dest='inputs', type=str, required=True, help="input file names",nargs='+')
    #parser.add_argument('--neffs', dest='neffs', type=str, required=True, help="input neff file names",nargs='+')
    parser.add_argument('--neff', dest='neff', type=str, required=True, help="input neff file name")
    parser.add_argument('--output_base', dest='output_base', type=str, required=True, help="base for output filename")
    #parser.add_argument('--cat_version'  , dest='cat_version'  , type=str, required=True, help="Catalogue version")
    #parser.add_argument('--blinds'       , dest='blinds'       , type=str, required=True, help="Blinding variable")
    #parser.add_argument('--input_folder' , dest='input_folder' , type=str, required=True, help="folder containing inputs")
    #parser.add_argument('--nzfile_string', dest='nzfile_string', type=str, required=True, help="String designating the Nz files")
    parser.add_argument('--suffix', dest='suffix', type=str, required=True, help="String designating nz suffix (source, lens, obs)")
    
    args = parser.parse_args()
    
    inputs = args.inputs
    #neff_filenames = args.neffs
    neff_filename = args.neff
    output_base = args.output_base
    
    #nbins = args.nbins
    #cat_version_out = args.cat_version
    #cat_version_in  = args.cat_version
    #blinds = args.blinds
    #input_folder = args.input_folder
    #nzfile_string = args.nzfile_string
    
    #neff=[]
    #for fname in neff_filenames:
    #    neff_file=open(fname)
    #    neff.append(np.loadtxt(neff_file,comments='#'))

    neff_file=open(neff_filename)
    neff=np.loadtxt(neff_file,comments='#')
       
    print(neff)
    
    output_filename=output_base+'_comb_Nz.fits'
    onebin_output_filename=output_base+'_comb_single_bin_Nz.fits'
    MakeNofz_fits(input_files=inputs,
                  outputfileName=output_filename,
                  OneBin_nofzFileName=onebin_output_filename,
                  neff=neff,single_bin=False,type='lowerEdge',suffix=args.suffix)
    

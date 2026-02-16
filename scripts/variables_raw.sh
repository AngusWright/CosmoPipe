##
# 
# KiDS COSMOLOGY PIPELINE Configuration Variables 
# Written by A.H. Wright (2019-09-30) 
# Created by `whoami` (`date`)
#
##

##
# If you need to edit any paths, do so here and rerun the configure script
##

#Paths and variables for configuration
#Variables required for master installation 

#Pipeline that you wish to run
PIPELINE=test

#Pipeline that you wish to run
SURVEY=Euclid_TR1

#Root directory for pipeline scripts
PACKROOT=@PACKROOT@

#Date
DATE=`date`

#Username 
USER=`whoami`

#Machine type 
MACHINE=Linux_64

#Path to Rscript binary (can just be "Rscript" if you want $PATH to take charge)
P_RSCRIPT=Rscript 

#Define inplace sed command (different on OSX)
#P_SED_INPLACE='sed -i "" ' #Darwin
P_SED_INPLACE='sed -i ' #Linux 

#Colours 
RED='\033[0;31m' #Red 
BLU='\033[0;34m' #Blue 
DEF='\033[0m'    #Default


#Variables requires at pipeline compilation 

#Designation for "all patches" (Default is Euclid TR1)
ALLPATCH=LE3

#COSEBIs binning format; 'lin' or 'log' (Default is Euclid TR1)
BINNING='log'

#Blind identifier
BLINDING=UNBLIND

#Datablock directory
DATABLOCK=CosmoPipe_DataBlock

#Root directory for running pipeline
RUNROOT=@RUNROOT@

#Directory for runtime scripts (relative to RUNROOT)
RUNTIME=RUNTIME_${PIPELINE}

#Path to pipeline config files (relative to RUNTIME)
CONFIGPATH=${RUNTIME}/config

#Path for modified scripts (relative to RUNTIME)
SCRIPTPATH=${RUNTIME}/scripts

#Path for logfiles (relative to RUNTIME)
LOGPATH=${RUNTIME}/logs

#Path for manual files (relative to RUNTIME)
MANUALPATH=${RUNTIME}/man

#Path for outputs (relative to RUNROOT)
STORAGEPATH=work_${PIPELINE}/

#Nz file suffix
NZFILESUFFIX=_Nz.fits

#Path to python binary folder
PYTHON3BIN=`which python3`

#Super Sample Covariance Matrix: Matrix elements 
SSCMATRIX=@SSCMATRIX@
#Super Sample Covariance Matrix: ell bins 
SSCELLVEC=@SSCELLVEC@

#Name of the conda environment that cosmopipe installs 
CONDAPIPENAME=cosmopipe


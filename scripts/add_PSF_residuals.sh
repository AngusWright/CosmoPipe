#=========================================
#
# File Name : add_PSFSize_residuals.sh
# Created By : hendrik
# Creation Date : 02-03-2026
# Last Modified : Mon March 02 2026
#
#=========================================

#Catalogue(s) from DATAHEAD 
current=@DB:DATAHEAD@ 

#Construct file names for shape recalibration {{{
appendstr="_PSFR2"
#Define the file name extension
extn=${current##*.}
#Define the output file name 
outputname=${current//.${extn}/${appendstr}.${extn}}
#Construct the output catalogue filename 
catname=${outputname//.${extn}/.txt}
catname=${catname##*/}
#Check if the outputname file exists 
if [ -f ${outputname} ] 
then 
  #If it exists, remove it 
  _message " > @BLU@Removing previous catalogue for @RED@${current##*/}@DEF@"
  rm -f ${outputname}
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 
#}}}

#Add PSF size residuals {{{
_message " > @BLU@Adding PSF size residuals to @RED@${current##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/add_PSF_residuals.py\
    --inpath ${current} \
    --outpath ${outputname} \
    --mode @BV:PSFMODE@ \
    --PSF_table @BV:PSFTABLE@ 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

#Update the datahead {{{
_replace_datahead ${current} ${outputname}
#}}}



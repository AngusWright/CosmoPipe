#=========================================
#
# File Name : run_shape_recal.sh
# Created By : awright
# Creation Date : 26-05-2023
# Last Modified : Mon Mar 30 10:03:54 2026
#
#=========================================

#Catalogue(s) from DATAHEAD 
current=@DB:DATAHEAD@ 

#Construct file names for shape recalibration {{{
appendstr="_A2"
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
  _message " > @BLU@Removing previous alpha-correction (shape) catalogue for @RED@${current##*/}@DEF@"
  rm -f ${outputname}
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 
#}}}

#Check if input file lengths are ok {{{
links="FALSE"
for file in ${outputname} ${current} 
do 
  if [ ${#file} -gt 250 ] 
  then 
    links="TRUE"
  fi 
done 
#}}}

 #If needed, make the links {{{
if [ "${links}" == "TRUE" ] 
then 
  #Remove existing infile links 
  if [ -e infile_$$.lnk.cat ] || [ -h infile_$$.lnk.cat ]
  then 
    rm infile_$$.lnk.cat
  fi 
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk.cat ] || [ -h outfile_$$.lnk.cat ]
  then 
    rm outfile_$$.lnk.cat
  fi

  #Create input link
  originp=${current}
  ln -s ${current} infile_$$.lnk.cat
  current="infile_$$.lnk.cat"
  #Create output links 
  origout=${outputname}
  ln -s ${outputname} outfile_$$.lnk.cat
  origout=${outputname}
  outputname=outfile_$$.lnk.cat
fi 
#}}}

#Perform shape recalibration {{{
_message " > @BLU@Constructing shape-recalibrated catalogue for @RED@${current##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_shape_recal_nobin.py\
    --inpath ${current} \
    --outpath ${outputname}_tmp \
    --col_weight @BV:WEIGHTNAME@ \
    --cols_e12 @BV:E1NAME@ @BV:E2NAME@ \
    --cols_psf_e12 @BV:PSFE1NAME@ @BV:PSFE2NAME@ \
    --flagsource False --removeconst @BV:SHAPECAL_CTERM@ 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

# Merge recal columns {{{
_message "   > @BLU@Merging AlphaRecal columns in @RED@${current##*/}@DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i ${current} \
  -p ${outputname}_tmp \
  -o ${outputname}_tmp2 \
  -k AlphaRecalD2_alpha1 AlphaRecalD2_alpha2 AlphaRecalD2_const1 AlphaRecalD2_const2 AlphaRecalD2_alpha1_err AlphaRecalD2_alpha2_err AlphaRecalD2_const1_err AlphaRecalD2_const2_err @BV:E1NAME@_alphaRecal @BV:E2NAME@_alphaRecal flag_recal \
  -t OBJECTS 2>&1
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

# Filter sources
_message "   > @BLU@Filtering non shape-recalibrated sourcen in @RED@${current##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
          -i ${outputname}_tmp2 \
          -o ${outputname} \
          -t OBJECTS \
          -c "(flag_recal==1);" 2>&1 
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

#Remove the temporary files {{{
rm ${outputname}_tmp
rm ${outputname}_tmp2
#}}}
#If using links, remove them {{{
if [ "${links}" == "TRUE" ] 
then 
  rm ${current} ${outputname} 
  current=${originp}
  outputname=${origout}
fi

#Update the datahead {{{
_replace_datahead ${current} ${outputname}
#}}}



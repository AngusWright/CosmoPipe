#
# Correct the constant shear bias term for all files in DATAHEAD 
#

#Get the input filename 
current=@DB:DATAHEAD@

#Correct the constant shear term {{{
appendstr="_w2d"
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
  _message " > @BLU@Removing previous catalogue world_to_det catalogue for @RED@${current##*/}@DEF@"
  rm -f ${outputname}
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 
#Construct the output tomographic bin 
_message " > @BLU@Constructing world_to_det catalogue for @RED@${current##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/project_shapes_w2d.py \
  -i ${current} \
  -o ${outputname} \
  --id SeqNr \
  --e1name_det @BV:E1DETNAME@ \
  --e2name_det @BV:E2DETNAME@ \
  --e1name @BV:E1NAME@ \
  --e2name @BV:E2NAME@ \
  --jacobians @BV:JACOBIANS@ 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

#Remove pre-existing e12-det columns {{{
objstr=''
{
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${current} -t OBJECTS -k @BV:E1DETNAME@ 2>&1 && objstr="" || objstr="FAIL"
} >&1

if [ "${objstr}" == "" ] 
then 
  _message "  > @BLU@Removing previous {e1_det,e2_det} columns@DEF@"
  #Remove the original columns 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
    -i ${current} \
    -o ${current}_tmp \
    -k @BV:E1DETNAME@ @BV:E2DETNAME@ -t OBJECTS 2>&1
  mv ${current}_tmp ${current}
  _message "@RED@ - Done\n"
fi 
#}}}
#Merge new e12 columns {{{
_message "  > @BLU@Merging {e1_det,e2_det} columns@DEF@"
#Merge new E1E2 columns 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i ${current} \
  -p ${outputname} \
  -o ${outputname}_tmp \
  -k @BV:E1DETNAME@ @BV:E2DETNAME@ -t OBJECTS 2>&1
_message "@RED@ - Done\n"
#}}}

mv ${outputname}_tmp ${outputname}

#Update the datahead {{{
_replace_datahead ${current} ${outputname}
#}}}


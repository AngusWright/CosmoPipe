#=========================================
#
# File Name : combine_tomocats.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Fri 02 Aug 2024 08:25:10 AM CEST
#
#=========================================


#Get the DATAHEAD filelist 
input="@DB:ALLHEAD@" 

#Remove leading space
if [ "${input:0:1}" == " " ]
then
  input=${input:1}
fi

#Define the Z_B limits from the TOMOLIMS {{{
ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=1 '{print $n}'`
ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=1 '{print $(n+1)}'`
#}}}
#Define the string to append to the file names {{{
ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
binone_appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
#}}}

#Select all the bin-one catalogues 
binone_input=`echo ${input} | sed 's/ /\n/g' | grep ${binone_appendstr} || echo `

#Check for errors 
if [ "$binone_input" == "" ] 
then 
  _message "@RED@ - ERROR!\nThere are no bin-one catalogues?!"
  exit 1 
fi 

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
#For each bin-one catalogue: 
for file in ${binone_input}
do 
  #Get the tomographic file list for these catalogues 
  filelist=""
  for i in `seq ${NTOMO}`
  do
    #Define the Z_B limits from the TOMOLIMS {{{
    ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
    ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
    #}}}
    #Define the string to append to the file names {{{
    ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
    ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
    appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
    #}}}
    #Define the file name {{{
    catname=${file//${binone_appendstr}/${appendstr}}
    #}}}
    #Check if this filename is valid 
    if [ ! -f ${catname} ] 
    then 
      #Try without the tail 
      catname=${catname%${appendstr}*}
      #Glob for the filename 
      matchname=`compgen -G ${catname}* || echo`
      #If there is no file: 
      if [ "${matchname}" == "" ]
      then 
        _message "@RED@ - ERROR!\nThere is equivalent bin ${appendstr} catalogue for file ${file}?\n${matchname}@DEF@"
        exit 1 
      fi
      catname=${matchname}
    fi 

    filelist="${filelist} ${catname}"
  done 

  #Construct the output name 
  outputname=${file##*/}
  outputname=${outputname//${binone_appendstr}/}
  extn=${outputname##*.}
  outname=${outputname//.${extn}/_comb.${extn}}
  outname=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${outname} 
  
  #Check if input file lengths are ok 
  links="FALSE"
  for file in ${filelist} ${outname}
  do 
    if [ ${#file} -gt 255 ] 
    then 
      links="TRUE"
    fi 
  done 
  
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing outfile links 
    if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
    then 
      rm outfile_$$.lnk
    fi 
    count=1
    origlist=${filelist}
    filelist=''
    for file in ${origlist} 
    do 
      ln -s ${file} infile${count}_$$.lnk 
      filelist="${filelist} infile${count}_$$.lnk"
      count=$((count+1))
    done 
    #Create output links 
    ln -s ${outname} outfile_$$.lnk
    origoname=${outname}
    outname=outfile_$$.lnk
  fi 

  #Combine the DATAHEAD catalogues into one 
  _message "   > @BLU@Constructing combined catalogue @DEF@${outname##*/}@DEF@ "
  if [ ${NTOMO} == 1 ]
  then 
    touch ${outname}
    cp ${filelist} ${outname}
  else 
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste \
      -i ${filelist} \
      -o ${outname} 2>&1 
  fi 
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  if [ "${links}" == "TRUE" ] 
  then 
    if [ -s ${outname} ] 
    then 
      #Output file is a link
      rm ${filelist} ${outname}
    else 
      #Output file is a file, not a link 
      rm ${filelist} 
      mv ${outname} ${origoname}
    fi 
    filelist=${origlist}
    outname=${origoname}
  fi 

  #Update datahead 
  for _file in ${filelist}
  do 
    #Replace the first file with the output name, then clear the rest
    _replace_datahead ${_file} "${outname}"
    outname=""
  done 
done

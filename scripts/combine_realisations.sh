#=========================================
#
# File Name : combine_realisations.sh
# Created By : awright
# Creation Date : 30-06-2026
# Last Modified : Tue Jun 30 22:21:39 2026
#
#=========================================


#Get the DATAHEAD filelist 
all_input="@DB:ALLHEAD@" 

#Select all files with the _r1{_.} label
bases=`echo $all_input | sed 's/ /\n/g' | grep '_r1[._]'` 

#Initialise the allout object 
allout=

for base in ${bases} 
do 

  #Get all the inputs that match the base 
  ext=${base##*.}
  base=${base%_r1[._]*}
  input=`echo $all_input | sed 's/ /\n/g' | grep "${base}[._]" | sed 's/\n/ /g'`
  #Check if there is more than one file in the datahead 
  nfile=`echo ${input} | awk '{print NF}'` 
  if [ ${nfile} -gt 1 ] 
  then 
    #Get the output name from the base file 
    output=${base}
    output=${output##*/}
    #First file extension 
    ext=${output##*.}
    #Get the part we want to use 
    output=${output%_r1[._]*}
    
    #Construct the output name 
    outname=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${output}_comb.${ext}
  
    #Check if input file lengths are ok {{{
    links="FALSE"
    for file in ${input} ${outname}
    do 
      if [ ${#file} -gt 255 ] 
      then 
        links="TRUE"
      fi 
    done 
    
    if [ "${links}" == "TRUE" ] 
    then
      #Remove existing infile links 
      if [ -e infile_$$.lnk ] || [ -h infile_$$.lnk ]
      then 
        rm infile_$$.lnk
      fi 
      #Remove existing outfile links 
      if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
      then 
        rm outfile_$$.lnk
      fi
      #Create input link
      originp=${input}
      input=''
      count=0
      for file in ${originp}
      do 
        ((count+=1))
        ln -s ${file} infile_$$_$count.lnk 
        input="${input} infile_$$_$count.lnk"
      done 
      #Create output links 
      ln -s ${outname} outfile_$$.lnk
      origout=${outname}
      outname=outfile_$$.lnk
    fi 
    #}}}
  
    count=0
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i `echo ${input} | awk '{print $1}'` -t OBJECTS > tmp 2> /dev/null 
    for file in ${input} 
    do 
      ((count+=1))
      _message "\r   > @BLU@Checking files have common format: @RED@$((count))@BLU@ of @RED@$nfile@DEF@ "
      @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i `echo ${input} | awk -v n=$count '{print $n}'` -t OBJECTS > tmp2 2> /dev/null 
      ndiff=`diff tmp tmp2 | wc -l`
      if [ ${ndiff} -gt 0 ] 
      then 
         _message " @RED@- ERROR: formats differ!\n@DEF@ `echo ${input} | awk -v n=$count '{print $n}'`\n"
         exit 1 
      fi 
    done 
    _message " @RED@- Done@DEF@\n" 
    
    if [ ${nfile} -gt 1020 ] 
    then 
      count=0
      endlist=""
      while [ $count -lt $nfile ]
      do 
        tmpind=`seq -s ' ' $((count+1)) $((count+1000))`
        tmplist=`echo $input | cut -d ' ' -f "$tmpind"`
        echo ${tmplist} | awk '{print NF}' 
        outtmp=${outname}_${count}_tmp
        endlist="${endlist} ${outname}_${count}_tmp"
        _message "   > @BLU@Constructing intermediate combined catalogue with files @RED@$((count+1))@BLU@-@RED@$((count+1000))@BLU@ of @RED@$nfile@DEF@ "
        @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste \
          -i ${tmplist} \
          -o ${outtmp} 2>&1 
        _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
        ((count+=1000))
      done 
      #Combine the DATAHEAD catalogues into one 
      _message "   > @BLU@Constructing final combined catalogue @DEF@${outname}@DEF@ "
      @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste \
        -i ${endlist} \
        -o ${outname} 2>&1 
      _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
    else 
      #Combine the DATAHEAD catalogues into one 
      _message "   > @BLU@Constructing combined catalogue @DEF@${outname}@DEF@ "
      @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste \
        -i ${input} \
        -o ${outname} 2>&1 
      _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
    fi
  
    #If using links, replace them {{{
    if [ "${links}" == "TRUE" ] 
    then 
      rm ${input} ${outname}
      input=${originp}
      outname=${origout}
    fi 
    #}}}
    
    allout="${allout} ${outname##*/}"
  
    for _file in ${input}
    do 
      #Remove the input files 
      rm -f ${_file}
    done 
  else 
    _message "   > @BLU@There is only @RED@1 file@BLU@ in the DATAHEAD: @DEF@nothing to do!\n@DEF@"
  fi 
  
done

#Update datahead 
_replace_datahead "${all_input}" "$allout"


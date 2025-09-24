#
# Add the lens catalogue to the data block
#

#If needed, make the simulations folder 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_main/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_main
fi

#Check that the main catalogue(s) exists
if [ -d @BV:LENSMAINCAT@ ]
then
  inputlist=`ls @BV:LENSMAINCAT@`
  filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist} 
  do 
    #Construct the output name {{{
    outname=${file##*/}
    #}}}
    #Save the output file to the list {{{
    filelist="$filelist @BV:LENSMAINCAT@/$outname"
    #}}}
  done 
elif [ -f @BV:LENSMAINCAT@ ]
then
  filelist=@BV:LENSMAINCAT@
  outname=${filelist##*/}
else
  _message "${RED} - ERROR: Main lens catalogue @BV:LENSMAINCAT@ does not exist!"
  exit -1
fi 

#Update the datablock contents file 
_add_datablock lens_main "$filelist"

#Get the number of catalogues 
nlens=`echo ${filelist} | awk '{print NF}'`
#Add the NLENSCATS variable to the datablock
_write_blockvars "NLENSCATS" "${nlens}"

#Create the LENS_CATS block variable
_write_blockvars "LENS_MAIN" "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_main/${outname}"



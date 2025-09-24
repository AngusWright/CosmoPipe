#
# Add the lens catalogue to the data block
#

#If needed, make the simulations folder 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/rand_main/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/rand_main
fi

#Check that the main catalogue(s) exists
if [ -d @BV:RANDMAINCAT@ ]
then
  inputlist=`ls @BV:RANDMAINCAT@`
  filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist} 
  do 
    #Construct the output name {{{
    outname=${file##*/}
    #}}}
    #Save the output file to the list {{{
    filelist="$filelist @BV:RANDMAINCAT@/$outname"
    #}}}
  done 
elif [ -f @BV:RANDMAINCAT@ ]
then
  filelist=@BV:RANDMAINCAT@
  outname=${filelist##*/}
else
  _message "${RED} - ERROR: Main randoms catalogue @BV:RANDMAINCAT@ does not exist!"
  exit -1
fi 

#Update the datablock contents file 
_add_datablock rand_main "$filelist"

#Get the number of catalogues 
nrand=`echo ${filelist} | awk '{print NF}'`
#Add the NLENSCATS variable to the datablock
_write_blockvars "NRANDCATS" "${nrand}"

#Create the RAND_CATS block variable
_write_blockvars "RAND_MAIN" "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/rand_main/${outname}"

#=========================================
#
# File Name : specz_som.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Mon Jul 21 12:22:12 2025
#
#=========================================


#Construct the SOM 
outname=@DB:DATAHEAD@
outname=${outname##*/}
outext=${outname##*.}
#Add the calib weight name if it exists
if [ "@BV:CALIBWEIGHTNAME@" == "" ]
then 
  calibweightname=''
else
  calibweightname='-ct @BV:CALIBWEIGHTNAME@'
fi 
#Add sparse option if requested 
if [ "@BV:SPARSEFRAC@" == "" ]
then 
  sparsefrac=''
else
  sparsefrac='--sparse.som @BV:SPARSEFRAC@'
fi 
#Notify
_message "@BLU@ > Constructing a SOM for @DEF@${outname}@DEF@"
@P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
  -r none \
  -t @DB:DATAHEAD@ \
  @BV:TOROIDAL@ --topo @BV:TOPOLOGY@ @BV:UNWHITEN_FEATURES@ \
  --som.dim @BV:SOMDIM@ -np -fn Inf \
  --data.threshold @BV:DATATHRESHOLD@ \
  ${calibweightname} ${sparsefrac} \
  --data.missing -99 @BV:ADDITIONALFLAGS@ \
  -sc @BV:NTHREADS@ --som.iter @BV:NITER@ --only.som \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -of ${outname} \
  --zr.label @BV:ZPHOTNAME@ --zt.label @BV:ZSPECNAME@ \
  -k @BV:SOMFEATURES@ 2>&1 

#Notify
_message "@RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the new file to the datablock 
#_add_datablock som CosmoPipeSOM_SOMdata.Rdata
_replace_datahead @DB:DATAHEAD@ ${outname//.${outext}/_SOMdata.Rdata}


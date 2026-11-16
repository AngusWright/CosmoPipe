##
# 
# KiDS COSMOLOGY PIPELINE Configuration
# Written by A.H. Wright (2019-09-30) 
# Created by @USER@ (@DATE@)
#
##

##
# Variables and paths should not be editted here! 
# - Change variables in the variables.sh file
# - Change pipeline formats in the pipeline.sh file 
##

set -e 

#Source the Script Documentation Functions {{{
source @PACKROOT@/man/CosmoPipe.man.sh
source @PACKROOT@/man/${0//.sh/.man.sh} 
#}}}

#Get the option list {{{
OPTLIST=`_get_optlist @RUNROOT@/variables.sh`
##Compute NTOMOBINS
#NTOMOBINS=`echo ${TOMOLIMS} | awk '{print NF-1}'`
##Add NTOMOBINS to OPTLIST variables 
#OPTLIST=`echo $OPTLIST NTOMOBINS`
#}}}

#Paths and variables for configuration {{{
source @RUNROOT@/variables.sh
#}}}

#Prompt {{{
_prompt ${VERBOSE}
#}}}

#Variable Check {{{
_varcheck $0
#}}}

#Read command line options  {{{
pipeline_only=FALSE
recheck=FALSE
useauto=FALSE
resume=""
resumenum='0'
while [ $# -gt 0 ] 
do 
  case ${1,,} in 
    "--pipeline-olny") 
      pipeline_only=TRUE
      echo "Nice typing bro. olny!=only (smh)" 
      shift 
      ;; 
    "--pipeline-only") 
      pipeline_only=TRUE
      shift 
      ;; 
    "--pipeline_only") 
      pipeline_only=TRUE
      shift 
      ;; 
    "--resume") 
      resume="--resume" 
      shift
      if [ $# -gt 0 ] 
      then 
        re='^[0-9]+$'
        if [[ ${1:0:1} =~ $re ]]
        then 
          resumenum=$1
          shift 
        elif [ "${1^^}" == "AUTO" ]
        then 
          useauto=TRUE
          shift
        fi 
      fi
      ;; 
    "--*")
      echo "Unknown command line option: $1"
      exit 1
      ;; 
    *)
      if [ "$1" != "${PIPELINE}" ] 
      then 
        ${P_SED_INPLACE} "s/^PIPELINE=/PIPELINE=${1} #/" @RUNROOT@/variables.sh
        PIPELINE=$1
        recheck=TRUE
      fi 
      shift
      ;;
  esac
done 
if [ "${recheck}" == "TRUE" ] 
then 
  source @RUNROOT@/variables.sh 
fi 
if [ "${useauto}" == "TRUE" ]
then 
  step=`ls -tr ${RUNROOT}/${LOGPATH}/step* | tail -1 | awk -F/ '{print $NF}' | awk -F_ '{print $2}'`
  resumenum=${step}
fi 
#}}}

if [ "${pipeline_only}" == "FALSE" ]
then 
  
  #Remove any previous pipeline versions {{{
  if [ -d ${RUNROOT}/${RUNTIME} ]
  then 
    _message "   >${RED} Removing previous configuration scripts ${DEF}" 
    rm -fr ${RUNROOT}/${SCRIPTPATH}
    _message "${BLU} - Done! ${DEF}\n"
    _message "   >${RED} Removing previous configuration manual files ${DEF}" 
    rm -fr ${RUNROOT}/${MANUALPATH}
    _message "${BLU} - Done! ${DEF}\n"
    _message "   >${RED} Removing previous configuration configs ${DEF}" 
    rm -fr ${RUNROOT}/${CONFIGPATH}
    _message "${BLU} - Done! ${DEF}\n"
    if [ "${resume}" == "" ] 
    then 
      _message "   >${RED} Removing previous configuration log files ${DEF}" 
      rm -fr ${RUNROOT}/${LOGPATH}
      _message "${BLU} - Done! ${DEF}\n"
    fi 
  else 
    mkdir -p ${RUNROOT}/${RUNTIME}
  fi 
  #}}}
  
  #Make and populate the runtime scripts directory {{{
  _message "   >${RED} Copying Provided Data Products to Storage Path${DEF}" 
  mkdir -p ${RUNROOT}/${STORAGEPATH}/${DATABLOCK}/DATAHEAD
  rsync -autv ${PACKROOT}/data/* ${RUNROOT}/${STORAGEPATH}/ > ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
  _message "${BLU} - Done! ${DEF}\n"
  _message "   >${RED} Copying scripts & configs to Run directory${DEF}" 
  mkdir -p ${RUNROOT}/${LOGPATH}/
  rsync -autv ${PACKROOT}/scripts/* ${RUNROOT}/${SCRIPTPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
  rsync -autv ${PACKROOT}/config/* ${RUNROOT}/${CONFIGPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
  rsync -autv ${PACKROOT}/man/* ${RUNROOT}/${MANUALPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
  _message "${BLU} - Done! ${DEF}\n"
  # _message "   >${RED} Copying post processing scripts to Run directory${DEF}" 
  # rsync -autvz ${RUNROOT}/INSTALL/post_process_mcmcs/make_all.py ${RUNROOT}/${SCRIPTPATH}/ \
  #   >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
  # _message "${BLU} - Done! ${DEF}\n"
  cd ${RUNROOT}
  #}}}
  
  ##Make a copy of the CosmoFisherForecast Repository {{{
  #mkdir -p ${RUNROOT}/${SCRIPTPATH}/CosmoFisherForecast
  #cp -rf ${COSMOFISHER}/* ${RUNROOT}/${SCRIPTPATH}/CosmoFisherForecast/
  ##}}}
  
  ##Convert Survey area from arcmin to deg {{{
  #SURVEYAREADEG="`awk -v s=${SURVEYAREA} 'BEGIN { printf "%.4f", s/3600.0 }'`"
  ##Add derived quantity to option list 
  #OPTLIST=`echo $OPTLIST SURVEYAREADEG`
  ##}}}
  
  #Update the runtime scripts with the relevant paths & variables {{{
  scripts=`find ${RUNROOT}/${SCRIPTPATH} -mindepth 1 -maxdepth 1 -type f`
  configs=`find ${RUNROOT}/${CONFIGPATH} -mindepth 1 -type f`
  manuals=`find ${RUNROOT}/${MANUALPATH} -mindepth 1 -maxdepth 1 -type f`
  #Only update files that contain varables 
  scripts=`grep -c "@" ${scripts} | grep -v ":0" | awk -F: '{print $1}'` 
  configs=`grep -c "@" ${configs} | grep -v ":0" | awk -F: '{print $1}'` 
  manuals=`grep -c "@" ${manuals} | grep -v ":0" | awk -F: '{print $1}'` 
  #Get the number of files 
  nscript=`echo ${scripts} | awk '{print NF}'`
  nconf=`echo ${configs} | awk '{print NF}'`
  nman=`echo ${manuals} | awk '{print NF}'`
  nfile=$((nscript+nconf+nman))
  _message "   >${RED} Modify Runtime Scripts for ${nfile} files (${nscript}+${nconf}+${nman})${DEF}" 
  for OPT in $OPTLIST
  do 
    ${P_SED_INPLACE} "s#\\@${OPT}\\@#${!OPT//\\/\\\\}#g" ${scripts} ${configs} ${manuals} 
  done 
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
fi 

#Check if a pipeline file exists {{{
for pipe in ${PIPELINE}
do 
  if [ -f ${pipe}_pipeline.sh ]
  then 
    _message "   >${RED} Removing Existing Pipeline ${pipe} ${DEF}"
    rm -f ${pipe}_pipeline.sh
    _message "${BLU} - Done! ${DEF}\n"
  fi 
done 
#}}}

#Create the pipeline, & update the runtime scripts with the relevant paths & variables {{{
if [ "${resume}" == "" ] 
then 
  resumenum=''
fi 
for pipe in ${PIPELINE}
do 
  _message "   >${RED} Constructing Pipeline ${pipe} ${DEF}" 
  PIPELINE=${pipe} VERBOSE=0 bash ${RUNROOT}/${SCRIPTPATH}/construct_pipeline.sh ${RUNROOT}/pipeline.ini ${resume} ${resumenum} > ${pipe}_pipeline.log
  _message "${BLU} - Done! ${DEF}\n"
  _message "   ${BLU} Pipeline viewer: ${DEF}${RUNROOT}/${pipe}_graph.html\n"
done 
#}}}

#Set the pipeline file to read and execute only
for pipe in ${PIPELINE}
do 
  chmod a-w ${RUNROOT}/${pipe}_pipeline.sh
done 

#Finish 
_message "   >${RED} Finished! To run the Cosmology pipeline, check cosmosis is configured (source cosmosis-configure) and run: ${DEF}\n"
for pipe in ${PIPELINE}
do 
  _message "   ${BLU} bash ${pipe}_pipeline.sh ${DEF} (from within the 'cosmopipe' conda env), or:\n"
  _message "   ${BLU} conda run -n ${CONDAPIPENAME} --no-capture-output bash ${pipe}_pipeline.sh ${DEF} (from anywhere).\n"
done

trap : 0

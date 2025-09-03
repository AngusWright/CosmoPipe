#
# Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  if [ "$1" != "0" ] 
  then 
    _message "\n${BLU}=====================================================${DEF}\n"
    _message "${BLU}== ${RED}     Cosmology Pipeline Construction Mode      ${BLU} ==${DEF}\n"
    _message "${BLU}=====================================================${DEF}\n\n"
    _message "Constructing the pipeline ${RED}${PIPELINE}${DEF} from the configuration file:\n"
    _message "${BLU}${RUNROOT}/${SCRIPTPATH}/pipeline.ini${DEF}\n\n"
  fi 
}
#}}}

# Abort Message {{{
_abort()
{
  _message "${RED} - !FAILED!\n" 
  _message "${BLU} An error occured while running $0.\n" 
  _message "${DEF} Check the relevant logging file for this step.\n" 
  trap : 0
  exit 1
}
trap '_abort' 0
set -e 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo 
} 
#}}}

# Input variables {{{ 
function _inp_var { 
  #Variable inputs (leave blank if none)
  echo 
} 
#}}}

# Output data {{{ 
function _outputs { 
  #NONE
  echo 
} 
#}}}

#Additional Functions 

#Read pipeline {{{
function _read_pipe { 
  #Pipeline file location 
  _PIPELOC=${RUNROOT}/pipeline.ini
  cp ${_PIPELOC} ${RUNROOT}/${STORAGEPATH}/pipeline.ini
  if [ -e ${RUNROOT}/subroutines.ini ] 
  then 
    cat ${RUNROOT}/subroutines.ini >> ${RUNROOT}/${STORAGEPATH}/pipeline.ini
  fi 
  #Now use the combined pipeline file 
  _PIPELOC=${RUNROOT}/${STORAGEPATH}/pipeline.ini
  #Step & step number 
  _step=${1}
  _stepnum=''
  #If there is a number provided, use that: 
  if [ "${2}" != "" ] 
  then 
    #Use substep numbering if stepnum is provided
    _stepnum="${2}."
  fi 
  #Check for the number of pipelines with this name, and continue if 0
  _npipe=`grep -Ev "^[[:space:]]{0,}#" ${_PIPELOC} | grep -Fc --ignore-case "${_step}:" | xargs echo `
  #>&2 echo "Number of pipelines: ${_npipe}"
  if [ "${_npipe}" == "0" ]
  then 
    _message "${RED} - ERROR${DEF}\n\n"
    _message "${RED}ERROR: There is no pipeline called ${_step} in the pipeline script:\n"
    _message "${BLU}       ${_PIPELOC}${DEF}\n"
    exit 1
  elif [ "${_npipe}" != "1" ]
  then 
    _message "${RED} - ERROR${DEF}\n\n"
    _message "${RED}ERROR: There is more than one pipeline called ${_step} in the pipeline script! There are ${_npipe}.\n"
    _message "${BLU}       ${_PIPELOC}${DEF}\n"
    exit 1
  fi
  #Create the steps with numbering 
  grep -Ev "^[[:space:]]{0,}#" ${_PIPELOC} | awk -v S="${_stepnum}" -v pipe="${_step}:" -v seen="F" -v count=0 -v SQ="'" -v DQ='"' '{
    if ($1 == "" ) next
    if ($1 != pipe && seen == "F") {
      next
    } else if ($1 == pipe) {
      seen="T"
    }
    #If we arrive at the next block, break
    if (substr($1,length($1),1) == ":" && $1 != pipe) {
      seen="F"
      next
    }
    #Here we are at a line in our desired pipeline
    inquote="F"
    #For each element in the line 
    for(i=1; i<=NF; i++) {
      gsub(SQ,DQ,$i)
      #If we are inside a quotation: 
      if (inquote=="T") { 
        #Check for the ending quotation mark 
        res=match($i,quotemark)
        if (res==0) { 
          #If not found, add this item to the quote string
          quotestring=quotestring "," $i 
        } else { 
          #If found, add this item to the quote string, print
          print quotestring "," $i "=_"
          #End the quotation mode 
          inquote="F"
        }
      } else { 
        #We are not in a quotation 
        #If we are processing further entries on a line (i!=1) or are not at the pipeline ID ($ != :)
        #(this allows pipelines to be specified on a single line) 
        if (i!=1 || substr($i,length($i),1)!=":") {
          #Check for leading activation characters 
          if (substr($i,1,1) == "@" || substr($i,1,1) == "!" || substr($i,1,1) == "%" ) {
            #Block manipulations: Step has no number; print and continue 
            print $i "=_"
          } else if ( $i == "RESUME") {
            print $i 
          } else if (substr($i,1,1) == "+") {
            #Step is a variable assignment 
            #Check for the quotation mark type 
            res=match($i,SQ)
            if (res==0) { 
              quotemark=DQ
            } else { 
              quotemark=SQ
            }
            #Move RSTART to beginning of variable content
            match($i,"=")
            #Check for the number of quotation marks 
            match($i,quotemark)
            if (substr($i,RSTART,1)==quotemark) { 
              #Is there another quotemark 
              res=match(substr($i,RSTART+1),quotemark)
              if (res==0) { 
                #This is a list: activate quotation mode and continue
                inquote="T"
                quotestring=$i
              } else { 
                #This is a single item in quotes 
                print $i "=_"
              }
            } else { 
              #This is a single element:print and continue
              print $i "=_"
            }
          } else if (substr($i,1,1) == "#") {
            #This is a comment 
            next
          } else {
            #Add (sub)step number
            count+=1
            print $i "=" S count
          }
        }
      }
    }
  }' | awk '{printf "%s ", $0}' 
  #grep -Ev "^[[:space:]]{0,}#" ${_PIPELOC} | grep --ignore-case "${1}:" | awk -F: '{print $2}' | \
  #  awk -v S=${_stepnum} '{
  #    count=0 
  #    for(i=1; i<=NF; i++) 
  #      if (substr($i,1,1) == "@" || substr($i,1,1) == "!") {
  #        #Step has no number 
  #        print $i "=_" 
  #      } else {
  #        #Add (sub)step number
  #        count+=1
  #        print $i "=" S count
  #      }
  #    }' | xargs echo 
} 
#}}}

#Pipeline Opening Prompt {{{
function _openingprompt { 
  _banner="===================================="
  echo "echo -e \"@BLU@==============${_banner:0:${#PIPELINE}}===================@DEF@\""
  echo "echo -e \"@BLU@== @RED@ CosmoPipe Pipeline File: ${PIPELINE} @BLU@ ==@DEF@\""
  echo "echo -e \"@BLU@==============${_banner:0:${#PIPELINE}}===================@DEF@\""
  echo  
}
#}}}

#Pipeline Closing Prompt {{{
function _closingprompt { 
  echo 
  echo "echo -e \"@BLU@====================================@DEF@\""
  echo "echo -e \"@BLU@== @RED@ CosmoPipe Pipeline Finished! @BLU@ ==@DEF@\""
  echo "echo -e \"@BLU@====================================@DEF@\""
}
#}}}



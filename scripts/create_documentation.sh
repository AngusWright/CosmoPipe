#
# Script to generate an initial documentation file for an input script
#

#Input script name 
script=${1##*/}
#Script extension
ext=${script##*.}
#Documentation name 
docu=${script//.${ext}/.man.sh}

#Generate the file header {{{
cat > $docu << EOF 
#
# $script Documentation & Housekeeping functions
#

EOF
#}}}

#Starting prompt {{{
_banner="======================================================"
cat >> $docu << EOF 
#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "\$1" != "0" ] 
  then
    _message "@BLU@============${_banner:0:${#script}}=========@DEF@\n"
    _message "@BLU@== @RED@ Running ${script} Mode @BLU@ ==@DEF@\n"
    _message "@BLU@============${_banner:0:${#script}}=========@DEF@\n"
  fi 
}
#}}}

EOF
#}}}

#Read the description from user  {{{
read -p "A brief description of what this script does: (press Enter when finished) " desc
#}}}

#Reformat the user description {{{
nchar=${#desc}
n=0
while [ $n -le $nchar ]
do 
  #Select a 50 char chunk
  ntmp=$((n+50))
  #Check if the last character is a space 
  if [ "${desc:$ntmp:1}" == " " ]
  then 
    nnew=50
  else 
    #If not, is the line shorter than 50 characters?
    _tmpstring=${desc:$n:50}
    if [ ${#_tmpstring} -lt 50 ] 
    then 
      nnew=50
    else 
      #If not, truncate the line to the last whitespace
      #Trim back to the last whitespace
      _tmpstring=${_tmpstring##* }
      #Next line is the chunk up to the whitespace
      nnew=$((50-${#_tmpstring}))
      echo $nnew
    fi
  fi 
  docstring="${docstring}  echo '# ${desc:$n:$nnew}'\n"
  n=$((n+nnew))
done
#}}}

#Description {{{
cat >> $docu << EOF 
#Mode description {{{
function _description { 
  echo "#"
`echo -e "$docstring"`
  echo "#"
  echo "# Function takes input data:"
  echo "# \`_inp_data\`"
  echo "#"
}
#}}}

EOF
#}}}

#Abort message {{{
cat >> $docu << EOF 
# Abort Message {{{
_abort()
{
  #Message to print when script aborts 
  #\$0 is the script that was running when this error occurred
  _message "@BLU@ An error occured while running:\n@DEF@\$0.\n" >&2
  _message "@BLU@ Check the logging file for this step in:\n" >&2
  _message "@DEF@@RUNROOT@/@LOGPATH@/\n" >&2
  exit 1
}
trap '_abort' 0
set -e 
#}}}

EOF
#}}}

#Construct the list of variables present in this script {{{
#variables=`cat $1 | grep -Ev "^[[:space:]]{0,}#" | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
#  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `
variables=$(grep -Ev '^[[:space:]]*#' "$1" \
  | grep "@" \
  | sed 's/\(@.*@\)/\n\1\n/g' \
  | grep "@" \
  | awk -F@ '{s=""; for (i=2;i<=NF;i+=2) {s=s ? s "\n" $i : $i} print s }' \
  | grep -v "^$" \
  | sort -u \
  | grep -v "DB:" \
  | xargs echo)

#If there is a python script, add the variables from that too
if [ -f ${script/.${ext}/.py} ]
then 
  variables="${variables} `cat ${script/.${ext}/.py} | grep -Ev "^[[:space:]]{0,}#" | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
fi 
#If there is a cosmosis .ini file, add the variables from that too 
inifile=${script/.${ext}/.ini}
inifile=../config/${inifile}
echo ${inifile}
if [ -f ${inifile} ]
then 
  #variables="${variables} `cat ${inifile} | grep -Ev "^[[:space:]]{0,}#" | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
  #awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
  variables="${variables} $(grep -Ev '^[[:space:]]*#' "${script/.${ext}/.py}" \
  | grep "@" \
  | sed 's/\(@.*@\)/\n\1\n/g' \
  | grep "@" \
  | awk -F@ '{s=""; for (i=2;i<=NF;i+=2) {s=s ? s "\n" $i : $i} print s }' \
  | grep -v "^$" \
  | sort -u \
  | grep -v "DB:" \
  | xargs echo)"

fi 
#If there is an R script, add the variables from that too
if [ -f ${script/.${ext}/.R} ]
then 
  #variables="${variables} `cat ${script/.${ext}/.R} | grep -Ev "^[[:space:]]{0,}#" | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
  #awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
  variables="${variables} $(grep -Ev '^[[:space:]]*#' "${script/.${ext}/.R}" \
  | grep "@" \
  | sed 's/\(@.*@\)/\n\1\n/g' \
  | grep "@" \
  | awk -F@ '{s=""; for (i=2;i<=NF;i+=2) {s=s ? s "\n" $i : $i} print s }' \
  | grep -v "^$" \
  | sort -u \
  | grep -v "DB:" \
  | xargs echo)"

fi 
variables=`echo ${variables} | tr " " "\n" | sort | uniq | xargs echo`
#}}}

cat >> $docu << EOF 
# Input variables {{{ 
function _inp_var { 
  #Variable inputs (leave blank if none)
  echo $variables
} 
#}}}

EOF

#Construct the list of DB variables present in this script {{{
#variables=`cat $1 | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
#  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep "DB:" | sed 's/DB://g' | xargs echo `
variables=$(grep "@" "$1" \
  | sed 's/\(@.*@\)/\n\1\n/g' \
  | grep "@" \
  | awk -F@ '{s=""; for (i=2;i<=NF;i+=2) {s=s ? s "\n" $i : $i} print s }' \
  | grep -v "^$" \
  | sort -u \
  | grep "DB:" \
  | sed 's/DB://g' \
  | xargs echo)
variables=`echo ${variables} | tr " " "\n" | sort | uniq | xargs echo`
#}}}

#Read the input data from user  {{{
read -p "A list of the input data to this script: (def: '$variables') " inputs
#}}}

if [ "$inputs" == "" ] 
then 
  inputs="${variables}"
fi 

cat >> $docu << EOF 
# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo $inputs
} 
#}}}

EOF

#Read the output data from user  {{{
read -p "A list of the output data produced by this script: (def: '$variables') " outputs
#}}}

if [ "$outputs" == "" ] 
then 
  outputs="${variables}"
fi 

cat >> $docu << EOF 
# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  echo $outputs
} 
#}}}

EOF

#Read the execution command from the user  {{{
read -p "How is the script executed (blank -> 'bash @RUNROOT@/@SCRIPTPATH@/$script'): " runcommand
#}}}

if [ "$runcommand" == "" ] 
then 
  runcommand="bash @RUNROOT@/@SCRIPTPATH@/$script"
fi 

if [ "$runcommand" == "cosmosis" ] 
then 
  runcommand="mpirun -n @BV:NTHREADS@ --env MKL_NUM_THREADS 1 --env NUMEXPR_NUM_THREADS 1 --env OMP_NUM_THREADS 1 @PYTHON3BIN@/cosmosis --mpi @RUNROOT@/@CONFIGPATH@/${script//.${ext}/.ini}"
fi 

cat >> $docu << EOF 
# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo ${runcommand}
} 
#}}}

EOF

cat >> $docu << EOF 
# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

EOF
cat >> $docu << EOF 
#Additional Functions 

EOF

mv $docu ../man/

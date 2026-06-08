#=========================================
#
# File Name : construct_manual.sh
# Created By : awright
# Creation Date : 01-10-2024
# Last Modified : Mon Feb 16 12:34:56 2026
#
#=========================================


source ../man/CosmoPipe.man.sh 

if [ ! -d ../tex ]
then 
  mkdir ../tex 
fi 

if [ ! -d ../history ]
then 
  mkdir ../history
fi 



cat CosmoPipe_frontmatter.tex | sed "s/@DATE@/`date`/" > ../tex/CosmoPipe_manual.tex 
echo > ../tex/sections.tex 

for file in `ls ../scripts/*.sh` 
do 
  file=${file##*/}
  #if [ -f ../tex/${file//.sh/.tex} ] 
  #then 
  #  continue
  #fi 
  #Define the manual file name 
  man_file=../man/${file//.sh/.man.sh} 
  if [ ! -f ${man_file} ] 
  then 
    echo "manual does not exist for file ${file}! Skipping!"
    continue
  fi 
  #Check if this file is tracked 
  git ls-files --error-unmatch ../scripts/${file} >/dev/null 2>&1 || tracked=FALSE && tracked=TRUE 
  if [ "${tracked}" == "FALSE" ] 
  then 
    echo "File ${file} isn't tracked by git: skipping"
    continue 
  fi 
  #Check if the script contains uncommited changes 
  git diff --exit-code ../scripts/${file}  >/dev/null 2>&1|| modified=TRUE && modified=FALSE
  if [ "${modified}" == "TRUE" ] 
  then 
    echo "Warning: File ${file} contains uncommitted changes!"
    continue 
  fi 
  #Check if the documentation is tracked by git
  git ls-files --error-unmatch ${man_file} > /dev/null 2>&1 || tracked=FALSE && tracked=TRUE 
  if [ "${tracked}" == "FALSE" ] 
  then 
    echo "ERROR: Documentation for file ${file} isn't tracked by git!"
    exit 1 
  fi 
  #Check if the script contains uncommited changes 
  git diff --exit-code ${man_file} > /dev/null 2>&1 || modified=TRUE && modified=FALSE
  if [ "${modified}" == "TRUE" ] 
  then 
    echo "Warning: Documentation for file ${file} contains uncommitted changes!"
    continue 
  fi 
  echo ${file}
  #Extract the git commit history for this script 
  git log --follow -- ../scripts/${file} 2>/dev/null > ../history/${file//.sh/.txt} 
  #Extract the git commit history for the documentation for this script 
  git log --follow -- ${man_file} 2>/dev/null > ../history/${file//.sh/.man.txt} 
  #Load the documentation for this script 
  source ${man_file} 

  #Write the documentation .tex file {{{
  title=${file//.sh/}
  title=${title//_/\\_}
  echo "\\subsection{ \\texttt{${title}} }" > ../tex/${file//.sh/.tex}
  desc="`_description | sed 's/#//g' | sed 's/^ //g' | sed '/Function takes input data:/,+1d'`"
  echo "${desc//_/\\_}" >> ../tex/${file//.sh/.tex} 
  echo >> ../tex/${file//.sh/.tex}
  #}}}

  #Input data products {{{
  data=`_inp_data`
  if [ "$data" != "" ] 
  then 
    echo "\\paragraph{Required input data products}" >> ../tex/${file//.sh/.tex}
    echo Function reads data from: >> ../tex/${file//.sh/.tex} 
      #Write blocks
      echo "\\begin{itemize}" >> ../tex/${file//.sh/.tex} 
      for block in ${data} 
      do 
        if [ "`echo ${block} | grep "BV:" || echo 0`" != "0" ]
        then 
          echo "\\item ${block//_/\\_} (i.e. Name set dynamically using runtime variable value)" >> ../tex/${file//.sh/.tex}
        else 
          echo "\\item ${block//_/\\_}" >> ../tex/${file//.sh/.tex}
        fi 
      done 
      echo "\\end{itemize}" >> ../tex/${file//.sh/.tex} 
    echo >> ../tex/${file//.sh/.tex}
  else
    echo >> ../tex/${file//.sh/.tex} 
    echo "\\textbf{Function reads no input data.}" >> ../tex/${file//.sh/.tex} 
    echo >> ../tex/${file//.sh/.tex} 
  fi 
  #}}}

  #Input variables {{{
  vars=`_inp_var`
  if [ "$vars" != "" ] 
  then 
    echo "\\paragraph{Required input variables}" >> ../tex/${file//.sh/.tex}
    echo Function requires defined runtime variables: >> ../tex/${file//.sh/.tex} 
    #Write variables as list
    echo "\\begin{itemize}" >> ../tex/${file//.sh/.tex} 
    for var in `echo ${vars} | sed 's/ /\n/g' | grep "BV:" | sed 's/BV://g' ` 
    do 
      desc=`grep -B1 "^${var}=" ../config/defaults.sh | head -1 | sed 's/^#//g'`
      echo "\\item \\texttt{${var//_/\\_}}: ${desc//_/\\_}" >> ../tex/${file//.sh/.tex}
    done 
    echo "\\end{itemize}" >> ../tex/${file//.sh/.tex} 
    echo  >> ../tex/${file//.sh/.tex}
  else 
    echo >> ../tex/${file//.sh/.tex} 
    echo "\\textbf{Function requires no runtime variables.}" >> ../tex/${file//.sh/.tex} 
    echo >> ../tex/${file//.sh/.tex} 
  fi 
  #}}}

  #Output data products {{{
  outputs=`_outputs`
  if [ "$outputs" != "" ] 
  then 
    echo "\\paragraph{Output data products}" >> ../tex/${file//.sh/.tex}
    output_var=`echo ${outputs} | sed 's/ /\n/g' | grep "^BV:" | sed 's/BV://g'` 
    if [ "${output_var}" != "" ] # Output variables {{{
    then 
      echo Function writes to the following runtime variables: >> ../tex/${file//.sh/.tex} 
      #Write variables as list
      echo "\\begin{itemize}" >> ../tex/${file//.sh/.tex} 
      for var in ${output_var} 
      do 
        desc=`grep -B1 "^${var}=" ../config/defaults.sh | head -1 | sed 's/^#//g'`
        echo "\\item \\texttt{${var//_/\\_}}: ${desc//_/\\_}" >> ../tex/${file//.sh/.tex}
      done 
      echo "\\end{itemize}" >> ../tex/${file//.sh/.tex} 
    fi #}}}
    output_block=`echo ${outputs} | sed 's/ /\n/g' | grep -v "^BV:" || echo` 
    if [ "${output_block}" != "" ] # Output blocks {{{
    then 
      echo Function writes to the following datablock elements: >> ../tex/${file//.sh/.tex} 
      #Write blocks
      echo "\\begin{itemize}" >> ../tex/${file//.sh/.tex} 
      for block in ${output_block} 
      do 
        if [ "`echo ${block} | grep "BV:" || echo 0`" != "0" ]
        then 
          echo "\\item ${block//_/\\_} (i.e. Name set dynamically using runtime variable value)" >> ../tex/${file//.sh/.tex}
        else 
          echo "\\item ${block//_/\\_}" >> ../tex/${file//.sh/.tex}
        fi 
      done 
      echo "\\end{itemize}" >> ../tex/${file//.sh/.tex} 
    else 
      echo >> ../tex/${file//.sh/.tex} 
      echo "\\textbf{Function does not write to any datablock elements.}" >> ../tex/${file//.sh/.tex} 
      echo >> ../tex/${file//.sh/.tex} 
    fi #}}}
    echo  >> ../tex/${file//.sh/.tex}
  else 
    echo >> ../tex/${file//.sh/.tex} 
    echo "\\textbf{Function outputs no data products or runtime variables.}" >> ../tex/${file//.sh/.tex} 
    echo >> ../tex/${file//.sh/.tex} 
  fi 
  #}}}

  echo "\\input{${file//.sh/.tex}}" >> ../tex/sections.tex

done 

_unset_functions
trap : 0 





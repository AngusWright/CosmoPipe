#
# Script to generate an initial documentation file for an input script
#

#Input script name 
for base in "scripts"
do 
  #Do one or all scripts 
  if [ "$1" == "" ] 
  then 
    scriptlist=`ls ../${base}/`
  else 
    scriptlist="$1"
  fi 

	for script in $scriptlist 
	do 
	
		scriptfull=../${base}/${script}
		#Script extension
		ext=${script##*.}
		#Documentation name 
		docu=${script//.${ext}/.man.sh}
	
    if [ "${ext}" == "R" ] || [ "${ext}" == "py" ]
    then 
	    echo "skipping ${scriptfull}; it's an R/py file"
	    continue
	  elif [ ! -f ../man/${docu} ]
	  then 
	    echo "skipping ${scriptfull}; no file ../man/${docu}"
	    continue
	  else 
	    echo "Running ${scriptfull}"
	    cp ../man/${docu} ${docu}
	  fi 
		
		#Construct the list of variables present in this script {{{
		#variables=`cat ${scriptfull} | grep -Ev "^[[:space:]]{0,}#" | sed 's/"//g' | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
		#  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `
		variables=$(grep -Ev '^[[:space:]]*#' "$scriptfull" \
  		| sed 's/"//g' \
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
		  #variables="${variables} `cat ${script/.${ext}/.py} | grep -Ev "^[[:space:]]{0,}#" | sed 's/"//g' | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
		  #awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
		  variables="${variables} $(grep -Ev '^[[:space:]]*#' "${script/.${ext}/.py}" \
  			| sed 's/"//g' \
  			| grep "@" \
  			| sed 's/\(@.*@\)/\n\1\n/g' \
  			| grep "@" \
  			| awk -F@ '{s=""; for (i=2;i<=NF;i+=2) {s=s ? s "\n" $i : $i} print s }' \
  			| grep -v "^$" \
  			| sort -u \
  			| grep -v "DB:" \
  			| xargs echo)"
		fi 
		#If there is a cosmosis .ini file, add the variables from that too 
		inifile=${script/.${ext}/.ini}
		inifile=../config/${inifile}
		#echo ${inifile}
		if [ -f ${inifile} ]
		then 
		  #variables="${variables} `cat ${inifile} | grep -Ev "^[[:space:]]{0,}#" | sed 's/"//g' | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
		  #awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
		  variables="${variables} $(grep -Ev '^[[:space:]]*#' "${inifile}" \
  			| sed 's/"//g' \
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
		  #variables="${variables} `cat ${script/.${ext}/.R} | grep -Ev "^[[:space:]]{0,}#" | sed 's/"//g' | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
		  #awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
		  variables="${variables} $(grep -Ev '^[[:space:]]*#' "${script/.${ext}/.R}" \
			| sed 's/"//g' \
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
		
	  #Update the variables entry {{{
	  grep -B 10000 "function _inp_var" ${docu} | head -n -1 > tmp.man.sh
		cat >> tmp.man.sh <<- EOF 
		function _inp_var { 
		  #Variable inputs (leave blank if none)
		  echo $variables
		} 
		EOF
	  grep -A 10000 "function _inp_var" ${docu} | tail -n +5 >> tmp.man.sh
	  mv tmp.man.sh ${docu}
	  #}}}
		
		#Construct the list of DB variables present in this script {{{
		#variables=`cat ${scriptfull} | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
		#  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep "DB:" | sed 's/DB://g' | xargs echo `
		variables=$(grep "@" "${scriptfull}" \
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
		
	  #Update the variables entry {{{
	  grep -B 10000 "function _inp_data" ${docu} | head -n -1 > tmp.man.sh
		cat >> tmp.man.sh <<- EOF 
		function _inp_data { 
		  #Data inputs (leave blank if none)
		  echo $variables
		} 
		EOF
	  grep -A 10000 "function _inp_data" ${docu} | tail -n +5 >> tmp.man.sh
	  mv tmp.man.sh ${docu}
	  #}}}

    ndiff=`diff ../man/${docu} ${docu} | wc -l`
    if [ ${ndiff} -gt 0 ] 
    then 
      diff ../man/${docu} ${docu} 
    else 
      echo "No changes to file ${docu}"
      rm ${docu}
      continue
    fi 
	
    read -p "Are you happy with the changes? [Y/n] " status 
    if [ "$status" == "" ] 
    then 
      status='Y'
    fi 
    if [ ${status} == "Y" ] 
    then 
	    echo "moving $docu ../man/"
	    mv $docu ../man/
    else 
	    echo "not moving $docu"
    fi 

	done
done 



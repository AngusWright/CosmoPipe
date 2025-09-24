#
# Shell script for installation of the KiDS COSMOLOGY pipeline
# Written by A.H.Wright (2023-03-10)
#

#Source the Script Documentation Functions {{{
source man/CosmoPipe.man.sh
source man/${0//.sh/.man.sh} 
#}}}

#Full List of available options {{{ 
OPTLIST=`_get_optlist scripts/variables_raw.sh`
#Add INSTALL-only variables 
OPTLIST=`echo $OPTLIST NOCONFIG NOCONDA`
#}}}

#Generate the list of possible command-line arguments {{{
COMMOPTS=`echo ${OPTLIST} | awk '{print "--" tolower($1)}'`
#remove hyphens and make lowercase
COMMOPTS=${OPTLIST//-/}
COMMOPTS=${COMMOPTS,,}
#}}}

#Set the default variables to determine the installation paths  {{{
#Do we want to run the configure file? (1=NO, else YES)
NOCONFIG=1
NOCONDA=1
NOINSTALL=1
#Source the main variables 
source scripts/variables_raw.sh 
#}}}

#Read any command line options  {{{
while [ $# -gt 0 ]
do 
  #Get the option name: remove hyphens and make uppercase
  name=${1//-/}
  name=${name^^}
  if [ $name == 'NOCONDA' ] 
  then 
    NOCONDA=0
    shift 
  elif [ $name == 'NOINSTALL' ] 
  then 
    NOINSTALL=0
    shift 
  elif [ $name == 'NOCONFIG' ]
  then 
    NOCONFIG=0
    shift 
  else 
    #Get the option value 
    value=$2
    #Check for OPTLIST matches: return 0 if not found, but do not trap-exit  
    match=`echo $OPTLIST | grep -c $name || echo `
    if [ "$match" == "0" ]
    then 
      echo "ERROR - unknown option $1! Does not match any known variable!"
      exit 1
    fi 
    #Assign the variable 
    declare $name="$value"
    #shift to the next option 
    shift; shift; 
  fi 
done
#}}}

#Check for calling syntax {{{
if [ ${RUNROOT} == "@RUNROOT@" ] || [ ${RUNROOT} == "" ]
then 
  _runroot_error 
fi 
#}}}

#Check for calling syntax {{{
if [ ${PACKROOT} == "@PACKROOT@" ] || [ ${PACKROOT} == "" ]
then 
  PACKROOT=`pwd`
fi 
#}}}

#Prompt {{{
_prompt ${VERBOSE}
#}}}

#Variable Check {{{
_varcheck $0
#}}}

if [ "$NOINSTALL" == "1" ] 
then 

  #Move into the install directory {{{
  if [ -d ${RUNROOT}/INSTALL ] && [ "$NOCONDA" == "1" ] 
  then 
    _existing_install_error
  fi 
  _message "   >${RED} Creating Initial Directory structure ${DEF}"
  mkdir -p ${RUNROOT}/INSTALL 
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  cd ${RUNROOT}/INSTALL
  
  #Run Conda installation {{{
  if [ "$NOCONDA" == "1" ] 
  then 
    _message "   >${RED} Installing Conda tools ${DEF}"
    #If there is no conda installation, exit {{{
    if [ "`which conda`" == "" ] 
    then 
      _message " - ${RED} ERROR!\n\n"
      _message "There is no conda installation in the PATH. Install conda using the below commands:${DEF}\n"
      if [ "`uname`" == "Darwin" ]
      then 
        _message "wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-MacOSX-x86_64.sh\n"
        _message "bash Miniconda3-py38_4.10.3-MacOSX-x86_64.sh\n" 
        _message "${RED}and then activate the installation with by sourcing your .bashrc:${DEF}\nsource ~/.bashrc\n" 
      else 
        _message "wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-Linux-x86_64.sh\n"
        _message "bash Miniconda3-py38_4.10.3-Linux-x86_64.sh\n"
        _message "${RED}and then activate the installation with by sourcing your .bashrc:${DEF}\nsource ~/.bashrc\n" 
      fi 
      exit 1 
    else 
        _message "using conda binary ${RED}`which conda`${DEF}\n" 
    fi 
    #}}}
    
    #Copy the environment & requirements files to the INSTALL directory
    #cp ${PACKROOT}/environment.yml ${PACKROOT}/requirements.txt .
    cp ${PACKROOT}/environment*.yml .
    #Install Conda
    nenv=`conda info --envs | grep "^${CONDAPIPENAME} " | wc -l`
    if [ ${nenv} -ne 0 ] 
    then 
      _message " - ${RED} ERROR!\n\n"
      _message "There is an existing conda environment that is called 'cosmopipe'!\n"
      _message "You need to remove it first by running: ${DEF}\n"
      _message "conda remove -n cosmopipe --all \n"
      exit 1
    fi 
    if [ "`uname`" == "Darwin" ]
    then 
      conda env create --file environment_darwin.yml > conda_install_output.log 2>&1
    else 
      conda env create --file environment.yml > conda_install_output.log 2>&1
    fi 
    _message "${BLU} - Done! ${DEF}\n"
  fi 
  #}}}
  
  #Install cosmosis-standard-library {{{
  python_vers=`conda run -n ${CONDAPIPENAME} python --version | head -1 | awk '{print $2}' | awk -F. '{print "python"$1"."$2 }'`
  cosmosis_src=`conda run -n ${CONDAPIPENAME} which cosmosis | sed "s@/bin/cosmosis@/lib/${python_vers}/site-packages/cosmosis/@"`
  #Clone the cosmosis-standard-library repository {{{
  _message "   >${RED} Cloning the cosmosis-standard-library Git repository${DEF}"
  #Clone the repository
  if [ -d ${RUNROOT}/INSTALL/cosmosis-standard-library ] 
  then 
    rm -fr cosmosis-standard-library
  fi
  git clone --single-branch -b two-point-one-point https://github.com/andrejdvornik/cosmosis-standard-library.git >> gitclone_output.log 2>&1
  # The two-point-one-point branch has one-point function enabled and some further non-PR fixes to CAMB
  # We will try to merge that with the oficial CSL, until then the rest of CSL is in sync!
  #git clone https://github.com/joezuntz/cosmosis-standard-library.git >> gitclone_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  _message "   >${RED} Installing cosmosis-standard-library ${DEF}"
  #Replace the cpdef instances with cdef in classy.pyx
  if [ -f cosmosis-standard-library/boltzmann/class/class_v3.2.0/python/classy.pyx ]
  then 
    ${P_SED_INPLACE} "s# cpdef # cdef #" cosmosis-standard-library/boltzmann/class/class_v3.2.0/python/classy.pyx 
  fi 
  #}}}
  cat > csl_make.sh <<-EOF
source cosmosis-configure
cd cosmosis-standard-library
make
cd ..
EOF
  conda run -n ${CONDAPIPENAME} bash csl_make.sh > CSL_install_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Install requisite R Packages {{{
  _message "   >${RED} Installing R Packages ${DEF}"
  conda run -n ${CONDAPIPENAME} ${P_RSCRIPT} ${PACKROOT}/INSTALL_Rpack.R > R_install_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Clone the SOM_DIR repository {{{
  _message "   >${RED} Cloning SOM_DIR Git repository${DEF}"
  #Clone the repository
  if [ -d ${RUNROOT}/INSTALL/SOM_DIR ] 
  then 
    rm -fr SOM_DIR
  fi
  git clone https://github.com/AngusWright/SOM_DIR.git >> gitclone_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Clone the CosmoPowerCosmosis repository {{{
  _message "   >${RED} Cloning CosmoPowerCosmosis Git repository${DEF}"
  #Clone the repository
  if [ -d ${RUNROOT}/INSTALL/CosmoPowerCosmosis ] 
  then 
    rm -fr CosmoPowerCosmosis
  fi
  git clone https://github.com/KiDS-WL/CosmoPowerCosmosis.git >> gitclone_output.log 2>&1
  #git clone git@github.com:KiDS-WL/CosmoPowerCosmosis.git >> gitclone_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Clone the One Covariance repository {{{
  _message "   >${RED} Cloning the One Covariance Git repository${DEF}"
  #Clone the repository
  if [ -d ${RUNROOT}/INSTALL/OneCovariance ] 
  then 
    rm -fr OneCovariance
  fi
  git clone https://github.com/rreischke/OneCovariance.git >> gitclone_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Clone the 2ptstats repository {{{
  _message "   >${RED} Cloning the 2ptStats Git repository${DEF}"
  #Clone the repository
  if [ -d ${RUNROOT}/INSTALL/2pt_stats ] 
  then 
    rm -fr 2pt_stats
  fi
  git clone https://github.com/maricool/2pt_stats.git >> gitclone_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  #}}}

  #Clone the Datavec Blinding repository {{{
  _message "   >${RED} Cloning the Datavector Blinding Git repository${DEF}"
  #Clone the repository
  if [ -d ${RUNROOT}/INSTALL/legacy_blinding ]
  then
    rm -fr legacy_blinding
  fi
  git clone --single-branch -b kids https://github.com/andrejdvornik/legacy_blinding.git >> gitclone_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  cat > blinding_make.sh <<-EOF
cd legacy_blinding
python -m pip install -e .
cd ..
EOF
  conda run -n ${CONDAPIPENAME} bash blinding_make.sh > blinding_install_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Clone the galselect repository {{{
  _message "   >${RED} Cloning the galselect Git repository${DEF}"
  #Clone the repository
  if [ -d ${RUNROOT}/INSTALL/galselect ] 
  then 
    rm -fr galselect
  fi
  git clone https://github.com/jlvdb/galselect.git >> gitclone_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Install THELI LDAC tools {{{
  _message "   >${RED} Installing THELI LDAC tools${DEF}"
  if [ -f ${RUNROOT}/../theli-1.6.1.tgz ]
  then 
    ln -s ${RUNROOT}/../theli-1.6.1.tgz .
  else 
    wget https://marvinweb.astro.uni-bonn.de/data_products/theli/theli-1.6.1.tgz > THELI_wget.log 2>&1
  fi 
  cd ${RUNROOT}/INSTALL
  tar -xf theli-1.6.1.tgz >> THELI_install.log 2>&1
  rm -f theli-1.6.1.tgz  >> THELI_install.log 2>&1
  cd theli-1.6.1/pipesetup
  #Test if there is an existing pipe_env file, from a previous installation
  if [ -f pipe_env.bash.${MACHINE} ] 
  then 
    rm -f pipe_env.bash.${MACHINE}
  fi 
  #conda run -n ${CONDAPIPENAME} bash install.sh -m ALL >> THELI_install.log 2>&1
  warn=FALSE
  echo "set -e" > THELI_install.sh
  echo "bash install.sh -m ALL || echo " >> THELI_install.sh
  echo ". pipe_env.bash.${MACHINE}" >> THELI_install.sh
  echo "make ldactools.make" >> THELI_install.sh
  conda run -n ${CONDAPIPENAME} bash THELI_install.sh >> THELI_install.log 2>&1 || warn=TRUE 
  if [ "${warn}" == "TRUE" ] 
  then 
    _message "${BLU} - ${RED}WARNING!${BLU} Check if ldac tools installed correctly... ${DEF}\n"
  else 
    _message "${BLU} - Done! ${DEF}\n"
  fi 
  cd ${RUNROOT}/INSTALL
  #}}}

  #Copy IA model to the INSTALL directory {{{
  _message "   >${RED} Copying IA models${DEF}"
  rsync -autv ${PACKROOT}/ia_models ${RUNROOT}/INSTALL/ > ${RUNROOT}/INSTALL/ia_models_rsync.log 2>&1
  #}}}
  
  #Install cosebis functions {{{
  _message "   >${RED} Installing COSEBIs tools${DEF}"
  rsync -autv ${PACKROOT}/kcap ${RUNROOT}/INSTALL/ > ${RUNROOT}/INSTALL/COSEBIs_rsync.log 2>&1
  #cd ${RUNROOT}/INSTALL/kcap/cosebis/
  cd ${RUNROOT}/INSTALL/2pt_stats/
  python_vers=`conda run -n ${CONDAPIPENAME} python --version | head -1 | awk '{print $2}' | awk -F. '{print "python"$1"."$2 }'`
  cosmosis_src=`conda run -n ${CONDAPIPENAME} which cosmosis | sed "s@/bin/cosmosis@/lib/${python_vers}/site-packages/cosmosis/@"`
  cat > cosebis_make.sh <<-EOF
source cosmosis-configure
COSMOSIS_SRC_DIR=${cosmosis_src} make clean
COSMOSIS_SRC_DIR=${cosmosis_src} make
EOF
  conda run -n ${CONDAPIPENAME} bash cosebis_make.sh > ${RUNROOT}/INSTALL/COSEBIs_install.log 2>&1
  cd ${RUNROOT}/INSTALL/
  _message "${BLU} - Done! ${DEF}\n"
  #}}}

fi 
  
  #Install OneCovariance {{{
  _message "   >${RED} Installing OneCovariance ${DEF}"
  cd ${RUNROOT}/INSTALL/OneCovariance/
  cat > OneCovariance_make.sh <<-EOF
pip install .
EOF
  conda run -n ${CONDAPIPENAME} bash OneCovariance_make.sh > ${RUNROOT}/INSTALL/OneCovariance_install.log 2>&1
  cd ${RUNROOT}/INSTALL/
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Install galselect {{{
  _message "   >${RED} Installing galselect ${DEF}"
  cd ${RUNROOT}/INSTALL/galselect/
  cat > galselect_make.sh <<-EOF
pip install .
EOF
  conda run -n ${CONDAPIPENAME} bash galselect_make.sh > ${RUNROOT}/INSTALL/galselect_install.log 2>&1
  cd ${RUNROOT}/INSTALL/
  _message "${BLU} - Done! ${DEF}\n"
  #}}}

cd ${RUNROOT}

#Update the Configure script for this run {{{
_message "   >${RED} Update the configure script ${DEF}"
MACHINE=`uname`
THELIPATH=`echo ${RUNROOT}/INSTALL/theli-1.6.1/bin/${MACHINE}*`
if [ "${PACKROOT%/}" != "${RUNROOT%/}" ]
then 
  cp -f ${PACKROOT}/update_configure.sh ${RUNROOT}/
fi 
cp ${PACKROOT}/scripts/configure_raw.sh ${RUNROOT}/configure.sh 
cp ${PACKROOT}/scripts/variables_raw.sh ${RUNROOT}/variables.sh 
cp ${PACKROOT}/config/defaults.sh ${RUNROOT}/defaults.sh 
cp ${PACKROOT}/config/pipeline.ini ${RUNROOT}/pipeline.ini 
cp ${PACKROOT}/config/subroutines.ini ${RUNROOT}/subroutines.ini 
for OPT in $OPTLIST
do 
  ${P_SED_INPLACE} "s#\\@${OPT}\\@#${!OPT}#g" ${RUNROOT}/configure.sh ${RUNROOT}/variables.sh
done 
_message "${BLU} - Done! ${DEF}\n"
#}}}

#Run the configuration script {{{
if [ "${NOCONFIG}" != "1" ]
then 
  _message "   >${RED} Running the configure script { ${DEF}\n"
  conda run -n ${CONDAPIPENAME} bash ./configure.sh 
  _message "${BLU} } - Done! ${DEF}\n"
fi 
#}}}

#Closing Prompt {{{
_message "${BLU}=======================================${DEF}\n"
#Finished! 
trap : 0
_message "${BLU}=======================================${DEF}\n"
_message "${BLU}==${RED}  Pipeline Installation Complete!  ${BLU}==${DEF}\n"
_message "${BLU}=======================================${DEF}\n"
_message "${BLU}CosmoPipe has been installed at the below path:${DEF}\n"
_message "${DEF}${RUNROOT}${DEF}\n"
_message "${BLU}In that directory, you will find: ${DEF}\n"
_message "  - ${BLU}configure.sh (The pipeline configuration script)${DEF}\n"
_message "  - ${BLU}variables.sh (The file contains compile-time variables)${DEF}\n"
_message "    -> ${BLU}These variables cannot be edited after compilation.${DEF}\n"
_message "  - ${BLU}defaults.sh (The file contains run-time variables)${DEF}\n"
_message "    -> ${BLU}These variables can be assigned/modified as the pipeline runs, and so this file just${DEF}\n"
_message "       ${BLU}contains the global default values that they are assigned during compilation. ${DEF}\n"
_message "    -> ${BLU}Only run-time variables needed by your pipeline are important, and so the compilation${DEF}\n"
_message "       ${BLU}will select the needed run-time variables and put them into a different bespoke file.${DEF}\n"
_message "       ${BLU}So you can probably ignore this file for now.${DEF}\n"
_message "  - ${BLU}pipeline.ini (The pipeline definition script)${DEF}\n\n"
_message "${RED}To use CosmoPipe: ${DEF}\n"
_message "  1) ${BLU}Go to the directory containing CosmoPipe (listed above)${DEF}\n"
_message "  2) ${BLU}Check the ${DEF}variables.sh${BLU} file has all the variables correctly defined${DEF}\n"
_message "    -> ${BLU}Of particular importance is the ${DEF}PIPELINE${BLU} variable, which tells${DEF}\n"
_message "       ${BLU}CosmoPipe which pipeline in ${DEF}pipeline.ini${BLU} to construct!${DEF}\n"
_message "  3) ${BLU}Check the ${DEF}pipeline.ini${BLU} file has your desired pipeline, and that the pipeline is correct${DEF}\n"
_message "  4) ${BLU}Run the configuration: ${DEF}conda run -n ${CONDAPIPENAME} bash configure.sh ${DEF}\n"
_message "  5) ${BLU}Follow the configuration instructions! ${DEF}\n"
#}}}


#!/usr/bin/env bash
set -eo pipefail
#
# Shell script for installation of the KiDS COSMOLOGY pipeline
# Written by A.H.Wright (2023-03-10)
#

#Source the Script Documentation Functions {{{
INSTALLER_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${INSTALLER_ROOT}/man/CosmoPipe.man.sh"
source "${INSTALLER_ROOT}/man/COSMOPIPE_MASTER_INSTALL.man.sh"
#}}}

#Full List of available options {{{ 
OPTLIST=`_get_optlist "${INSTALLER_ROOT}/scripts/variables_raw.sh"`
#Add INSTALL-only variables 
OPTLIST=`echo $OPTLIST NOCONFIG NOCONDA NOINSTALL VERBOSE`
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
source "${INSTALLER_ROOT}/scripts/variables_raw.sh"
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
    if [ $# -lt 2 ] || [[ "$2" == --* ]]
    then
      echo "ERROR - option $1 requires a value!" >&2
      exit 1
    fi
    value=$2
    #Check for OPTLIST matches: return 0 if not found, but do not trap-exit  
    if [[ " $OPTLIST " != *" $name "* ]]
    then 
      echo "ERROR - unknown option $1! Does not match any known variable!"
      exit 1
    fi 
    #Assign the variable 
    declare "$name=$value"
    #shift to the next option 
    shift; shift; 
  fi 
done
#}}}

#Check for calling syntax {{{
if [ "${RUNROOT}" == "@RUNROOT@" ] || [ "${RUNROOT}" == "" ]
then 
  _runroot_error 
fi 
#}}}

#Check for calling syntax {{{
if [ "${PACKROOT}" == "@PACKROOT@" ] || [ "${PACKROOT}" == "" ]
then 
  PACKROOT="${INSTALLER_ROOT}"
fi 
PACKROOT="$(cd -- "${PACKROOT}" && pwd)"
mkdir -p "${RUNROOT}"
RUNROOT="$(cd -- "${RUNROOT}" && pwd)"
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
  cp "${PACKROOT}/environment.yml" .
  
  #Run Conda installation {{{
  if [ "$NOCONDA" == "1" ] 
  then 
    _message "   >${RED} Installing Conda tools ${DEF}"
    #If there is no conda installation, exit {{{
    if ! command -v conda >/dev/null 2>&1
    then 
      _message " - ${RED} ERROR!\n\n"
      _message "There is no conda installation in the PATH. Install conda using the below commands:${DEF}\n"
      if [ "`uname`" == "Darwin" ]
      then 
        _message "Install Miniforge for your macOS architecture: https://conda-forge.org/download/\n"
        _message "${RED}and then activate the installation with by sourcing your .bashrc:${DEF}\nsource ~/.bashrc\n" 
      else 
        _message "Install Miniforge for your Linux architecture: https://conda-forge.org/download/\n"
        _message "${RED}and then activate the installation with by sourcing your .bashrc:${DEF}\nsource ~/.bashrc\n" 
      fi 
      exit 1 
    else 
        _message "using conda binary ${RED}`which conda`${DEF}\n" 
    fi 
    #}}}
    
    #Install Conda
    nenv=$(conda info --envs | awk -v name="${CONDAPIPENAME}" '$1 == name {n++} END {print n+0}')
    if [ ${nenv} -ne 0 ] 
    then 
      _message " - ${RED} ERROR!\n\n"
      _message "There is an existing conda environment called '${CONDAPIPENAME}'!\n"
      _message "You need to remove it first by running: ${DEF}\n"
      _message "conda remove -n ${CONDAPIPENAME} --all \n"
      exit 1
    fi 
    conda env create --name "${CONDAPIPENAME}" --file environment.yml > conda_install_output.log 2>&1
    _message "${BLU} - Done! ${DEF}\n"
  fi 
  #}}}
  
  # Keep ChainConsumer's Pydantic dependencies separate from TensorFlow 2.13.
  cp "${PACKROOT}/environment-plotting.yml" .
  if [ ! -d "${RUNROOT}/INSTALL/plotting-env/conda-meta" ]
  then
    _message "   >${RED} Installing plotting environment ${DEF}"
    conda env create --prefix "${RUNROOT}/INSTALL/plotting-env" \
      --file environment-plotting.yml > plotting_install_output.log 2>&1
    _message "${BLU} - Done! ${DEF}\n"
  fi

  #Install cosmosis-standard-library {{{
  cosmosis_src=$(conda run -n "${CONDAPIPENAME}" python -c 'import pathlib, cosmosis; print(pathlib.Path(cosmosis.__file__).parent)')
  #Clone the cosmosis-standard-library repository {{{
  _message "   >${RED} Cloning the cosmosis-standard-library Git repository${DEF}"
  #Clone the repository
  if [ -d ${RUNROOT}/INSTALL/cosmosis-standard-library ] 
  then 
    rm -fr cosmosis-standard-library
  fi
  git clone https://github.com/joezuntz/cosmosis-standard-library.git >> gitclone_output.log 2>&1
  _message "${BLU} - Done! ${DEF}\n"
  _message "   >${RED} Installing cosmosis-standard-library ${DEF}"
  #Replace the cpdef instances with cdef in classy.pyx
  if [ -f cosmosis-standard-library/boltzmann/class/class_v3.2.0/python/classy.pyx ]
  then 
    ${P_SED_INPLACE} "s# cpdef # cdef #" cosmosis-standard-library/boltzmann/class/class_v3.2.0/python/classy.pyx 
  fi 
  #}}}
  cat > csl_make.sh <<-EOF
set -eo pipefail
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
  cd ${RUNROOT}/INSTALL
  if [ -f ${PACKROOT}/theli-1.6.1.tgz ]
  then 
    ln -s ${PACKROOT}/theli-1.6.1.tgz .
  else 
    wget -t 1 --connect-timeout 60 https://marvinweb.astro.uni-bonn.de/data_products/theli/theli-1.6.1.tgz > THELI_wget.log 2>&1 || _message "FAILED"
  fi 
  if [ -f theli-1.6.1.tgz ] 
  then 
    tar -xf theli-1.6.1.tgz >> THELI_install.log 2>&1
    rm -f theli-1.6.1.tgz  >> THELI_install.log 2>&1
    cd theli-1.6.1/pipesetup
    #Test if there is an existing pipe_env file, from a previous installation
    if [ -f pipe_env.bash.${MACHINE} ] 
    then 
      rm -f pipe_env.bash.${MACHINE}
    fi 
    # THELI predates C23 and GCC's -fno-common default.
    cat > THELI_install.sh <<-EOF
set -eo pipefail
bash install.sh -m UPDATE
source pipe_env.bash.${MACHINE}
sed 's!#define __PIPEVERS__!#define __PIPEVERS__ "THELI Pipeline Version: 1.6.1"!' global_vers.h.raw > ../ldactools/library/global_vers.h
make bin_dirs ldactools.make "CC=\${CC} -std=gnu89 -fcommon"
test -x "\${PIPEBIN}/\${EXT}/ldacrenkey"
test -x "\${PIPEBIN}/\${EXT}/ldacfilter"
EOF
    conda run -n "${CONDAPIPENAME}" bash THELI_install.sh >> "${RUNROOT}/INSTALL/THELI_install.log" 2>&1
    _message "${BLU} - Done! ${DEF}\n"
    cd ${RUNROOT}/INSTALL
  else 
      _message "${BLU} - ${RED}FAILED!${BLU} The theli-1.6.1.tgz tarball was not accessible, and was not in the PACKROOT directory.\n${DEF}\n"
      _message "${BLU}   CosmoPipe requires LDAC tools to run, so you will need to rerun the installation once the tarball is placed in the PACKROOT directory:\n${DEF}${PACKROOT}\n"
      exit 1 
  fi 
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
  cat > cosebis_make.sh <<-EOF
set -eo pipefail
source cosmosis-configure
COSMOSIS_SRC_DIR=${cosmosis_src} make clean
COSMOSIS_SRC_DIR=${cosmosis_src} make
EOF
  conda run -n ${CONDAPIPENAME} bash cosebis_make.sh > ${RUNROOT}/INSTALL/COSEBIs_install.log 2>&1
  cd ${RUNROOT}/INSTALL/
  _message "${BLU} - Done! ${DEF}\n"
  #}}}

  #Install OneCovariance {{{
  _message "   >${RED} Installing OneCovariance ${DEF}"
  cd ${RUNROOT}/INSTALL/OneCovariance/
  cat > OneCovariance_make.sh <<-EOF
set -eo pipefail
python -m pip install .
EOF
  conda run -n ${CONDAPIPENAME} bash OneCovariance_make.sh > ${RUNROOT}/INSTALL/OneCovariance_install.log 2>&1
  cd ${RUNROOT}/INSTALL/
  _message "${BLU} - Done! ${DEF}\n"
  #}}}
  
  #Install galselect {{{
  _message "   >${RED} Installing galselect ${DEF}"
  cd ${RUNROOT}/INSTALL/galselect/
  cat > galselect_make.sh <<-EOF
set -eo pipefail
python -m pip install .
EOF
  conda run -n ${CONDAPIPENAME} bash galselect_make.sh > ${RUNROOT}/INSTALL/galselect_install.log 2>&1
  cd ${RUNROOT}/INSTALL/
  _message "${BLU} - Done! ${DEF}\n"
  #}}}

  conda run -n "${CONDAPIPENAME}" python -m pip check > "${RUNROOT}/INSTALL/pip_check.log" 2>&1
  conda run -n "${CONDAPIPENAME}" python "${PACKROOT}/scripts/check_installation.py" \
    --runroot "${RUNROOT}" > "${RUNROOT}/INSTALL/compatibility_check.log" 2>&1
  conda run --prefix "${RUNROOT}/INSTALL/plotting-env" python -m pip check \
    > "${RUNROOT}/INSTALL/plotting_pip_check.log" 2>&1
  conda run --prefix "${RUNROOT}/INSTALL/plotting-env" python -m unittest discover \
    -s "${PACKROOT}/tests" -p test_plot_sigma8.py \
    > "${RUNROOT}/INSTALL/plotting_check.log" 2>&1
  conda env export -n "${CONDAPIPENAME}" > "${RUNROOT}/INSTALL/environment-resolved.yml"
  conda env export --prefix "${RUNROOT}/INSTALL/plotting-env" \
    > "${RUNROOT}/INSTALL/plotting-environment-resolved.yml"
  for dependency in cosmosis-standard-library SOM_DIR CosmoPowerCosmosis OneCovariance 2pt_stats galselect
  do
    printf '%s ' "${dependency}"
    git -C "${RUNROOT}/INSTALL/${dependency}" rev-parse HEAD
  done > "${RUNROOT}/INSTALL/source-revisions.txt"
fi

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
${P_SED_INPLACE} "s#^CONDAPIPENAME=.*#CONDAPIPENAME=${CONDAPIPENAME}#" "${RUNROOT}/variables.sh"
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

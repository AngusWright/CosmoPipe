###############################################
#             CosmoPipe Pipeline              #
###############################################
#
# Written by: Angus H Wright 
#             (awright AT astro.rub.de)
# 
###############################################
#
# This pipeline file was constructed for the user
# @USER@, using the pipeline "@PIPELINE@" 
#
# This script has been configured using the
# documentation provided with each CosmoPipe
# module, has satisfied the module input/output
# checks, and has been written with bespoke paths
# constructed during configuration. The steps of
# the process are _not_ designed to be run
# independently. Doing so may lead to violation of
# the data-flow and catastrophically incorrect
# results. So:
#
#         ~~~ DO NOT EDIT THIS FILE ~~~
#

#Stop on error 
set -e 

#Source the CosmoPipe base functions 
source @RUNROOT@/@MANUALPATH@/CosmoPipe.man.sh

#Initialise the datablock 
_initialise_datablock block


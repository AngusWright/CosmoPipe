#Statistic
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ]  || [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020_NOFEEDBACK" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020_NOFEEDBACK" ]
then
  non_linear_model=mead2020
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi
#Input data vector
STATISTIC="@BV:STATISTIC@"
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  inputfile=@DB:mcmc_inp_cosebis@
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  inputfile=@DB:mcmc_inp_bandpowers@
#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then
  _message "B-modes are not defined for vanilla xipm! Use xiEB instead!\n"
#}}}
elif [ "${STATISTIC^^}" == "XIEB" ] #{{{
then 
  inputfile_E=@DB:mcmc_inp_xiE@
  inputfile=@DB:mcmc_inp_xiB@
fi
#}}}
#If needed, create the output directory {{{
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 
#}}}

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
MULT=@BV:MULT@

# Old Bmode script
#if [ -n "$MULT" ]
#then
#  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/Bmodes_pvalue.py \
#  --inputfile ${inputfile} \
#  --statistic @BV:STATISTIC@ \
#  --ntomo ${NTOMO} \
#  --thetamin @BV:THETAMINXI@ \
#  --thetamax @BV:THETAMAXXI@ \
#  --title "@SURVEY@" \
#  --suffix "@BV:CHAINSUFFIX@" \
#  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/ \
#  --mult ${MULT}
#else
#  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/Bmodes_pvalue.py \
#  --inputfile ${inputfile} \
#  --statistic @BV:STATISTIC@ \
#  --ntomo ${NTOMO} \
#  --thetamin @BV:THETAMINXI@ \
#  --thetamax @BV:THETAMAXXI@ \
#  --title "@SURVEY@" \
#  --suffix "@BV:CHAINSUFFIX@" \
#  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
#fi

if [ -n "$MULT" ] && [ "$MULT" != "1.0" ]
then
 # @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/Bmodes_pvalue_v2.py \
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/Bmodes_pvalue_v2.R \
  --inputfile ${inputfile} \
  --statistic @BV:STATISTIC@ \
  --ntomo ${NTOMO} \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/ \
  --mult ${MULT}
else
  #@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/Bmodes_pvalue_v2.py \
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/Bmodes_pvalue_v2.R \
  --inputfile ${inputfile} \
  --statistic @BV:STATISTIC@ \
  --ntomo ${NTOMO} \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi


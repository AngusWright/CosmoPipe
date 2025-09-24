
#Input data vector
STATISTIC="@BV:STATISTIC@"
MODES="@BV:MODES@"
BLIND="@BV:BLIND@"

if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  inputfile="@DB:mcmc_inp_cosebis@"
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  inputfile="@DB:mcmc_inp_bandpowers@"
#}}}
elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
then
  inputfile="@DB:mcmc_inp_2pcf@"
elif [ "${STATISTIC^^}" == "XIEB" ] #{{{
then 
  inputfile_E="@DB:mcmc_inp_xiE@"
  inputfile_B="@DB:mcmc_inp_xiB@"
fi
#If needed, create the output directory {{{
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi
#}}}

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
NLENS="@BV:NLENSBINS@"
NOBS="@BV:NSMFLENSBINS@"

if [ "${STATISTIC^^}" != "XIEB" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    ee="True"
    thetamin_xi="@BV:THETAMINXI@"
    thetamax_xi="@BV:THETAMAXXI@"
  else
    ee="False"
    thetamin_xi="0.0"
    thetamax_xi="0.0"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    ne="True"
    thetamin_gt="@BV:THETAMINGT@"
    thetamax_gt="@BV:THETAMAXGT@"
  else
    ne="False"
    thetamin_gt="0.0"
    thetamax_gt="0.0"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    nn="True"
    thetamin_wt="@BV:THETAMINWT@"
    thetamax_wt="@BV:THETAMAXWT@"
  else
    nn="False"
    thetamin_wt="0.0"
    thetamax_wt="0.0"
  fi
  if [[ .*\ $MODES\ .* =~ " OBS " ]]
  then
    obs="True"
  else
    obs="False"
  fi
  
  arr=(${inputfile})
  if [[ "${#arr[@]}" > 1 ]]
  then
    for file in ${inputfile}
    do
      if [[ "$file" =~ .*"${BLIND^^}.fits".* ]]
      then
        @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
          --inputfile ${file} \
          --statistic @BV:STATISTIC@ \
          --ntomo ${NTOMO} --nlens ${NLENS} --nobs ${NOBS} \
          --thetamin_ee ${thetamin_xi} \
          --thetamax_ee ${thetamax_xi} \
          --thetamin_ne ${thetamin_gt} \
          --thetamax_ne ${thetamax_gt} \
          --thetamin_nn ${thetamin_wt} \
          --thetamax_nn ${thetamax_wt} \
          --ee ${ee} --ne ${ne} --nn ${nn} --obs ${obs} \
          --title "@SURVEY@" \
          --suffix "@BV:CHAINSUFFIX@" \
          --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
      fi
    done
  else
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
      --inputfile ${inputfile} \
      --statistic @BV:STATISTIC@ \
      --ntomo ${NTOMO} --nlens ${NLENS} --nobs ${NOBS} \
      --thetamin_ee ${thetamin_xi} \
      --thetamax_ee ${thetamax_xi} \
      --thetamin_ne ${thetamin_gt} \
      --thetamax_ne ${thetamax_gt} \
      --thetamin_nn ${thetamin_wt} \
      --thetamax_nn ${thetamax_wt} \
      --ee ${ee} --ne ${ne} --nn ${nn} --obs ${obs} \
      --title "@SURVEY@" \
      --suffix "@BV:CHAINSUFFIX@" \
      --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
  fi
else
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
  --inputfile ${inputfile_E} \
  --statistic xiE \
  --ntomo ${NTOMO} --nlens ${NLENS} --nobs ${NOBS} \
  --thetamin_ee ${thetamin_xi} \
  --thetamax_ee ${thetamax_xi} \
  --thetamin_ne ${thetamin_gt} \
  --thetamax_ne ${thetamax_gt} \
  --thetamin_nn ${thetamin_wt} \
  --thetamax_nn ${thetamax_wt} \
  --ee True --ne False --nn False --obs False \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@E" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
  --inputfile ${inputfile_B} \
  --statistic xiB \
  --ntomo ${NTOMO} --nlens ${NLENS} --nobs ${NOBS} \
  --thetamin_ee ${thetamin_xi} \
  --thetamax_ee ${thetamax_xi} \
  --thetamin_ne ${thetamin_gt} \
  --thetamax_ne ${thetamax_gt} \
  --thetamin_nn ${thetamin_wt} \
  --thetamax_nn ${thetamax_wt} \
  --ee True --ne False --nn False --obs False \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@B" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi




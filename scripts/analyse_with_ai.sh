#=========================================
#
# File Name : analyse_with_ai.sh
# Created By : dvornik
# Creation Date : 25-03-2025
# Last Modified : Tue 25 Mar 2025 15:21:13 PM CET
#
#=========================================


data="@DB:ALLHEAD@"
api_key="@BV:GPT_API_KEY@"

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/analyse_with_ai.py --data ${data} --api_data ${api_key} 2>&1

_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"




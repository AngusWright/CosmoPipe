#Script for multiplying the nz covariance matrix by an arbitrary factor
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/multiply_nzcov.py \
  --file @DB:nzcov@ \
  --factor @BV:FACTOR@ 2>&1 

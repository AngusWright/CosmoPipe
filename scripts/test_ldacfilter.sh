@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/test_ldacfilter.py \
  --input @DB:tomography_unittest_input@ \
  --output @DB:DATAHEAD@ \
  --expected-ids "@BV:LDACFILTER_TEST_EXPECTED_IDS@"

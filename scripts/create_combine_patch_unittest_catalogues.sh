output_dir=@RUNROOT@/unit_test_fixtures/combine_patch

mkdir -p "${output_dir}"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/create_combine_patch_unittest_catalogues.py "${output_dir}"

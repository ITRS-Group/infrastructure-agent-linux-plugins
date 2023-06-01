#!/bin/bash
script_path=$(realpath $0)
script_path=$(dirname $script_path)
source $script_path/utils.sh

test_id=0
failures=0

err="METRIC UNKNOWN: Integration impacted: could not retrieve physical server hardware vendor"


start_test "basic plugin usage" # --------------------------------------------------------------------------------------

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_vendor)
ret=$?

check_ok $ret


start_test "no vendor" # -----------------------------------------------------------------------------------------------

# override the `[` command so plugin thinks files don't exist
[() { return 1; }

export -f [

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_vendor)
ret=$?

unset -f [

check_output 3 "$err" $ret "$out"


start_test "empty vendor" # --------------------------------------------------------------------------------------------

# fake file contents
cat() { echo ''; }

export -f cat

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_vendor)
ret=$?

unset -f cat

check_output 3 "$err" $ret "$out"


start_test "vendor whitespace" # ---------------------------------------------------------------------------------------

cat() { echo '    foo  '; }

export -f cat

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_vendor)
ret=$?

unset -f cat

check_output 0 "METRIC OK: foo" $ret "$out"


# ----------------------------------------------------------------------------------------------------------------------

finish_tests

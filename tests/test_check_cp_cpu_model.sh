#!/bin/bash
script_path=$(realpath $0)
script_path=$(dirname $script_path)
source $script_path/utils.sh

test_id=0
failures=0

err="METRIC UNKNOWN: Integration impacted: could not retrieve physical server cpu model"


start_test "basic plugin usage" # --------------------------------------------------------------------------------------

out=$($script_path/../vendor/custom-plugins/check_cp_cpu_model)
ret=$?

check_ok $ret


start_test "commands not in PATH" # ------------------------------------------------------------------------------------

out=$(PATH='' $script_path/../vendor/custom-plugins/check_cp_cpu_model)
ret=$?

check_output 3 "$err" $ret "$out"


start_test "lscpu model name missing" # --------------------------------------------------------------------------------

# override the lscpu command temporarily
lscpu() { echo 'foo'; }

export -f lscpu

out=$($script_path/../vendor/custom-plugins/check_cp_cpu_model)
ret=$?

unset -f lscpu

check_output 3 "$err" $ret "$out"


start_test "lscpu model name empty" # ----------------------------------------------------------------------------------

lscpu() { echo 'Model name: '; }

export -f lscpu

out=$($script_path/../vendor/custom-plugins/check_cp_cpu_model)
ret=$?

unset -f lscpu

check_output 3 "$err" $ret "$out"


start_test "lscpu model name whitespace" # -----------------------------------------------------------------------------

lscpu() { echo 'Model name:   foo   '; }

export -f lscpu

out=$($script_path/../vendor/custom-plugins/check_cp_cpu_model)
ret=$?

unset -f lscpu

check_output 0 "METRIC OK: foo" $ret "$out"


# ----------------------------------------------------------------------------------------------------------------------

finish_tests

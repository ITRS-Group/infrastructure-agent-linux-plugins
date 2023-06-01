#!/bin/bash
script_path=$(realpath $0)
script_path=$(dirname $script_path)
source $script_path/utils.sh

test_id=0
failures=0

err="METRIC UNKNOWN: Integration broken: could not retrieve physical server utilization"


start_test "basic plugin usage" # --------------------------------------------------------------------------------------

out=$($script_path/../vendor/custom-plugins/check_cp_server_utilization)
ret=$?

# Expected regex output
# STDOUT:
# CPU Utilization: 1-3 digits followed by optional decimal and 0 or more digits, followed by %
# Memory Utilization: 1-3 digits followed by optional decimal and 0 or more digits, followed by %
#
# PERFDATA:
# CPU Utilization: 1-3 digits followed by optional decimal and 0 or more digits, followed by %
# Memory Utilization: 1-3 digits followed by optional decimal and 0 or more digits, followed by %
regex="^METRIC OK: CPU Utilization is [0-9]{1,3}.?[0-9]{0,}%, Memory Utilization is [0-9]*\.?[0-9]{0,}% \| 'CPU Utilization'=[0-9]{1,3}\.?[0-9]{0,}% 'Memory Utilization'=[0-9]{1,3}\.?[0-9]{0,}%$"

check_output_regex 0 "$regex" $ret "$out"


start_test "commands not in PATH" # ------------------------------------------------------------------------------------

out=$(PATH='' $script_path/../vendor/custom-plugins/check_cp_server_utilization)
ret=$?

check_output 3 "$err" $ret "$out"


start_test "top no matching lines" # -----------------------------------------------------------------------------------

# override the top command temporarily
top() { echo 'foo'; }

export -f top

out=$($script_path/../vendor/custom-plugins/check_cp_server_utilization)
ret=$?

unset -f top

check_output 3 "$err" $ret "$out"


start_test "free does not match" # -------------------------------------------------------------------------------------

# override the free command temporarily
free() { echo 'foo'; }

export -f free

out=$($script_path/../vendor/custom-plugins/check_cp_server_utilization)
ret=$?

unset -f free

check_output 3 "$err" $ret "$out"

# ----------------------------------------------------------------------------------------------------------------------

finish_tests

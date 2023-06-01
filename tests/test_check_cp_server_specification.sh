#!/bin/bash
script_path=$(realpath $0)
script_path=$(dirname $script_path)
source $script_path/utils.sh

test_id=0
failures=0

err="METRIC UNKNOWN: Integration broken: could not retrieve physical server specification"


start_test "basic plugin usage" # --------------------------------------------------------------------------------------

out=$($script_path/../vendor/custom-plugins/check_cp_server_specification)
ret=$?

# Expected regex output
# STDOUT:
# Physical/Physical cores: any number (we allow even 1000 in this test although that is unlikely)
# CPU Speed: any number following by "MHz"
# Memory Capacity: any number, optically a comma and 0 or more digits, following one or two chars. We rely on free -h to give the the unit
#
# PERFDATA:
# Physical/Physical cores: any number (we allow even 1000 in this test although that is unlikely)
# CPU Speed: any nuymber following by "MHz"
# Memory Capacity: any number followed by B. We call `free -b` for perfdata part.
regex="^METRIC OK: Physical Cores is [0-9], Logical Cores is [0-9]*, Memory Capacity is [0-9]*\.?[0-9]{0,}[a-zA-Z][a-zA-Z]?, CPU Clock Speed is [0-9]*MHz | 'Physical Cores'=[0-9]* 'Logical Cores'=[0-9]* 'Memory Capacity'=[0-9]*B 'CPU Clock Speed'=[0-9]*MHz"

check_output_regex 0 "$regex" $ret "$out"


start_test "commands not in PATH" # ------------------------------------------------------------------------------------

out=$(PATH='' $script_path/../vendor/custom-plugins/check_cp_server_specification)
ret=$?

check_output 3 "$err" $ret "$out"


start_test "lscpu no matching lines" # ---------------------------------------------------------------------------------

# override the lscpu command temporarily
lscpu() { echo '# foo'; }

export -f lscpu

out=$($script_path/../vendor/custom-plugins/check_cp_server_specification)
ret=$?

unset -f lscpu

check_output 3 "$err" $ret "$out"


start_test "no cpuinfo" # ----------------------------------------------------------------------------------------------

# override the `[` command so plugin thinks files don't exist
[() { return 1; }

export -f [

out=$($script_path/../vendor/custom-plugins/check_cp_server_specification)
ret=$?

unset -f [

check_output 3 "$err" $ret "$out"


start_test "cpuinfo does not match" # ----------------------------------------------------------------------------------

# fake file contents
cat() { echo 'foo'; }

export -f cat

out=$($script_path/../vendor/custom-plugins/check_cp_server_specification)
ret=$?

unset -f cat

check_output 3 "$err" $ret "$out"


start_test "free does not match" # -------------------------------------------------------------------------------

# override the free command temporarily
free() { echo 'foo'; }

export -f free

out=$($script_path/../vendor/custom-plugins/check_cp_server_specification)
ret=$?

unset -f free

check_output 3 "$err" $ret "$out"

# ----------------------------------------------------------------------------------------------------------------------

finish_tests

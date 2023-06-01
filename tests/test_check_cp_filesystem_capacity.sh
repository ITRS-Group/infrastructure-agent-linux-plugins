#!/bin/bash
script_path=$(realpath $0)
script_path=$(dirname $script_path)
source $script_path/utils.sh

test_id=0
failures=0

err="METRIC UNKNOWN: Integration broken: could not retrieve physical server filesystem capacity"


start_test "basic plugin usage" # --------------------------------------------------------------------------------------

out=$($script_path/../vendor/custom-plugins/check_cp_filesystem_capacity)
ret=$?

# Plugin text
# In this regex we check for i.e 'is 200G |`. That is
# we look to ensure there is at least one filesystem.
regex="is [0-9]*[a-zA-Z] \|"

check_output_regex 0 "$regex" $ret "$out"

# Perfdata. Check that the last part in the string is a number followed by B
regex="\=[0-9]*B$"

check_output_regex 0 "$regex" $ret "$out"


start_test "no filesystem utils" # -------------------------------------------------------------------------------------

# fake source of filesystem utils failing
source() { return 1; }

export -f source

out=$($script_path/../vendor/custom-plugins/check_cp_filesystem_capacity)
ret=$?

unset -f source

check_output 3 "$err" $ret "$out"


start_test "commands not in PATH" # ------------------------------------------------------------------------------------

out=$(PATH='' $script_path/../vendor/custom-plugins/check_cp_filesystem_capacity)
ret=$?

check_output 3 "$err" $ret "$out"


# ----------------------------------------------------------------------------------------------------------------------

finish_tests

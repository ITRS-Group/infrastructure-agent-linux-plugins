#!/bin/bash
script_path=$(realpath $0)
script_path=$(dirname $script_path)
source $script_path/utils.sh

test_id=0
failures=0

err="METRIC UNKNOWN: Integration impacted: could not retrieve physical server operating system"


start_test "basic plugin usage" # --------------------------------------------------------------------------------------

out=$($script_path/../vendor/custom-plugins/check_cp_os)
ret=$?

check_ok $ret


start_test "no release file" # -----------------------------------------------------------------------------------------

# override the `[` command so plugin thinks files don't exist
[() { return 1; }

export -f [

out=$($script_path/../vendor/custom-plugins/check_cp_os)
ret=$?

unset -f [

check_output 3 "$err" $ret "$out"


start_test "release file not matching" # -------------------------------------------------------------------------------

# fake file contents
source() { export FOO="bar"; }

export -f source

out=$($script_path/../vendor/custom-plugins/check_cp_os)
ret=$?

unset -f source

check_output 3 "$err" $ret "$out"


start_test "os name empty" # -------------------------------------------------------------------------------------------

source() { export NAME=""; export VERSION=""; }

export -f source

out=$($script_path/../vendor/custom-plugins/check_cp_os)
ret=$?

unset -f source

check_output 3 "$err" $ret "$out"


start_test "os name whitespace" # --------------------------------------------------------------------------------------

source() { export NAME="  foo  "; export VERSION="  bar  "; }

export -f source

out=$($script_path/../vendor/custom-plugins/check_cp_os)
ret=$?

unset -f source

check_output 0 "METRIC OK: foo     bar" $ret "$out"


# ----------------------------------------------------------------------------------------------------------------------

finish_tests

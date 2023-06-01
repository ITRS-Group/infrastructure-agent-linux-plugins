#!/bin/bash
script_path=$(realpath $0)
script_path=$(dirname $script_path)
source $script_path/utils.sh

test_id=0
failures=0

err="METRIC UNKNOWN: Integration impacted: could not retrieve physical server hardware model"


start_test "basic plugin usage" # --------------------------------------------------------------------------------------

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_model)
ret=$?

check_ok $ret


start_test "no name, no sku" # -----------------------------------------------------------------------------------------

# override the `[` command so plugin thinks files don't exist
[() { return 1; }

export -f [

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_model)
ret=$?

unset -f [

check_output 3 "$err" $ret "$out"


start_test "no name, sku" # --------------------------------------------------------------------------------------------

[() {
  if test "$2" = "/sys/devices/virtual/dmi/id/product_name" ; then
    return 1
  fi;
}

export -f [

cat() { echo 'foo '; }

export -f cat

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_model)
ret=$?

unset -f [
unset -f cat

check_output 0 "METRIC OK: foo" $ret "$out"


start_test "name, no sku" # --------------------------------------------------------------------------------------------

[() {
  if test "$2" = "/sys/devices/virtual/dmi/id/product_sku" ; then
    return 1
  fi;
}

export -f [

# fake file contents
cat() { echo ' bar'; }

export -f cat

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_model)
ret=$?

unset -f [
unset -f cat

check_output 0 "METRIC OK: bar" $ret "$out"


start_test "empty model" # ---------------------------------------------------------------------------------------------

cat() { echo ''; }

export -f cat

out=$($script_path/../vendor/custom-plugins/check_cp_hardware_model)
ret=$?

unset -f cat

check_output 3 "$err" $ret "$out"


# ----------------------------------------------------------------------------------------------------------------------

finish_tests

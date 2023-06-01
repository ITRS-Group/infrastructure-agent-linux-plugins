# start_test <desc>
start_test() {
  ((test_id++))
  echo "Test $test_id: $1"
}

# check_ok <return code>
check_ok() {
  if [[ $1 != 0 ]]; then
    echo "Test $test_id failed: Non-OK exit code: $1"
    ((failures++))
  fi
}

# check_output <expected code> <expected string> <return code> <output>
check_output() {
  if [[ "$3" != "$1" ]]; then
    echo "Test $test_id failed: Wrong exit code: $3, expected $1"
    ((failures++))
  fi

  if [[ "$4" != "$2" ]]; then
    echo "Test $test_id failed: Wrong output: '$4', expected '$2'"
    ((failures++))
  fi
}

# check_output_regex <expected code> <expected regex> <return code> <output>
check_output_regex() {
  if [[ "$3" != "$1" ]]; then
    echo "Test $test_id failed: Wrong exit code: $3, expected $1"
    ((failures++))
  fi

  if ! [[ "$4" =~ $2 ]]; then
    echo "Test $test_id failed: Wrong output: '$4', expected to match '$2'"
    ((failures++))
  fi
}

finish_tests() {
  if [[ $failures = 0 ]];
  then
    echo "-- Tests OK --"
  else
    echo "!! Tests NOT OK, $failures failure(s) !!"
  fi

  exit $failures
}
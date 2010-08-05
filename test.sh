#!/bin/bash
# test.sh runs NeuroPipe's unit tests, which are contained in the "tests" dir
# author: mason simon (mgsimon@princeton.edu)

pushd tests > /dev/null
for test in *.sh; do
  bash $test > /dev/null 2> /dev/null
  if [ $? -eq 0 ]; then
    echo "SUCCESS: $test"
  else
    echo "FAILURE: $test"
  fi
done
popd > /dev/null

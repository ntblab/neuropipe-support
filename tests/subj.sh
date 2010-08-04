#!/bin/bash
# subj.sh tests that the variable $SUBJ is correct in a project's globals.sh 
# author: mason simon (mgsimon@princeton.edu)

TEST_DIR=subj-test
SUBJ_ID=asdf

bash ../np $TEST_DIR
pushd $TEST_DIR
bash scaffold $SUBJ_ID

pushd subjects/$SUBJ_ID
source globals.sh
popd

popd
rm -rf $TEST_DIR

if [ $SUBJ != $SUBJ_ID ]; then
  exit 1
fi

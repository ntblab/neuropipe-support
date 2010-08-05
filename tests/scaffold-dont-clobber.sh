#!/bin/bash
# scaffold-dont-clobber.sh tests that scaffold.sh won't overwrite files
# author: mason simon (mgsimon@princeton.edu)

TEST_DIR=clobber-test
TEST_TEXT=TEST
SUBJ_ID=subj

bash ../np $TEST_DIR
pushd $TEST_DIR

TEST_FILE=subjects/$SUBJ_ID/globals.sh
bash scaffold $SUBJ_ID
echo $TEST_TEXT > $TEST_FILE
bash scaffold $SUBJ_ID

if [ -n "$(echo $TEST_TEXT | diff $TEST_FILE -)" ]; then
  EXIT=1
else
  EXIT=0
fi

popd
rm -rf $TEST_DIR

exit $EXIT

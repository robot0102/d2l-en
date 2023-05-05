#!/bin/bash

set -ex

# Used to capture status exit of build eval command
ss=0

REPO_NAME="$1"  # Eg. 'd2l-en'
TARGET_BRANCH="$2" # Eg. 'master' ; if PR raised to master

pip3 install .
mkdir _build

# Move sanity check outside
d2lbook build outputcheck tabcheck

# Move aws copy commands for cache restore outside
echo "Retrieving tensorflow build cache"
aws s3 sync s3://preview.d2l.ai/ci_cache/"$REPO_NAME"-"$TARGET_BRANCH"/_build/eval_tensorflow/ _build/eval_tensorflow/ --delete --quiet --exclude 'data/*'

export TF_CPP_MIN_LOG_LEVEL=3
export TF_FORCE_GPU_ALLOW_GROWTH=true
# Continue the script even if some notebooks in build fail to
# make sure that cache is copied to s3 for the successful notebooks
d2lbook build eval --tab tensorflow || ((ss=1))

# Move aws copy commands for cache store outside
echo "Upload tensorflow build cache to s3"
aws s3 sync _build s3://preview.d2l.ai/ci_cache/"$REPO_NAME"-"$TARGET_BRANCH"/_build --acl public-read --quiet

if [ "$ss" -ne 0 ]; then
  exit 1
fi
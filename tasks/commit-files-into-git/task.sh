#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -eux
else
  set -eu
fi

git clone git-repo git-repo-updated

if [ ! -d "git-repo-updated/$FILES_PATH" ]; then
  mkdir -p git-repo-updated/$FILES_PATH
fi

cp -r src_dir/* git-repo-updated/$FILES_PATH/

pushd git-repo-updated
  git config --global user.email "${CI_EMAIL_ADDRESS}"
  git config --global user.name "${CI_USERNAME}"

  git add .
  git commit -m "$GIT_COMMIT_MESSAGE"
popd
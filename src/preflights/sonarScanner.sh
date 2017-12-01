#!/bin/bash

source ../config/common.sh
source ../config/circleci.sh

function sonarCheck() {
  if [ -z $GITHUB_PULL_REQUEST_URL ] && [ "$GITHUB_BRANCH" != "master" ] && [ "$GITHUB_BRANCH" != "staging" ];
  then
    echo "Stopping build as it is neither a pull-request, master nor staging."
    echo "${GITHUB_MAIN_DOC_PATH}${DOCUMENTATION_SCOPE}#syncronicity-issues"
    if [ -z $CI_API_TOKEN ];
      then
        echo "CI_API_TOKEN is not set.";
        echo "${GITHUB_MAIN_DOC_PATH}${DOCUMENTATION_SCOPE}#prerequisites"
        exit 1;
      else
        cancelBuild
    fi
  fi
}

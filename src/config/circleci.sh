#!/bin/bash

GITHUB_PULL_REQUEST_URL=${CIRCLE_PULL_REQUEST}
GITHUB_BRANCH=${CIRCLE_BRANCH}

function cancelBuild() {
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -XPOST "https://circleci.com/api/v1/project/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/${CIRCLE_BUILD_NUM}/cancel?circle-token=${CI_API_TOKEN}")
  if [ $STATUS_CODE == "200" ];
    then echo "This build was canceled.";
    else
      echo "Tried cancelling the build, but the ci token was invalid.";
      echo "${SONAR_LOGIN}${DOCUMENTATION_SCOPE}#prerequisites"
      exit -1;
  fi
}

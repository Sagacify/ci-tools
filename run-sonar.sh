#!/bin/bash

SONAR_VERSION="sonar-scanner-2.5.1"

function install() {
  wget -N "https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/${SONAR_VERSION}.zip";
  unzip -o "${SONAR_VERSION}.zip";
}

function run() {
  if [ $CI_PULL_REQUEST ];
    then ./$SONAR_VERSION/bin/sonar-runner \
      -Dsonar.host.url=$SONAR_HOST \
      -Dsonar.login=$SONAR_LOGIN \
      -Dsonar.password=$SONAR_PASSWORD \
      -Dsonar.projectKey=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME \
      -Dsonar.sourceEncoding=UTF-8 \
      -Dsonar.github.repository=$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME \
      -Dsonar.github.pullRequest=${CI_PULL_REQUEST##*/} \
      -Dsonar.github.oauth=$SAGA_STALIN_TOKEN \
      -Dsonar.analysis.mode=preview;
  elif [ "$CIRCLE_BRANCH" == "master" ];
    then ./$SONAR_VERSION/bin/sonar-runner \
      -Dsonar.host.url=$SONAR_HOST \
      -Dsonar.login=$SONAR_LOGIN \
      -Dsonar.password=$SONAR_PASSWORD \
      -Dsonar.projectKey=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME \
      -Dsonar.sourceEncoding=UTF-8;
  fi
}

function check() {
  if [ -z $CI_PULL_REQUEST ] && [ "$CIRCLE_BRANCH" != "master" ] && [ "$CIRCLE_BRANCH" != "staging" ];
  then
    curl -XPOST "https://circleci.com/api/v1/project/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/${CIRCLE_BUILD_NUM}/cancel?token=${CI_API_TOKEN}" > /dev/null;
    exit 1;
  fi
}

case "$1" in
        install)
            install
            ;;

        run)
            run
            ;;

        check)
            check
            ;;

        *)
            echo $"Usage: $0 {install|run|check}"
            exit 1
 
esac

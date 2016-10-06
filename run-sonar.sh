#!/bin/bash

SONAR_VERSION="sonar-scanner-2.8"

function install() {

  wget -N "https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/${SONAR_VERSION}.zip";
  unzip -o "${SONAR_VERSION}.zip";
}

function run() {
  # Params used everywhere
  DEFAULT_SONAR_PARAMS="-Dsonar.host.url=$SONAR_HOST
        -Dsonar.login=$SONAR_LOGIN
        -Dsonar.password=$SONAR_PASSWORD
        -Dsonar.projectName=$CIRCLE_PROJECT_REPONAME
        -Dsonar.projectVersion=$CIRCLE_BUILD_NUM
        -Dsonar.sourceEncoding=UTF-8"

  # If there is no sonar-project.properties, analyses src folder by default
  if [ ! -f "sonar-project.properties" ];
    then if [ -d "src" ];
      then DEFAULT_PARAMS+="-Dsonar.sources=src";
      else echo "If your source files are not in the src folder, you must define the sonar.sources property in sonar-project.properties";
        exit -1;
    fi
  fi

  if [ $CI_PULL_REQUEST ];
    if [ "$CIRCLE_BRANCH" != "staging" ] & [ "$STAGING_EXISTS" ];
      then SONAR_PROJECT_KEY=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME:staging
      else SONAR_PROJECT_KEY=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME
    fi
    then ./$SONAR_VERSION/bin/sonar-scanner $DEFAULT_SONAR_PARAMS \
      -Dsonar.projectKey=$SONAR_PROJECT_KEY \
      -Dsonar.github.repository=$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME \
      -Dsonar.github.pullRequest=${CI_PULL_REQUEST##*/} \
      -Dsonar.analysis.mode=preview;
  fi
  if [ "$CIRCLE_BRANCH" == "master" ];
    then ./$SONAR_VERSION/bin/sonar-scanner $DEFAULT_SONAR_PARAMS \
      -Dsonar.projectKey=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME;
  fi
  if [ "$CIRCLE_BRANCH" == "staging" ];
    then ./$SONAR_VERSION/bin/sonar-scanner DEFAULT_SONAR_PARAMS \
      -Dsonar.projectKey=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME:staging;
  fi
}

function check() {
  if type -p java; then
    echo found java executable in PATH
    _java=java
  elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
      echo found java executable in JAVA_HOME
      _java="$JAVA_HOME/bin/java"
  else
      echo "no java"
      exit 1
  fi

  if [[ "$_java" ]]; then
      version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
      echo version "$version"
      if [[ "$version" == *"1.8"* ]]; then
          echo "version is 1.8"
      else
          echo "version is not 1.8"
          exit 1
      fi
  fi

  if [ -z $CI_PULL_REQUEST ] && [ "$CIRCLE_BRANCH" != "master" ] && [ "$CIRCLE_BRANCH" != "staging" ];
  then
    echo "Stopping build as it neither a pull-request, master nor staging."
    if [ -z $CI_API_TOKEN ];
      then
        echo "CI_API_TOKEN is not set."; exit 1;
      else
        STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -XPOST "https://circleci.com/api/v1/project/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/${CIRCLE_BUILD_NUM}/cancel?circle-token=${CI_API_TOKEN}")
        if [ $STATUS_CODE == "200" ];
          then echo "This build was canceled.";
          else
            echo "Tried cancelling the build, but the ci token was invalid.";
            exit -1;
        fi
    fi
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

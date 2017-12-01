#!/bin/bash

function getJsCoverage() {
  if [ -f "sonar-project.properties" ];
    then SAGA_JS_COV=$(<sonar-project.properties grep 'sonar.javascript.lcov.reportPath=' | grep -o '[^=]*$');
  fi
  if [ -z $SAGA_JS_COV ] & [ -f "coverage/lcov.info" ];
    then SAGA_JS_COV="lcov_report.info"
      sed -e "s=/var/www=$(pwd)=" coverage/lcov.info > "$SAGA_JS_COV";
  fi
  if [ $SAGA_JS_COV ];
    then DEFAULT_SONAR_PARAMS+=" -Dsonar.javascript.lcov.reportPath=$SAGA_JS_COV";
  fi
}

function getPyCoverage() {
  if [ -f "sonar-project.properties" ];
    then SAGA_PY_COV=$(<sonar-project.properties grep 'sonar.python.coverage.reportPath=' | grep -o '[^=]*$');
  fi
  if [ -z $SAGA_PY_COV ] & [ -f "coverage/cov.xml" ];
    then SAGA_PY_COV="coverage/cov.xml"
  fi
  if [ $SAGA_PY_COV ];
    then DEFAULT_SONAR_PARAMS+=" -Dsonar.python.coverage.reportPath=$SAGA_PY_COV";
  fi
}

function getPyLintReport() {
   # detect if is python project;
  if (( $(find $SAGA_SOURCE_DIR | grep .py$ | wc -l) == 0 ));
    then return; # Not a python project
  fi

  if [ -f "sonar-project.properties" ];
    then SAGA_PY_LINT=$(<sonar-project.properties grep 'sonar.python.pylint.reportPath =' | grep -o '[^=]*$');
  fi

  if [ -z $SAGA_PY_LINT ];
    then if [ -f "coverage/pylint.report" ];
      then DEFAULT_SONAR_PARAMS+=" -sonar.python.pylint.reportPath=coverage/pylint.report";
      else pip install pylint;
    fi
  fi
}

function findSourceDir() {
  if [ $SAGA_SOURCE_DIR ]; then return; fi;

  if [ -f "sonar-project.properties" ];
    then SAGA_SOURCE_DIR=$(<sonar-project.properties grep 'sonar.sources=' | grep -o '[^=]*$');
  fi
  if [ $SAGA_SOURCE_DIR ]; then return; fi;

  if [ -d "src" ];
    then SAGA_SOURCE_DIR="src"
    else  echo "No src folder and no sonar-project.properties file."
          echo "Can't find project's sources."
          exit -1
  fi
}

function runSonarTest() {
  findSourceDir;
  # Params used everywhere
  DEFAULT_SONAR_PARAMS="-Dsonar.host.url=$SONAR_HOST
        -Dsonar.login=$SONAR_LOGIN
        -Dsonar.password=$SONAR_PASSWORD
        -Dsonar.projectName=$CIRCLE_PROJECT_REPONAME
        -Dsonar.projectVersion=$CIRCLE_BUILD_NUM
        -Dsonar.links.homepage=$CIRCLE_REPOSITORY_URL
        -Dsonar.links.ci=$CIRCLE_BUILD_URL
        -Dsonar.links.issue=$CIRCLE_REPOSITORY_URL/issues
        -Dsonar.links.scm=$CIRCLE_REPOSITORY_URL
        -Dsonar.sourceEncoding=UTF-8
        -Dsonar.sources=$SAGA_SOURCE_DIR"

  getJsCoverage;
  getPyCoverage;
  getPyLintReport;

  if [ $CI_PULL_REQUEST ];
    if [ "$CIRCLE_BRANCH" != "staging" ] & [ "$STAGING_EXISTS" ];
      then SONAR_PROJECT_KEY=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME:staging
      else SONAR_PROJECT_KEY=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME
    fi
    then /opt/$SONAR_VERSION/bin/sonar-scanner $DEFAULT_SONAR_PARAMS \
      -Dsonar.projectKey=$SONAR_PROJECT_KEY \
      -Dsonar.github.repository=$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME \
      -Dsonar.github.pullRequest=${CI_PULL_REQUEST##*/} \
      -Dsonar.github.oauth=$SAGA_STALIN_TOKEN \
      -Dsonar.analysis.mode=preview;
  fi
  if [ "$CIRCLE_BRANCH" == "master" ];
    then /opt/$SONAR_VERSION/bin/sonar-scanner $DEFAULT_SONAR_PARAMS \
      -Dsonar.projectKey=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME;
  fi
  if [ "$CIRCLE_BRANCH" == "staging" ];
    then /opt/$SONAR_VERSION/bin/sonar-scanner $DEFAULT_SONAR_PARAMS \
      -Dsonar.projectKey=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME:staging;
  fi
}

runSonarTest

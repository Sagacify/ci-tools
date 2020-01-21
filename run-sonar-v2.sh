#!/bin/bash

SONAR_ZIP_FILENAME="sonar-scanner-cli-3.3.0.zip"
SONAR_EXTRACTED_FOLDER="sonar-scanner-3.3.0"

function install() {
  wget -N "https://s3-eu-west-1.amazonaws.com/saga-ops/${SONAR_ZIP_FILENAME}";
  unzip -o "${SONAR_ZIP_FILENAME}";
}

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
      else pip3 install pylint;
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

function run() {
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


  if [ $CIRCLE_PULL_REQUEST ] || [ "$CIRCLE_BRANCH" == "master" ]
  then
	getJsCoverage;
	getPyCoverage;
	getPyLintReport;
	  if [ $CIRCLE_PULL_REQUEST ];
	    then
		echo "IF"
		SONAR_PROJECT_KEY=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME;
		./$SONAR_EXTRACTED_FOLDER/bin/sonar-scanner $DEFAULT_SONAR_PARAMS \
		-Dsonar.projectKey=$SONAR_PROJECT_KEY \
		-Dsonar.github.repository=$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME \
		-Dsonar.github.pullRequest=${CI_PULL_REQUEST##*/} \
		-Dsonar.github.oauth=$SAGA_STALIN_TOKEN \
		-Dsonar.analysis.mode=preview;
	  elif [ "$CIRCLE_BRANCH" == "master" ];
	    then
		 echo "ELSE"
		./$SONAR_EXTRACTED_FOLDER/bin/sonar-scanner $DEFAULT_SONAR_PARAMS \
	      -Dsonar.projectKey=$CIRCLE_PROJECT_USERNAME:$CIRCLE_PROJECT_REPONAME;
	  fi
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
          echo "https://github.com/Sagacify/atlas/wiki/Continuous-integration#java-8"
          exit 1
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

#!/bin/bash

source ./common.sh
source ../config/common.sh

OPENJDK_VERSION=${JAVA_VERSION: -1}

function checkJavaVersion {
  if [[ which java ]]; then
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
    if [[ "$version" == *"${JAVA_VERSION}"* ]]; then
      echo "version is ${JAVA_VERSION}"
    else
      echo "version is not ${JAVA_VERSION}"
      echo "${GITHUB_MAIN_DOC_PATH}${DOCUMENTATION_SCOPE}#java-8"
      exit 1
    fi
  fi
}

function uninstallJava {
  dpkg-query -W -f='${binary:Package}\n' | grep -E -e '^(ia32-)?(sun|oracle)-java' -e '^openjdk-' -e '^icedtea' -e '^(default|gcj)-j(re|dk)' -e '^gcj-(.*)-j(re|dk)' -e '^java-common' | xargs apt-get -y remove
  apt-get -y autoremove
  dpkg -l | grep ^rc | awk '{print($2)}' | xargs apt-get -y purge
  bash -c 'ls -d /home/*/.java' | xargs rm -rf
  rm -rf /usr/lib/jvm/*
  for g in ControlPanel java java_vm javaws jcontrol jexec keytool mozilla-javaplugin.so orbd pack200 policytool rmid rmiregistry servertool tnameserv unpack200 appletviewer apt extcheck HtmlConverter idlj jar jarsigner javac javadoc javah javap jconsole jdb jhat jinfo jmap jps jrunscript jsadebugd jstack jstat jstatd native2ascii rmic schemagen serialver wsgen wsimport xjc xulrunner-1.9-javaplugin.so; do update-alternatives --remove-all $g; done
  updatedb
  locate -b '\pack200'
}

function installJava {
  local installVersion=$1

  apt-get -q=2 -y install --no-install-recommends --no-upgrade \
    apt-transport-https \
    ca-certificates \
    software-properties-common

  echo "lauching installation of openjdk @ ${installVersion} !"

  add-apt-repository -y ppa:openjdk-r/ppa
  apt-get -q=2 update
  apt-get -q=2 install openjdk-${installVersion}-jdk
}

function javaInstaller {
  local installVersion=$1
  local name="java"

  if [[ $(programIsInstalled $name) -eq 1 ]]; then
    local currentVersion=$(getjavaVersion)

    if [[ $(minVersionCheck ${currentVersion} ${installVersion}) -eq 1 ]]; then
      echo "java already installed @ ${currentVersion} !"
    else
      echo "Unsintalling old java @ ${currentVersion} ..."
      uninstallJava
      installJava ${installVersion}
    fi
  else
    installJava ${installVersion}
  fi
}

# Test command:
javaInstaller ${OPENJDK_VERSION}

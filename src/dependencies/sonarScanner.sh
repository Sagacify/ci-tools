#!/bin/bash

source ./common.sh
source ../config/common.sh

function SonarScannerInstaller {
  local installVersion=$1

  curl -Lso "/opt/${installVersion}.zip" "https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/${installVersion}.zip";
  # mkdir "/opt/${installVersion}/"
  unzip -o "/opt/${installVersion}.zip" -d /opt;
}

# Test command:
SonarScannerInstaller ${SONAR_VERSION}



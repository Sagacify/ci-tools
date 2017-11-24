#!/bin/bash

. ./common.sh

function getDockerComposeVersion {
  local fullVersion=$(docker-compose --version)

  echo $(expr match "${fullVersion}" '.*version \([0-9.]\+\)')
}

function uninstallDockerCompose {
  local installPath=$(which docker-compose)

  rm ${installPath}
}

function installDockerCompose {
  local installVersion=$1
  local fullName="docker-compose-$(uname -s)-$(uname -m)"

  echo "Installing docker-compose @ ${installVersion} ..."

  curl -L -s \
    https://github.com/docker/compose/releases/download/${installVersion}/${fullName} \
    > /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
}

function dockerComposeInstaller {
  local installVersion=$1
  local name="docker-compose"

  if [[ $(programIsInstalled $name) -eq 1 ]]; then
    local currentVersion=$(getDockerComposeVersion)
    echo ${currentVersion}
    if [[ $(minVersionCheck ${currentVersion} ${installVersion}) -eq 1 ]]; then
      echo "Docker Compose already installed @ ${currentVersion} !"
    else
      echo "Unsintalling old Docker Compose @ ${currentVersion} ..."
      uninstallDockerCompose
      installDockerCompose ${installVersion}
    fi
  else
    installDockerCompose ${installVersion}
  fi
}

# Test command:
# dockerComposeInstaller 1.17.0

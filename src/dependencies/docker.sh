#!/bin/bash

. ./common.sh

function getDockerVersion {
  local fullVersion=$(docker --version)
  echo $(expr match "${fullVersion}" '.*version \([0-9.]\+\)')
}

function uninstallDocker {
  apt-get -q=2 remove docker docker-engine docker.io docker-ce
}

function installDocker {
  local installVersion=$1
  local minVersionCE=17.09
  local dockerType

  apt-get -q=2 -y install --no-install-recommends --no-upgrade \
    apt-transport-https \
    ca-certificates \
    software-properties-common

  if [[ $(minVersionCheck ${installVersion} ${minVersionCE}) -eq 1 ]]; then
    dockerType="docker-ce"

    echo "Installing Docker CE @ ${installVersion} ..."

    apt-key adv \
      --keyserver hkp://p80.pool.sks-keyservers.net:80 \
      --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    add-apt-repository \
      "deb [arch=amd64] https://apt.dockerproject.org/repo \
      ubuntu-$(lsb_release -cs) \
      main"
  else
    dockerType="docker-engine"

    echo "Installing Docker Engine @ ${installVersion} ..."

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      stable"
  fi

  apt-get -q=2 update
  apt-get -q=2 install ${dockerType}=${installVersion}\*
}

function dockerInstaller {
  local installVersion=$1
  local name="docker"

  if [[ $(programIsInstalled $name) -eq 1 ]]; then
    local currentVersion=$(getDockerVersion)

    if [[ $(minVersionCheck ${currentVersion} ${installVersion}) -eq 1 ]]; then
      echo "Docker already installed @ ${currentVersion} !"
    else
      echo "Unsintalling old Docker @ ${currentVersion} ..."
      uninstallDocker
      installDocker ${installVersion}
    fi
  else
    installDocker ${installVersion}
  fi
}

# Test command:
# dockerInstaller '17.09'

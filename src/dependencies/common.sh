#!/bin/bash

function programIsInstalled {
  local result=1

  which $1 >/dev/null 2>&1 || { local result=0; }

  echo "${result}"
}

function minVersionCheck {
  # $1 = current version, $2 = minimum version
  if [[ $(echo "$@" | tr " " "\n" | sort -rV | head -n 1)  == "$1" ]]; then
    echo 1
  else
    echo 0
  fi
}

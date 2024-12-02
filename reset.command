#!/usr/bin/env bash

COLOR_INFO='\033[0;34m'
COLOR_ERR='\033[0;35m'
COLOR_WARN='\033[0;93m'
NOCOLOR='\033[0m'

PDFM_VER="19.1.0-54729"
PDFM_DIR="/Applications/Parallels Desktop.app"

PDFM_DISP_DIR="${PDFM_DIR}/Contents/MacOS/Parallels Service.app/Contents/MacOS"
PDFM_DISP_DST="${PDFM_DISP_DIR}/prl_disp_service"
PDFM_DISP_PATCH="${PDFM_DISP_DST}_patched"

# check root permission
if [ "$EUID" -ne 0 ]; then
  echo -e "${COLOR_ERR}[-] Missing root permission, run sudo.${NOCOLOR}"
  exec sudo "$0" "$@"
  exit 5
fi

# stop prl_disp_service
if pgrep -x "prl_disp_service" &> /dev/null; then
  echo -e "${COLOR_INFO}[*] Stopping Parallels Desktop${NOCOLOR}"
  pkill -9 prl_client_app &>/dev/null
  # ensure prl_disp_service has stopped
  "${PDFM_DIR}/Contents/MacOS/Parallels Service" service_stop &>/dev/null
  sleep 1
  launchctl stop /Library/LaunchDaemons/com.parallels.desktop.launchdaemon.plist &>/dev/null
  sleep 1
  pkill -9 prl_disp_service &>/dev/null
  sleep 1
  rm -f "/var/run/prl_*"
fi

echo -e "${COLOR_INFO}[*] Resetting...${NOCOLOR}"

cp -f "$PDFM_DISP_PATCH" "$PDFM_DISP_DST"

# start prl_disp_service
if ! pgrep -x "prl_disp_service" &>/dev/null; then
  echo -e "${COLOR_INFO}[*] Starting Parallels Service${NOCOLOR}"
  "${PDFM_DIR}/Contents/MacOS/Parallels Service" service_restart &>/dev/null
  for (( i=0; i < 10; ++i ))
  do
    if pgrep -x "prl_disp_service" &>/dev/null; then
      break
    fi
    sleep 1
  done
  if ! pgrep -x "prl_disp_service" &>/dev/null; then
    echo -e "${COLOR_ERR}[x] Starting Service fail.${NOCOLOR}"
  fi
fi

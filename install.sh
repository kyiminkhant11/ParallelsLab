#!/usr/bin/env bash

COLOR_INFO='\033[0;34m'
COLOR_ERR='\033[0;35m'
COLOR_WARN='\033[0;93m'
COLOR_OK='\033[1;32m'
NOCOLOR='\033[0m'

BASE_PATH=$(
  cd $(dirname "$0");
  pwd
)

TMP_DIR="${BASE_PATH}/tmp"

PDFM_VER="19.1.1-54734"
PDFM_DIR="/Applications/Parallels Desktop.app"

LICENSE_FILE="${BASE_PATH}/licenses.json"
LICENSE_DST="/Library/Preferences/Parallels/licenses.json"

PDFM_DISP_DIR="${PDFM_DIR}/Contents/MacOS/Parallels Service.app/Contents/MacOS"
PDFM_DISP_DST="${PDFM_DISP_DIR}/prl_disp_service"
PDFM_DISP_BCUP="${PDFM_DISP_DST}_bcup"
PDFM_DISP_PATCH="${PDFM_DISP_DST}_patched"
PDFM_DISP_ENT="${BASE_PATH}/ParallelsService.entitlements"
PDFM_DISP_HASH="acc0dd89003bad65ecd4275e04b6f1446ee135dfe3db3ff6f378d3f766c20e48"

PDFM_VM_DIR="${PDFM_DIR}/Contents/MacOS/Parallels VM.app/Contents/MacOS"
PDFM_VM_DST="${PDFM_VM_DIR}/prl_vm_app"
PDFM_VM_DST_TMP="${TMP_DIR}/prl_vm_app"
PDFM_VM_BCUP="${PDFM_VM_DST}_bcup"
PDFM_VM_ENT="${BASE_PATH}/ParallelsVM.entitlements"
PDFM_VM_HASH="63eae5502adef612f2f0c28b5db8b113125403bebbaaa95732dcef549d5e9a61"

PDFM_VM_INFO_DST="${PDFM_DIR}/Contents/MacOS/Parallels VM.app/Contents/Info.plist"
PDFM_VM_INFO_BCUP="${PDFM_VM_INFO_DST}_bcup"
PDFM_VM_INFO_HASH="7c2caa40ad5f7b251f23b3b69f2539ef51e7da84c8105f3bab6215dc56217f48"

PDFM_FRAMEWORKS_DIR="${PDFM_DIR}/Contents/Frameworks"

PDFM_QTXML_DIR="${PDFM_FRAMEWORKS_DIR}/QtXml.framework/Versions/5"
PDFM_QTXML_DST="${PDFM_QTXML_DIR}/QtXml"
PDFM_QTXML_HASH="731fbabb913f58ce91238883a59f8759badc56775b04aef6993aa36b21841137"

SUBM_DIR="${BASE_PATH}/submodules"

INSERT_DYLIB_DIR="${SUBM_DIR}/insert_dylib"
INSERT_DYLIB_PRJ="${INSERT_DYLIB_DIR}/insert_dylib.xcodeproj"
INSERT_DYLIB_BIN="${INSERT_DYLIB_DIR}/build/Release/insert_dylib"

HOOK_PARALLELS_DIR="${SUBM_DIR}/hook_parallels"
HOOK_PARALLELS_MAKEFILE="${HOOK_PARALLELS_DIR}/Makefile"
HOOK_PARALLELS_VARS="${HOOK_PARALLELS_DIR}/variables.sh"
HOOK_PARALLELS_DYLIB="${HOOK_PARALLELS_DIR}/libHookParallels.dylib"
HOOK_PARALLELS_DYLIB_DST="${PDFM_FRAMEWORKS_DIR}/libHookParallels.dylib"
HOOK_PARALLELS_LOAD="@rpath/libHookParallels.dylib"

MASK_DIR="${SUBM_DIR}/mask"
MASK_MAKEFILE="${MASK_DIR}/Makefile"
MASK_APPLY_BIN="${MASK_DIR}/apply_mask"
MASK_VM_54734_TO_54729="${BASE_PATH}/prl_vm_app-mask-54734_to_54729.bin"
MASK_VM_INFO_54734_TO_54729="${BASE_PATH}/prl_vm-info-mask-54734_to_54729.bin"

MACKED_DYLIB="${BASE_PATH}/macked.app.dylib"
MACKED_DYLIB_DST="${PDFM_FRAMEWORKS_DIR}/macked.app.dylib"
MACKED_DYLIB_LOAD="@rpath/macked.app.dylib"

MODE_DOWNGRADE_VM=0
MODE_NO_USB=1
MODE_NO_SIP=2

# check mode
if [ "$1" == "downgrade_vm" ]; then
  MODE=$MODE_DOWNGRADE_VM
elif [ "$1" == "no_usb" ]; then
  MODE=$MODE_NO_USB
elif [ "$1" == "no_sip" ]; then
  MODE=$MODE_NO_SIP
else
  echo -e "${COLOR_ERR}[-] Invalid mode flag.${NOCOLOR}"
  echo -e "${COLOR_ERR}[-] The syntax is \"./install.sh <mode>\"${NOCOLOR}"
  echo -e "${COLOR_ERR}[-] \"<mode>\" is a placeholder that needs to be replaced with the actual mode, for example \"sudo ./install.sh downgrade_vm\"${NOCOLOR}"
  exit 1
fi

# check parallels installation
if [ ! -d "$PDFM_DIR" ]; then
  echo -e "${COLOR_ERR}[-] Parallels Desktop installation not found.${NOCOLOR}"
  exit 2
fi

# check parallels desktop version
VERSION_1=$(defaults read "${PDFM_DIR}/Contents/Info.plist" CFBundleShortVersionString)
VERSION_2=$(defaults read "${PDFM_DIR}/Contents/Info.plist" CFBundleVersion)
INSTALL_VER="${VERSION_1}-${VERSION_2}"
if [ "${PDFM_VER}" != "${VERSION_1}-${VERSION_2}" ]; then
  echo -e "${COLOR_ERR}[-] This script is for ${PDFM_VER}, but your's is ${INSTALL_VER}.${NOCOLOR}"
  exit 2
fi

# check submodule files
if [ ! -d "$INSERT_DYLIB_PRJ" ] || [ ! -f "$HOOK_PARALLELS_MAKEFILE" ]; then
  echo -e "${COLOR_ERR}[-] Missing submodule files, perhaps you forgot to execute \"git submodule update --init --recursive\"${NOCOLOR}"
  exit 2
fi

# check state of qtxml
# (once modified, it cannot be recovered... unlike the other binaries)
if [ ! -f "$PDFM_QTXML_DST" ] || [ $(shasum -a 256 "$PDFM_QTXML_DST" | awk '{print $1}') != "$PDFM_QTXML_HASH" ]; then
  echo -e "${COLOR_ERR}[-] Invalid state of QtXml (cannot ever be recovered), please reinstall Parallels Desktop.\"${NOCOLOR}"
  exit 1
fi

# check root permission
if [ "$EUID" -ne 0 ]; then
  echo -e "${COLOR_ERR}[-] Missing root permission, run sudo.${NOCOLOR}"
  exec sudo "$0" "$@"
  exit 5
fi

# check state of pdfm disp
need_recover_pdfm_disp=false

if [ ! -f "$PDFM_DISP_DST" ] || [ $(shasum -a 256 "$PDFM_DISP_DST" | awk '{print $1}') != "$PDFM_DISP_HASH" ]; then
  need_recover_pdfm_disp=true
fi

# check state of pdfm disp bcup
need_backup_pdfm_disp=true

if [ -f "$PDFM_DISP_BCUP" ] && [ $(shasum -a 256 "$PDFM_DISP_BCUP" | awk '{print $1}') == "$PDFM_DISP_HASH" ]; then
  need_backup_pdfm_disp=false
fi

# recover pdfm disp if necessary 
if [ "$need_recover_pdfm_disp" = true ]; then
  if [ "$need_backup_pdfm_disp" = true ]; then
    echo -e "${COLOR_ERR}[-] State of Parallels Disp is invalid and a valid backup could not be found. Please reinstall Parallels.${NOCOLOR}"
    exit 2
  fi
  echo -e "${COLOR_WARN}[-] State of Parallels Disp is invalid, recover from backup.${NOCOLOR}"
  cp -f "$PDFM_DISP_BCUP" "$PDFM_DISP_DST"
fi

# backup pdfm disp if necessary
if [ "$need_backup_pdfm_disp" = true ]; then
  cp -f "${PDFM_DISP_DST}" "${PDFM_DISP_BCUP}"
fi

# check state of pdfm vm
need_recover_pdfm_vm=false

if [ ! -f "$PDFM_VM_DST" ] || [ $(shasum -a 256 "$PDFM_VM_DST" | awk '{print $1}') != "$PDFM_VM_HASH" ]; then
  need_recover_pdfm_vm=true
fi

# check state of pdfm vm bcup
need_backup_pdfm_vm=true

if [ -f "$PDFM_VM_BCUP" ] && [ $(shasum -a 256 "$PDFM_VM_BCUP" | awk '{print $1}') == "$PDFM_VM_HASH" ]; then
  need_backup_pdfm_vm=false
fi

# recover pdfm vm if necessary 
if [ "$need_recover_pdfm_vm" = true ]; then
  if [ "$need_backup_pdfm_vm" = true ]; then
    echo -e "${COLOR_ERR}[-] State of Parallels VM is invalid and a valid backup could not be found. Please reinstall Parallels.${NOCOLOR}"
    exit 2
  fi
  echo -e "${COLOR_WARN}[-] State of Parallels VM is invalid, recover from backup.${NOCOLOR}"
  cp -f "$PDFM_VM_BCUP" "$PDFM_VM_DST"
fi

# backup pdfm vm if necessary
if [ "$need_backup_pdfm_vm" = true ]; then
  cp -f "${PDFM_VM_DST}" "${PDFM_VM_BCUP}"
fi

# check state of pdfm vm info
need_recover_pdfm_vm_info=false

if [ ! -f "$PDFM_VM_INFO_DST" ] || [ $(shasum -a 256 "$PDFM_VM_INFO_DST" | awk '{print $1}') != "$PDFM_VM_INFO_HASH" ]; then
  need_recover_pdfm_vm_info=true
fi

# check state of pdfm vm info bcup
need_backup_pdfm_vm_info=true

if [ -f "$PDFM_VM_INFO_BCUP" ] && [ $(shasum -a 256 "$PDFM_VM_INFO_BCUP" | awk '{print $1}') == "$PDFM_VM_INFO_HASH" ]; then
  need_backup_pdfm_vm_info=false
fi

# recover pdfm vm if necessary 
if [ "$need_recover_pdfm_vm_info" = true ]; then
  if [ "$need_backup_pdfm_vm_info" = true ]; then
    echo -e "${COLOR_ERR}[-] State of Parallels VM Info is invalid and a valid backup could not be found. Please reinstall Parallels.${NOCOLOR}"
    exit 2
  fi
  echo -e "${COLOR_WARN}[-] State of Parallels VM Info is invalid, recover from backup.${NOCOLOR}"
  cp -f "$PDFM_VM_INFO_BCUP" "$PDFM_VM_INFO_DST"
fi

# backup pdfm vm if necessary
if [ "$need_backup_pdfm_vm_info" = true ]; then
  cp -f "${PDFM_VM_INFO_DST}" "${PDFM_VM_INFO_BCUP}"
fi

echo -e "${COLOR_INFO}[*] Compiling...${NOCOLOR}"

# compile insert_dylib if neccessary
if [ ! -f "$INSERT_DYLIB_BIN" ]; then
  sudo -u $SUDO_USER xcodebuild -project "$INSERT_DYLIB_PRJ"
  if [ ! -f "$INSERT_DYLIB_BIN" ]; then
    echo -e "${COLOR_ERR}[-] Compiled insert_dylib binary not found.${NOCOLOR}"
    exit 2
  fi
fi

# compile HookParallels
if [ $MODE == $MODE_DOWNGRADE_VM ]; then
  sudo -u $SUDO_USER sed "s|export VM_54729=0|export VM_54729=1|g" "$HOOK_PARALLELS_VARS" > tmpfile
else
  sudo -u $SUDO_USER sed "s|export VM_54729=1|export VM_54729=0|g" "$HOOK_PARALLELS_VARS" > tmpfile
fi
sudo -u $SUDO_USER mv -f tmpfile "$HOOK_PARALLELS_VARS"
cd "${HOOK_PARALLELS_DIR}"
make clean
sudo -u $SUDO_USER make
if [ ! -f "$HOOK_PARALLELS_DYLIB" ]; then
  echo -e "${COLOR_ERR}[-] Compiled HookParallels dylib not found.${NOCOLOR}"
  exit 2
fi

# compile mask if neccessary
if [ ! -f "${MASK_APPLY_BIN}" ] && [ $MODE == $MODE_DOWNGRADE_VM ]; then
  cd "${MASK_DIR}"
  sudo -u $SUDO_USER make
  cd "${BASE_PATH}"
  if [ ! -f "${MASK_APPLY_BIN}" ]; then
    echo -e "${COLOR_ERR}[-] Compiled apply_mask binary not found.${NOCOLOR}"
    exit 2
  fi
  cd "${BASE_PATH}"
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

echo -e "${COLOR_INFO}[*] Installing...${NOCOLOR}"

if [ $MODE == $MODE_NO_USB ] && [ ! -d "$TMP_DIR" ]; then
  mkdir "$TMP_DIR"
fi

# install HookParallels dylib
cp -f "$HOOK_PARALLELS_DYLIB" "$HOOK_PARALLELS_DYLIB_DST"
chown root:wheel "${HOOK_PARALLELS_DYLIB_DST}"
chmod 755 "${HOOK_PARALLELS_DYLIB_DST}"
xattr -d com.apple.quarantine "$HOOK_PARALLELS_DYLIB_DST"
codesign -f -s - --timestamp=none --all-architectures "${HOOK_PARALLELS_DYLIB_DST}"

# install macked dylib
if [ $MODE == $MODE_NO_USB ]; then
  cp -f "$MACKED_DYLIB" "$MACKED_DYLIB_DST"
  chown root:wheel "${MACKED_DYLIB_DST}"
  chmod 755 "${MACKED_DYLIB_DST}"
  xattr -d com.apple.quarantine "$MACKED_DYLIB_DST"
  codesign -f -s - --timestamp=none --all-architectures "${MACKED_DYLIB_DST}"
elif [ -f "$MACKED_DYLIB_DST" ]; then
  rm "$MACKED_DYLIB_DST"
fi

# patch qtxml if neccessary
if [ $MODE == $MODE_NO_SIP ]; then
  chflags -R 0 "${PDFM_QTXML_DST}"
  "$INSERT_DYLIB_BIN" --no-strip-codesig --inplace "$HOOK_PARALLELS_LOAD" "$PDFM_QTXML_DST"
  chown root:wheel "${PDFM_QTXML_DST}"
  chmod 755 "${PDFM_QTXML_DST}"
  codesign -f -s - --timestamp=none --all-architectures "${PDFM_QTXML_DST}"
fi

# patch dispatcher
chflags -R 0 "${PDFM_DISP_DST}"

if [ $MODE == $MODE_DOWNGRADE_VM ]; then
  "$INSERT_DYLIB_BIN" --no-strip-codesig --inplace "$HOOK_PARALLELS_LOAD" "$PDFM_DISP_DST"
  chown root:wheel "${PDFM_DISP_DST}"
  chmod 755 "${PDFM_DISP_DST}"
  codesign -f -s - --timestamp=none --all-architectures --entitlements "${PDFM_DISP_ENT}" "${PDFM_DISP_DST}"
fi

if [ $MODE == $MODE_NO_USB ]; then
  "$INSERT_DYLIB_BIN" --no-strip-codesig --inplace "$MACKED_DYLIB_LOAD" "$PDFM_DISP_DST"
  chown root:wheel "${PDFM_DISP_DST}"
  chmod 755 "${PDFM_DISP_DST}"
  codesign -f -s - --timestamp=none --all-architectures --entitlements "${PDFM_DISP_ENT}" "${PDFM_DISP_DST}"
fi

if [ $MODE == $MODE_DOWNGRADE_VM ]; then
  cp -f "${PDFM_DISP_DST}" "${PDFM_DISP_PATCH}"
  chown -R root:admin "${PDFM_DISP_DIR}"
elif [ -f "${PDFM_DISP_PATCH}" ]; then
  rm "${PDFM_DISP_PATCH}"
fi

# downgrade vm if neccessary
if [ $MODE == $MODE_DOWNGRADE_VM ]; then
  "$MASK_APPLY_BIN" "-s$PDFM_VM_BCUP" "-m$MASK_VM_54734_TO_54729" "-o$PDFM_VM_DST"
  "$MASK_APPLY_BIN" "-s$PDFM_VM_INFO_BCUP" "-m$MASK_VM_INFO_54734_TO_54729" "-o$PDFM_VM_INFO_DST"
fi

# patch vm if neccessary
if [ $MODE == $MODE_NO_USB ]; then
  chflags -R 0 "${PDFM_VM_DST}"
  cp -f "$PDFM_VM_BCUP" "$PDFM_VM_DST_TMP"
  "$INSERT_DYLIB_BIN" --no-strip-codesig --inplace "$HOOK_PARALLELS_LOAD" "$PDFM_VM_DST"
  chown root:wheel "${PDFM_VM_DST}"
  chmod 755 "${PDFM_VM_DST}"
  codesign -f -s - --timestamp=none --all-architectures --deep --entitlements "${PDFM_VM_ENT}" "${PDFM_VM_DST}"
  cp -f "$PDFM_VM_DST_TMP" "$PDFM_VM_BCUP"
fi

# install fake license
if [ -f "${LICENSE_DST}" ]; then
  chflags -R 0 "${LICENSE_DST}"
  rm -f "${LICENSE_DST}" > /dev/null
fi

if [ $MODE != $MODE_NO_USB ]; then
  cp -f "${LICENSE_FILE}" "${LICENSE_DST}"
  chown root:wheel "${LICENSE_DST}"
  chmod 444 "${LICENSE_DST}"
  chflags -R 0 "${LICENSE_DST}"
  chflags uchg "${LICENSE_DST}"
  chflags schg "${LICENSE_DST}"
fi

# clean
if [ -d "$TMP_DIR" ]; then
  rm -rf "$TMP_DIR"
fi

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

"${PDFM_DIR}/Contents/MacOS/prlsrvctl" web-portal signout &>/dev/null
"${PDFM_DIR}/Contents/MacOS/prlsrvctl" set --cep off &>/dev/null
"${PDFM_DIR}/Contents/MacOS/prlsrvctl" set --allow-attach-screenshots off &>/dev/null

echo -e ""
echo -e "${COLOR_OK}Do you want to express gratitude for our reverse engineering efforts?${NOCOLOR}"
echo -e ""
echo -e "${COLOR_OK}[ PayPal ] trueToastedCode (Involved in versions 18.3 - 19.1.1)${NOCOLOR}"
echo -e "${COLOR_OK}paypal.me/Lennard478${NOCOLOR}"
echo -e ""
echo -e "${COLOR_OK}[ PayPal ] alsyundawy (Involved in versions 18.0 - 18.1)${NOCOLOR}"
echo -e "${COLOR_OK}https://paypal.me/alsyundawy${NOCOLOR}"
echo -e ""
echo -e "${COLOR_OK}[ PayPal ] QiuChenly (Inspired trueToastedCode on dylib-injections in 19.1)${NOCOLOR}"
echo -e "${COLOR_OK}https://github.com/QiuChenly${NOCOLOR}"
echo -e ""

echo -e "${COLOR_WARN}[⚠] The No USB method relies on closed source for the Dispatcher but uses open source code for the VM, which fixes a Network error, I am not able to reproduce.${NOCOLOR}"
echo -e "${COLOR_WARN}[⚠] Maybe you are able to reverse engineer this hack 😉.${NOCOLOR}"

if [ $MODE == $MODE_DOWNGRADE_VM ]; then
  echo -e ""
  echo -e "${COLOR_WARN}[⚠] Mixing versions doesn't work on all system, try or downgrade.${NOCOLOR}"
  echo -e "${COLOR_WARN}[⚠] Don't fully quit and reopen Parallels very quickly. It's automatically resetting the crack using hooked functions but this may break it.${NOCOLOR}"
  echo -e "${COLOR_WARN}[⚠] In case you're crack stops working, reset it using \"reset.command\".${NOCOLOR}"
fi

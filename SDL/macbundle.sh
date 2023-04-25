#!/bin/bash

echo "Hello"

PPSSPP="${1}"
PPSSPPSDL="${PPSSPP}/Contents/MacOS/PPSSPPSDL"

ls ${PPSSPPSDL}

if [ ! -f "${PPSSPPSDL}" ]; then
  echo "No such file: ${PPSSPPSDL}!"
  exit 0
fi

echo pwd=`pwd`
echo PPSSPP=$PPSSPP
echo PPSSPPSDL=$PPSSPPSDL

cd "$(dirname "$0")"
RPATH="$(pwd)/macOS"
cd -
echo RPATH=$RPATH
SDL="${RPATH}/SDL2.framework"
if [ ! -d "${SDL}" ]; then
  echo "Cannot locate SDL.framework: ${SDL}!"
  exit 0
fi

rm -rf "${PPSSPP}/Contents/Frameworks/SDL2.framework" || exit 0
mkdir -p "${PPSSPP}/Contents/Frameworks" || exit 0
cp -a "$SDL" "${PPSSPP}/Contents/Frameworks" || exit 0
echo install_name_tool -rpath "${RPATH}" "@executable_path/../Frameworks" "${PPSSPPSDL}" || echo "Already patched."
install_name_tool -rpath "${RPATH}" "@executable_path/../Frameworks" "${PPSSPPSDL}" || echo "Already patched."

echo "Done."

GIT_VERSION_LINE=$(grep "PPSSPP_GIT_VERSION = " "$(dirname "${0}")/../git-version.cpp")
# Hack, need to do something better here.
if [ -z "$GIT_VERSION_LINE" ]; then
  GIT_VERSION_LINE=$(grep "PPSSPP_GIT_VERSION = " "$(dirname "${0}")/../build/git-version.cpp")
fi

echo "Setting version to '${GIT_VERSION_LINE}'..."
SHORT_VERSION_MATCH='.*"v([0-9\.]+(-[0-9]+)?).*";'
LONG_VERSION_MATCH='.*"v(.*)";'
if [[ "${GIT_VERSION_LINE}" =~ ^${SHORT_VERSION_MATCH}$ ]]; then
	plutil -replace CFBundleShortVersionString -string $(echo ${GIT_VERSION_LINE} | perl -pe "s/${SHORT_VERSION_MATCH}/\$1/g") ${PPSSPP}/Contents/Info.plist
	plutil -replace CFBundleVersion            -string $(echo ${GIT_VERSION_LINE} | perl -pe "s/${LONG_VERSION_MATCH}/\$1/g")  ${PPSSPP}/Contents/Info.plist
else
	plutil -replace CFBundleShortVersionString -string "" ${PPSSPP}/Contents/Info.plist
	plutil -replace CFBundleVersion            -string "" ${PPSSPP}/Contents/Info.plist
fi

# AdHoc codesign is required for Apple Silicon.
echo "Signing..."
codesign -fs - --entitlements ../macOS/Entitlements.plist --timestamp "${PPSSPPSDL}" || echo "Failed signing"
codesign -fs - --entitlements ../macOS/Entitlements.plist --timestamp "${PPSSPP}" || echo "Failed signing"

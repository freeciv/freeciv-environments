#!/bin/bash

if ! test -x "$1/docker_run.sh" ; then
  echo "$1 not a crosser docker scripts directory" >&2
  exit 1
fi

if test "$2" != "main" &&
   test "$2" != "S3_3" &&
   test "$2" != "S3_2" &&
   test "$2" != "S3_1" &&
   test "$2" != "S3_0" ; then
  echo "Unknown branch \"$2\"" >&2
  exit 1
fi
if test "$3" = "" ; then
  echo "No Build number given" >&2
  exit 1
fi
if test "$4" = "" ; then
  echo "No commit given" >&2
  exit 1
fi

MAINDIR="$(cd $(dirname $0) ; pwd)"
DOCKDIR="$1"
BRANCH="$2"
BNBR="$3"
SCOMMIT="$4"

if ! test -f "${MAINDIR}/${BRANCH}/.git" ; then
  echo "No git clone at \"${MAINDIR}/${BRANCH}\"" >&2
  exit 1
fi

cd "$DOCKDIR"

./docker_run.sh "${MAINDIR}/${BRANCH}"

cd "$MAINDIR"

if test "${BRANCH}" = "main" || test "${BRANCH}" = "S3_3" ; then

ls -1 ${BRANCH}/platforms/windows/installer_cross/meson/output/Freeciv-*-setup.exe | ( while read ONAME ; do
  NNAME=$(echo "$ONAME" | sed "s,-setup.exe,-${SCOMMIT}-setup.exe,")
  echo "$NNAME" | sed "s,^${BRANCH}/platforms/windows/installer_cross/meson/output/,${BNBR}: crosser/," >> $BRANCH.files
  mv "$ONAME" "$NNAME"
  mv "$NNAME" "nightly/${BRANCH}/crosser/"
  done )

ls -1 ${BRANCH}/platforms/windows/installer_cross/meson/output/freeciv-*.7z | ( while read ONAME ; do
  NNAME=$(echo "$ONAME" | sed "s,.7z,-${SCOMMIT}.7z,")
  echo "$NNAME" | sed "s,^${BRANCH}/platforms/windows/installer_cross/meson/output/,${BNBR}: crosser/portable/," >> $BRANCH.files
  mv "$ONAME" "$NNAME"
  mv "$NNAME" "nightly/${BRANCH}/crosser/portable/"
  done )

elif test "${BRANCH}" = "S3_2" ; then

ls -1 ${BRANCH}/windows/installer_cross/meson/output/Freeciv-*-setup.exe | ( while read ONAME ; do
  NNAME=$(echo "$ONAME" | sed "s,-setup.exe,-${SCOMMIT}-setup.exe,")
  echo "$NNAME" | sed "s,^${BRANCH}/windows/installer_cross/meson/output/,${BNBR}: crosser/," >> $BRANCH.files
  mv "$ONAME" "$NNAME"
  mv "$NNAME" "nightly/${BRANCH}/crosser/"
  done )

ls -1 ${BRANCH}/windows/installer_cross/meson/output/freeciv-*.7z | ( while read ONAME ; do
  NNAME=$(echo "$ONAME" | sed "s,.7z,-${SCOMMIT}.7z,")
  echo "$NNAME" | sed "s,^${BRANCH}/windows/installer_cross/meson/output/,${BNBR}: crosser/portable/," >> $BRANCH.files
  mv "$ONAME" "$NNAME"
  mv "$NNAME" "nightly/${BRANCH}/crosser/portable/"
  done )

else
  # Old S3_0 & S3_1 directory hierarchy
ls -1 ${BRANCH}/windows/installer_cross/Output/Freeciv-*-setup.exe | ( while read ONAME ; do
  NNAME=$(echo "$ONAME" | sed "s,-setup.exe,-${SCOMMIT}-setup.exe,")
  echo "$NNAME" | sed "s,^${BRANCH}/windows/installer_cross/Output/,${BNBR}: crosser/," >> $BRANCH.files
  mv "$ONAME" "$NNAME"
  mv "$NNAME" "nightly/${BRANCH}/crosser/"
  done )

ls -1 ${BRANCH}/windows/installer_cross/Output/freeciv-*.7z | ( while read ONAME ; do
  NNAME=$(echo "$ONAME" | sed "s,.7z,-${SCOMMIT}.7z,")
  echo "$NNAME" | sed "s,^${BRANCH}/windows/installer_cross/Output/,${BNBR}: crosser/portable/," >> $BRANCH.files
  mv "$ONAME" "$NNAME"
  mv "$NNAME" "nightly/${BRANCH}/crosser/portable/"
  done )
fi

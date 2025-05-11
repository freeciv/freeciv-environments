#!/bin/bash

BRANCH=S3_2
MAINDIR="$(cd $(dirname "$0") ; pwd)"

cd "$MAINDIR"

OLDCOMMIT="$(cat ${BRANCH}.weekly.commit)"

if ! cd "${MAINDIR}/${BRANCH}" ; then
  echo "Failed to enter \"${MAINDIR}/${BRANCH}\"!" >&2
  exit 1
fi

rm -Rf tarbuild
rm -Rf docbuild

git checkout translations
git checkout ChangeLog
git pull
COMMIT="$(git rev-parse HEAD)"

if test "${COMMIT}" = "${OLDCOMMIT}" ; then
  exit 0
fi

echo "${COMMIT}" > "${MAINDIR}/${BRANCH}.weekly.commit"

SCOMMIT="$(git rev-parse --short HEAD)"

./autogen.sh --no-configure-run

mkdir -p docbuild
cd docbuild
../configure && make doc

rm -Rf "${MAINDIR}/nightly/weekly/${BRANCH}/doxygen/html" \
       "${MAINDIR}/nightly/weekly/${BRANCH}/doxygen.7z"

mv doc/doxygen/html "${MAINDIR}/nightly/weekly/${BRANCH}/doxygen/"

if ! cd "${MAINDIR}/nightly/weekly/${BRANCH}/" ; then
  echo "Failed to enter \"${MAINDIR}/nightly/weekly/${BRANCH}\"!" >&2
  exit 1
fi
7z a -r doxygen.7z doxygen

cd "${MAINDIR}"

if test -x ./upload.sh ; then
  ./upload.sh
fi

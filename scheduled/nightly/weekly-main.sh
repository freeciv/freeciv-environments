#!/bin/bash

BRANCH=main
MAINDIR="$(cd $(dirname "$0") ; pwd)"

cd "${MAINDIR}"

OLDCOMMIT="$(cat "${BRANCH}.weekly.commit")"

if ! cd "${MAINDIR}/${BRANCH}" ; then
  echo "Failed to enter \"${MAINDIR}/${BRANCH}\"!" >&2
  exit 1
fi

rm -Rf docbuild

git checkout translations
git checkout ChangeLog
git pull
COMMIT="$(git rev-parse HEAD)"

if test "${COMMIT}" = "${OLDCOMMIT}" ; then
  exit 0
fi

echo "${COMMIT}" > "${MAINDIR}/${BRANCH}.weekly.commit"

if ! mkdir -p docbuild ; then
  echo "Failed to create docbuild directory!" >&2
  exit 1
fi

cd docbuild

if ! ../scripts/generate_doc.sh .. ; then
  echo "Failed to generate documentation!" >&2
  exit 1
fi

rm -Rf "${MAINDIR}/nightly/weekly/${BRANCH}/doxygen/html" "${MAINDIR}/nightly/weekly/${BRANCH}/doxygen.7z"

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

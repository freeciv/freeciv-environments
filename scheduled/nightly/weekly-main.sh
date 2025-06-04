#!/usr/bin/env bash

BRANCH=main
MAINDIR="$(cd $(dirname "$0") ; pwd)"

cd "${MAINDIR}"

OLDCOMMIT="$(cat "${BRANCH}.weekly.commit")"

rm -Rf "wbuild/${BRANCH}"

if ! cd "${MAINDIR}/${BRANCH}" ; then
  echo "Failed to enter \"${MAINDIR}/${BRANCH}\"!" >&2
  exit 1
fi

git checkout translations
git checkout ChangeLog
git pull
COMMIT="$(git rev-parse HEAD)"

if test "${COMMIT}" = "${OLDCOMMIT}" ; then
  exit 0
fi

echo "${COMMIT}" > "${MAINDIR}/${BRANCH}.weekly.commit"

if ! mkdir -p "${MAINDIR}/wbuild/${BRANCH}/doxygen" ; then
  echo "Failed to create \"${MAINDIR}/wbuild/${BRANCH}/doxygen\"!" >&2
  exit 1
fi

if ! cd "${MAINDIR}/wbuild/${BRANCH}/doxygen" ; then
  echo "Failed to enter \"${MAINDIR}/wbuild/${BRANCH}/doxygen\"!" >&2
  exit 1
fi

if ! "${MAINDIR}/${BRANCH}/scripts/generate_doc.sh" "${MAINDIR}/${BRANCH}"
then
  echo "Failed to generate documentation!" >&2
  exit 1
fi

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

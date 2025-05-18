#!/bin/bash

BRANCH=S3_2
KEEP_DAYS=4
MAINDIR="$(cd $(dirname $0) ; pwd)"

if ! test -x "$1/docker_run.sh" ; then
  echo "$1 not a crosser docker scripts directory" >&2
  exit 1
fi

DOCKDIR="$1"

cd "${MAINDIR}"

OLDCOMMIT="$(cat ${BRANCH}.commit)"

rm -Rf "nbuild/${BRANCH}"

if ! cd "${MAINDIR}/${BRANCH}" ; then
  echo "Failed to enter \"${MAINDIR}/${BRANCH}\"!" >&2
  exit 1
fi

rm -Rf tarbuild
rm -Rf windows/installer_cross/meson

git checkout translations
git checkout ChangeLog
if ! git pull ; then
  sleep 20
  # Retry
  git pull
fi
COMMIT="$(git rev-parse HEAD)"

if test "${COMMIT}" = "${OLDCOMMIT}" ; then
  exit 0
fi

if ! mkdir -p "${MAINDIR}/nbuild/${BRANCH}/flatpak" ; then
  echo "Failed to create \"${MAINDIR}/nbuild/${BRANCH}/flatpak\"!" >&2
  exit 1
fi

if ! mkdir -p "${MAINDIR}/nbuild/${BRANCH}/appimage" ; then
  echo "Failed to create \"${MAINDIR}/nbuild/${BRANCH}/appimage\"!" >&2
  exit 1
fi

echo "${COMMIT}" > "${MAINDIR}/${BRANCH}.commit"

SCOMMIT="$(git rev-parse --short HEAD)"

./autogen.sh --no-configure-run

./scripts/refresh_changelog.sh

if ! cd "${MAINDIR}/nbuild/${BRANCH}/flatpak" ; then
  echo "Failed to enter \"${MAINDIR}/nbuild/${BRANCH}/flatpak\"!" >&2
  exit 1
fi

"${MAINDIR}/${BRANCH}/platforms/flatpak/build_flatpak.sh"

ls -1 *.flatpak | (while read OFPF ; do NFPF=$(echo "${OFPF}" | sed "s/.flatpak/-${SCOMMIT}.flatpak/") ; mv "${OFPF}" "${NFPF}" ; done )

if ! cd "${MAINDIR}/nbuild/${BRANCH}/appimage" ; then
  echo "Failed to enter \"${MAINDIR}/nbuild/${BRANCH}/appimage\"!" >&2
  exit 1
fi

"${MAINDIR}/${BRANCH}/platforms/appimage/build_appimages.sh"

rm -f linuxdeploy-*.AppImage
ls -1 *.AppImage | (while read OFPF ; do NFPF=$(echo "${OFPF}" | sed "s/.AppImage/-${SCOMMIT}.AppImage/") ; mv "${OFPF}" "${NFPF}" ; done )

if ! cd "${MAINDIR}/${BRANCH}" ; then
  echo "Failed to enter \"${MAINDIR}/${BRANCH}\"!" >&2
  exit 1
fi

mkdir -p tarbuild
cd tarbuild
../configure && make dist
ODISTNAME=$(ls -1 *.tar.xz)
NDISTNAME=$(echo ${ODISTNAME} | sed "s/.tar.xz/-${SCOMMIT}.tar.xz/")
mv ${ODISTNAME} ${NDISTNAME}

if ! cd "${MAINDIR}/${BRANCH}/translations" ; then
  echo "Failed to enter \"${MAINDIR}/${BRANCH}/translations\"!" >&2
  exit 1
fi

./stats.sh > "${MAINDIR}/nightly/${BRANCH}/translations/stats.txt"

cd "$MAINDIR"
declare -i BNBR
if ! test -f ${BRANCH}.build ; then
  BNBR=1
else
  BNBR=$(cat ${BRANCH}.build)
  BNBR=${BNBR}+1
fi
echo -n ${BNBR} > ${BRANCH}.build

declare -i OLDBNBR
OLDBNBR=${BNBR}-${KEEP_DAYS}
if test -f ${BRANCH}.files ; then
    grep "^${OLDBNBR}: " ${BRANCH}.files | sed "s/${OLDBNBR}: //" | ( while read FILE ; do
        echo "Removing nightly/${BRANCH}/${FILE}"
        rm -f "nightly/${BRANCH}/${FILE}"
    done )

    grep -v "^${OLDBNBR}: " ${BRANCH}.files > ${BRANCH}.files.new
    mv ${BRANCH}.files.new ${BRANCH}.files
fi

echo "${BNBR}: tarballs/${NDISTNAME}" >> ${BRANCH}.files
cp ${BRANCH}/tarbuild/${NDISTNAME} nightly/${BRANCH}/tarballs/

ls -1 "nbuild/${BRANCH}/flatpak/"*.flatpak |
  sed "s,^nbuild/${BRANCH}/,${BNBR}: ," >> ${BRANCH}.files
mv "nbuild/${BRANCH}/flatpak/"*.flatpak "nightly/${BRANCH}/flatpak/"

ls -1 "nbuild/${BRANCH}/appimage/"*.AppImage |
  sed "s,^nbuild/${BRANCH}/,${BNBR}: ," >> ${BRANCH}.files
mv "nbuild/${BRANCH}/appimage/"*.AppImage "nightly/${BRANCH}/appimage/"

./crosser-nightly.sh "${DOCKDIR}" "${BRANCH}" "${BNBR}" "${SCOMMIT}"

if test -x ./upload.sh ; then
  ./upload.sh
fi

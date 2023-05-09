#!/bin/bash

BRANCH=main
KEEP_DAYS=5
MAINDIR="$(cd $(dirname $0) ; pwd)"

if ! test -x "$1/docker_run.sh" ; then
  echo "$1 not a crosser docker scripts directory" >&2
  exit 1
fi

DOCKDIR="$1"

cd "${MAINDIR}"

OLDCOMMIT="$(cat ${BRANCH}.commit)"

if ! cd "${MAINDIR}/${BRANCH}" ; then
  echo "Failed to enter \"${MAINDIR}/${BRANCH}\"!" >&2
  exit 1
fi

rm -Rf tarbuild
rm -Rf docbuild
rm -Rf windows/installer_cross/meson \
       windows/installer/cross/autotools \
       windows/installer_cross/Output \
       windows/installer_cross/meson-install \
       windows/installer_cross/meson-build-win64* \
       windows/installer_cross/*.nsi

git checkout translations
git checkout ChangeLog
git pull
COMMIT="$(git rev-parse HEAD)"

if test "${COMMIT}" = "${OLDCOMMIT}" ; then
  exit 0
fi

echo "${COMMIT}" > "${MAINDIR}/${BRANCH}.commit"

SCOMMIT="$(git rev-parse --short HEAD)"

./autogen.sh --no-configure-run

./scripts/refresh_changelog.sh

if ! cd "${MAINDIR}/${BRANCH}/platforms/flatpak" ; then
  echo "Failed to enter \"${MAINDIR}/${BRANCH}/platforms/flatpak\"!" >&2
  exit 1
fi

rm -Rf build repo
./build_flatpak.sh

ls -1 *.flatpak | (while read OFPF ; do NFPF=$(echo "${OFPF}" | sed "s/.flatpak/-${SCOMMIT}.flatpak/") ; mv "${OFPF}" "${NFPF}" ; done )

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

ls -1 ${BRANCH}/platforms/flatpak/*.flatpak |
  sed "s,^${BRANCH}/platforms/,${BNBR}: ," >> ${BRANCH}.files
mv ${BRANCH}/platforms/flatpak/*.flatpak nightly/${BRANCH}/flatpak/

./crosser-nightly.sh "${DOCKDIR}" "${BRANCH}" "${BNBR}" "${SCOMMIT}"

if test -x ./upload.sh ; then
  ./upload.sh
fi

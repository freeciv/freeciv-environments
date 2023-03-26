#!/bin/sh -i

. /build/crosser-ver.sh

cd /freeciv/windows/installer_cross/

if test -x ./meson-build_all_installers.sh ; then
  ./meson-build_all_installers.sh "/usr/crosser/${CROSSER_DIR}" release
else
  ./build_all_installers.sh "/usr/crosser/${CROSSER_DIR}" release
fi

#!/bin/sh -i

. /env/crosser-ver.sh

if test -d /build ; then
  cd /build

  /freeciv/platforms/windows/installer_cross/meson-build_all_installers.sh \
      "/usr/crosser/${CROSSER_DIR}" release
else
  if test -d /freeciv/platforms/windows/installer_cross ; then
    cd /freeciv/platforms/windows/installer_cross/
  else
    # Older versions
    cd /freeciv/windows/installer_cross/
  fi

  if test -x ./meson-build_all_installers.sh ; then
    ./meson-build_all_installers.sh "/usr/crosser/${CROSSER_DIR}" release
  else
    ./build_all_installers.sh "/usr/crosser/${CROSSER_DIR}" release
  fi
fi

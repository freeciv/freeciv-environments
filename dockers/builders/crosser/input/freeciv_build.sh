#!/bin/sh -i

. /env/crosser-ver.sh

export PATH="${PATH}:$(pwd)/bin"
if ! mkdir bin ||
   ! mkdir tolua ||
   ! cd tolua ||
   ! meson setup -Dserver=disabled -Dclients=[] -Dfcmp=[] -Dtools=[] -Daudio=none /freeciv ||
   ! ninja ||
   ! cp tolua ../bin/
then
  echo "Failed to build native tolua!" >&2
  exit 1
fi

if test -d /build ; then
  cd /build

  /freeciv/platforms/windows/installer_cross/meson-build_all_installers.sh \
      "/usr/crosser/${CROSSER_DIR}" release
else
  if test -d /freeciv/platforms/windows/installer_cross ; then
    cd /freeciv/platforms/windows/installer_cross/
  else
    # Freeciv < 3.3
    cd /freeciv/windows/installer_cross/
  fi

  ./meson-build_all_installers.sh "/usr/crosser/${CROSSER_DIR}" release
fi

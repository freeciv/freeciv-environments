#!/bin/bash

. ./input/crosser-ver.sh

if test "$1" = "" ; then
  SRCDIR="$(pwd)/src/main"
else
  SRCDIR="$(cd $1 || exit 1 ; pwd)"
fi

if ! test -x "${SRCDIR}/fc_version" ; then
  echo "${SRCDIR}/ is not a freeciv source tree" >&2
  exit 1
fi

docker run -i --mount type=bind,source="${SRCDIR}",target=/freeciv -e FCSHELL=y -t "fc-crosser-builder-${CROSSER_VER}"

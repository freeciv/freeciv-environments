#!/bin/bash

. ./input/crosser-ver.sh

if ! test -f "input/${CROSSER_PACKET}" ; then
  echo "You seem to be missing ${CROSSER_PACKET} from input/"
  echo "Should I download it for you (y/n)?"

  while test "$req_dl" != "n" && test "$req_dl" != "y"
  do
    echo -n "> "
    read -n 1 req_dl
    echo
    if test "$req_dl" != 'n' && test "$req_dl" != "y" ; then
      echo "Please answer 'y' or 'n'"
    fi
  done

  if test "$req_dl" != 'y' ; then
    echo "Cannot continue without ${CROSSER_PACKET}" 1>&2
    exit 1
  fi

  (
    cd input

    if ! wget "https://sourceforge.net/projects/crosser/files/crosser-${CROSSER_VER}/${CROSSER_PACKET}"
    then
      echo "Failed to download ${CROSSER_PACKET}" 1>&2
      exit 1
    fi
  )
fi

if test "$1" = "" ; then
  FREECIV_UID=$UID
else
  FREECIV_UID="$1"
fi

docker build --build-arg FREECIV_UID="${FREECIV_UID}" \
             --build-arg CROSSER_PACKET="${CROSSER_PACKET}" \
             -t "fc-crosser-builder-${CROSSER_VER}" . -f Dockerfile-crosser

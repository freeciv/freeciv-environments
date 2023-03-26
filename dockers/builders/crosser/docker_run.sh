#!/bin/bash

. ./input/crosser-ver.sh

if test "$1" = "" ; then
  SRCDIR="$(pwd)/src/main"
else
  SRCDIR="$(cd $1 || exit 1 ; pwd)"
fi

if ! test -x "${SRCDIR}/fc_version" ; then
  echo "${SRCDIR}/ is not a freeciv source tree" >&2

  if test "$1" = "" && ! test -d "${SRCDIR}" ; then
    echo "Should I clone freeciv main branch there (y/n)?"

    req_dl="unset"
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
      echo "Cannot continue without sources to build!" 1>&2
      exit 1
    fi

    if ! git clone https://github.com/freeciv/freeciv "${SRCDIR}" ; then
      echo "git clone failed!" 1>&2
      exit 1
    fi

    echo "Should I also set up workdirs for stable branches S3_0 ... S3_2 (y/n)?"

    req_wd="unset"
    while test "$req_wd" != "n" && test "$req_wd" != "y"
    do
      echo -n "> "
      read -n 1 req_wd
      echo
      if test "$req_wd" != 'n' && test "$req_wd" != "y" ; then
        echo "Please answer 'y' or 'n'"
      fi
    done

    if test "$req_wd" = "y" ; then
      if test -d "${SRCDIR}/../S3_2" ||
         test -d "${SRCDIR}/../S3_1" ||
         test -d "${SRCDIR}/../S3_0" ; then
        echo "Directory by the name of a potential git worktree already exist!" >&2
        exit 1
      fi
      ( cd "${SRCDIR}" || exit 1
        if ! git worktree add ../S3_2 S3_2 ||
           ! git worktree add ../S3_1 S3_1 ||
           ! git worktree add ../S3_0 S3_0
        then
          echo "Setting up git worktrees failed!" >&2
          exit 1
        fi
      )
    fi
  else
    exit 1
  fi
fi

docker run --mount type=bind,source="${SRCDIR}",target=/freeciv -t "fc-crosser-builder-${CROSSER_VER}"

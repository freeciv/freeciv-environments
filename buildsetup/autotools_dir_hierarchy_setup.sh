#!/bin/bash

# Setup base src/build directory hierarchy to be used with autotools.
# - Does not create individual build directories, as we don't
#   know which configurations user wants

export STABLE_BRANCHES="S3_3 S3_2 S3_1"
export REPO_URL="https://github.com/freeciv/freeciv"

prepare_branch_dir()
{
  echo "Preparing $1"
  (
  cd "$1" || return 1

  if ! mkdir builds ; then
    echo "Failed to create toplevel directory for $1 builds" >&2
    return 1
  fi

  cd src || return 1
  if ! ./autogen.sh --no-configure-run ; then
    echo "Autogen.sh for $1 failed" >&2
    return 1
  fi
  )
}

make_build_dir()
{
  (
    if ! mkdir -p "$1/builds/$2" ; then
      echo "Failed to create build dir \"$1/builds/$2\"" >&2
      return 1
    fi

    cd "$1/builds/$2" || exit 1

    ../../src/configure $3
  )
}

if test "$1" = "" || test -e "$1" ; then
  echo "Give name of the root directory to create as parameter." >&2
  echo "It must not exist prior running this script." >&2
  exit 1
fi

ROOTDIR="$1"

MAINDIR="$(cd $(dirname "$0") || exit 1 ; pwd)"

if ! mkdir -p "$ROOTDIR/main" ; then
  echo "Can't create \"$ROOTDIR/main\"" >&2
  exit 1
fi

# Make path absolute
ROOTDIR="$(cd "$ROOTDIR" || exit 1 ; pwd)"

if ! cd "$ROOTDIR" ; then
  echo "Failed to 'cd' to \"$ROOTDIR\"" >&2
  exit 1
fi

(
  cd main || exit 1
  if ! git clone "$REPO_URL" src ; then
    echo "Failed to clone freeciv git" >&2
    exit 1
  fi
)

(
  cd main/src || exit 1
  for BRANCH in $STABLE_BRANCHES
  do
    if ! git worktree add "../../$BRANCH/src" "$BRANCH" ; then
      exit 1
    fi
  done
)

for BRANCH in main $STABLE_BRANCHES
do
  if ! prepare_branch_dir "$BRANCH" ; then
    exit 1
  fi
done

make_build_dir main dev "--enable-debug --enable-ack-legacy --enable-client=gtk3.22,gtk4,qt,sdl2,stub --enable-fcmp=gtk3,gtk4,qt,cli --enable-fcdb=sqlite3,mysql,postgres,odbc --enable-ai-static=classic,tex,stub"

make_build_dir S3_3 dev "--enable-debug --enable-ack-legacy --enable-client=gtk3.22,gtk4,qt,sdl2,stub --enable-fcmp=gtk3,gtk4,qt,cli --enable-fcdb=sqlite3,mysql,postgres,odbc --enable-ai-static=classic,tex,stub"

make_build_dir S3_2 dev "--enable-debug --enable-client=gtk3.22,gtk4,qt,sdl2,stub --enable-fcmp=gtk3,gtk4,qt,cli --enable-fcdb=sqlite3,mysql,postgres,odbc --enable-ai-static=classic,tex,stub"

make_build_dir S3_1 dev "--enable-debug --enable-client=gtk3.22,gtk4,gtk3,qt,sdl2,stub --enable-fcmp=gtk3,gtk4,qt,cli --enable-fcdb=sqlite3,mysql,postgres,odbc --enable-ai-static=classic,tex,stub"

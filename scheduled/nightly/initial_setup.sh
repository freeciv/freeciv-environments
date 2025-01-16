#!/bin/bash

export STABLE_BRANCHES="S3_3 S3_2 S3_1"
export REPO_URL="https://github.com/freeciv/freeciv"

MAINDIR="$(cd $(dirname "$0") || exit 1 ; pwd)"

for BRANCH in main $STABLE_BRANCHES
do
  if ! mkdir -p "nightly/${BRANCH}/crosser/portable" ||
     ! mkdir -p "nightly/${BRANCH}/flatpak"          ||
     ! mkdir -p "nightly/${BRANCH}/appimage"         ||
     ! mkdir -p "nightly/${BRANCH}/tarballs"         ||
     ! mkdir -p "nightly/${BRANCH}/translations"
  then
    exit 1
  fi
done

if ! git clone "$REPO_URL" main ; then
  echo "Failed to clone freeciv git" >&2
  exit 1
fi

(
  cd main || exit 1
  for BRANCH in $STABLE_BRANCHES
  do
    if ! git worktree add "../$BRANCH" "$BRANCH" ; then
      exit 1
    fi
  done
)

echo
echo "Now, setup e.g. cron to run nightly-*.sh and weekly-*.sh scripts."
echo "You may also want to create ./upload.sh hook to upload"
echo "produced contents of nightly/"

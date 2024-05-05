#!/bin/sh -i

if test "$FCSHELL" = "y" ; then
  /bin/bash
else
  su - $(cat /build/username.txt) /build/freeciv_build.sh
fi

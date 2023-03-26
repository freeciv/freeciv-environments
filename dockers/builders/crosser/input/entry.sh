#!/bin/sh -i

if test "$FCSHELL" = "y" ; then
  /bin/bash
else
  su - freeciv /build/freeciv_build.sh
fi

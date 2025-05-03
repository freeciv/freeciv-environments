#!/bin/sh -i

if test "${FCSHELL}" = "y" ; then
  /bin/bash
else
  su - $(cat /env/username.txt) /env/freeciv_build.sh
fi

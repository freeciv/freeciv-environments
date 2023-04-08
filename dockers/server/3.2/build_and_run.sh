#!/bin/bash

if ! test -f src/common/game.c ; then
  echo "There's no directory src/ with freeciv sources" >&2
  exit 1
fi

if ! test -f "modpacks.txt" ; then
  echo "There was not modpacks.txt listing modpacks to install" >&2
  echo "Creating empty one" >&2
  # Create modpacks.txt with one empty line
  echo > modpacks.txt
fi

if docker build -t freeciv-3.2 . -f Dockerfile-server-3.2
then
  docker run -i -p 5556:5556 freeciv-3.2
fi

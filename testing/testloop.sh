#!/bin/bash

stdout_log()
{
  echo $(date +"%H:%M:%S") : $1
}

if test "$1" = "-h" || test "$1" = "--help"
then
  echo "Usage: $(basename $0) [logfile=autotest.log] [port=5431] [srv cmd=\"./fcser\"]"
  echo "  Game descriptions from stdin: <script> <loop count>"
  exit
fi

if [ "$1" != "" ] ; then
  LOGFILE="$1"
else
  LOGFILE="autotest.log"
fi

if [ "$2" != "" ] ; then
  PORT="$2"
else
  PORT="5431"
fi

if [ "$3" = "" ] ; then
  SRV_CMD="./fcser"
else
  # e.g. "./run.sh freeciv-server" on meson based build
  SRV_CMD="$3"
fi

declare -i TOTAL_GAMES_PLAYED=0
declare -i GAMES_PLAYED

ulimit -c 50000

while read RC GAMES_TO_PLAY
do
  if [ "$RC" != "#" ] ; then
    if [ "$GAMES_TO_PLAY" != "" ] ; then
      GAMES_PLAYED=0
      if [ $GAMES_TO_PLAY -eq 0 ] ; then
        GAMES_TO_PLAY=100000
      fi
      while [ $GAMES_PLAYED -lt $GAMES_TO_PLAY ]
      do
        stdout_log "Running $RC"
        nice $SRV_CMD -d warn -l $LOGFILE -r $RC -p $PORT -e -w > /dev/null
        GAMES_PLAYED=$GAMES_PLAYED+1
        TOTAL_GAMES_PLAYED=$TOTAL_GAMES_PLAYED+1
        stdout_log "Game $GAMES_PLAYED/$GAMES_TO_PLAY with $RC finished."
        stdout_log "Total $TOTAL_GAMES_PLAYED games finished."
      done
    else
      stdout_log "No number of games given for $RC."
    fi
  fi
done

#!/usr/bin/bash

Help () {

	echo " Usage : $0 -n=Number_of_runs [-img=Number] [-server=/my/best/freeciv-server] [paramfile1 paramfile2 ...]"
	echo "\n  will run random_tests.sh -n=... times (default 10), see there for more help about other options"
	exit 1
}

if [ "$#" == 0 ]; then 
	Help
fi

INCLUDES=""
IMG=10
RUN=1
SERVER=freeciv-server

while [ "$#" -gt 0 ]; do
	case "$1" in
	-h*|--h*)
		Help
		exit 0
	;;
	-n=*)
		N="${1#*=}"
		shift 1
	;;
	-img=*)
		IMG="${1#*=}"
		shift 1
	;;
	-server=*)
		SERVER="${1#*=}"
		shift 1
		if [ -f $(which $SERVER) ]; then
			d=$(cd $(dirname $(which $SERVER)) && pwd) 
			SERVER="$d/$(basename $SERVER)"
		fi
	;;
	-*)
		echo "unknown option: $1" >&2
		exit 1
	;;

	*)
		if [ -f $1 ]; then
			#ls -l $1
			#will be called from a child directory so ...
			d=$(cd $(dirname $1) && pwd)
			INCLUDES="$INCLUDES $d/$(basename $1)"
			shift 1
		else 
			echo "$1 file not found" >&2
			exit 1
		fi
	;;
	esac
done


DATE="$(date +%y%m%d-%H%M%S)"
LOOPDIR="loop.$DATE"

mkdir -p $LOOPDIR

OLDPWD=$( pwd )
cd $LOOPDIR
	for (( i=1; i<=$N; i++ )); do
		../random_tests.sh -run=$RUN -img=$IMG -server=$SERVER $INCLUDES
	done
cd $OLDPWD
mv $LOOPDIR $LOOPDIR.done

### search for error messages in server's log
cat $LOOPDIR*/*/serv.log | grep "^1" |cut -d " " -f6- |grep -v -i Please | sort | uniq -c |sort -nr > servlog.1.counted

### search overflow in console log 
#  and suppress server prompt at the beginning of the line "> "
cat $LOOPDIR*/*/console.log | grep -e overflow -e saved |grep -B 1 overflow |  sed -e 's/^> //' >overflow.all.$DATE
cat overflow.all.$DATE | grep overflow | cut -d: -f-5 | sort | uniq -c > overflow.counted.$DATE
cat overflow.counted.$DATE | cut -c9- | cut -d: -f-5 | sort -u > overflow.list.$DATE
## find one saved game for each type
for overf in $(cat overflow.list.$DATE | cut -d " " -f1) ; do
	cat overflow.all.$DATE| fgrep -e saved -e $overf | fgrep -m 1 -B1 "$overf" 
done >overflow.onegame_each.$DATE



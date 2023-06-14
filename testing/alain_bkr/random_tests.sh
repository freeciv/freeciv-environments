#!/usr/bin/bash

Help () {
echo "
  Without arguments, this script will 
	- generate a .serv file with random parameters 
	- create a directory, copy the script and run it (no human, only AI)
	- if convert (ImageMagick) is installed, will convert .ppm to .png,
		 and make an animated gif with maps

  It tries many settings, not all, and not all possibilities, values may be extreme

  Usage : $0 [-option1=val1] [file1] [file2] ...

  options : 
    -h* | --h* : help = print the current message

    -img=N
	if N > 0, will generate mapimages each N turns  (default 10)
	if N == 0, do not generate map images

    -run=N
	if N != 0, do run the server script inside a created dir (default) 
	if N == 0, do not run freeciv-serv

    -server=My/Favourite/Server  (default freeciv-server)

  args :
	file1 file2 ...
	Other arguments on the command line will be considered as filenames that we will include
	in our generated file, after all random parameters
	Order of files is important when they contain the same parameters, the last will overwrite the previous
	The files must be 'clean' :
		# comment lines are allowed 
		'set parameter value' alone on a line, with NO leading spaces, no double spaces, no comment after.

  example :
	$0 -img=0 -server=/Big/clang/FC31/bin/freeciv-server small.srv tenturns.srv slowspace.srv
   
"
}

INCLUDES=""
IMG=10
RUN=1
SERVER=freeciv-server
err=0

while [ "$#" -gt 0 ]; do
	case "$1" in
	-h*|--h*)
		Help
		exit 0
	;;
	-img=*)
		IMG="${1#*=}"
		shift 1
	;;
	-run=*)
		RUN="${1#*=}"
		shift 1
	;;
	-server=*)
		SERVER="${1#*=}"
		shift 1
	;;
	-*)
		echo "unknown option: $1" >&2
		# exit 1
		err=$(( $err + 1 ))
		shift 1
	;;

	*)
		if [ -f $1 ]; then
			#ls -l $1
			INCLUDES="$INCLUDES $1"
			shift 1
		else 
			echo "$1 file not found" >&2
			#exit 1
			err=$(( $err + 1 ))
			shift 1
		fi
	;;
	esac
done

MESS=" will do : $0 -img=$IMG -run=$RUN -server=$SERVER $INCLUDES"


#####################################################


# print the number as a string with a given number of leading zeros : lzf 3 7 gives 007
leading_zero_fill ()
{
    printf "%0$1d\\n" "$2"
}

# Write to our file. must be used after having defined $name
Serv () {
echo $@ >>$name
}

# get one (-n 1) random integer (-i) in the range defined by $1  (like 1-10)
R () {
shuf -n 1 -i $1
}

enable=(
'DISABLED'
'ENABLED'
)

#####################################################
# Our generated filename uses size, aifill and landmass
#  so parse the INCLUDES once to get the values
 
size=$(cat $INCLUDES | grep -i '^set size'|tail -1 |awk '{ print $NF }')

if [ ! $size ]; then
	size=$(R 1-7)
	size=$(( $size * $size ))
fi
[[ $size -ge 10 ]] && size="$( leading_zero_fill 2 $size )"
[[ $size -ge 100 ]] && size="$( leading_zero_fill 3 $size )"
[[ $size -ge 1000 ]] && size="$( leading_zero_fill 4 $size )"

# number of AI, will be used later for loop on AI
aif=$(cat $INCLUDES | grep -i '^set aifill'|tail -1 |awk '{ print $NF }')
if [ ! $aif ]; then
	typeset -i aif=$(( $(R 1-10) + $(R 1-$size) ))
fi
[ $aif -gt 150 ] && aif=150
# string with leading 0
aifill="$aif"
aifill="$( leading_zero_fill 3 $aifill )"

# landmass
land=$(cat $INCLUDES | grep -i '^set landmass'|tail -1 |awk '{ print $NF }')
if [ ! $land ]; then
	land=$(R 15-85)
fi

# ugly but simple : one name to rule them all : directory, .srv , saves, score ...
#  /!\ our name lenght must be <36 char, because fc will append -T01234-%Reason, and max is 46char , otherwise it will fallback to freeciv-...
now=$(date +%y%m%d-%H%M%S)
DIR="Sz${size}-Ai${aifill}-Lm${land}-$now"	# 30 char

mkdir -p $DIR

# self copy in DIR
cp -a $0 $DIR/

####################################################
# the name of our generated file	=> we can begin to fill our .srv file with Serv function
name="${DIR}/$DIR.serv"

# comment with the current scripts and args
Serv "# $MESS"

# append turns on 5 digit (no gameyear) , in case of long game (>9999 turns), and later video made from mapimg
Serv "set savename ${DIR}-T%05T-%R"

cat >>$name <<EOF

# uses default ruleset  (ie civciv3 at present time)
# see rulesetdir options ,  classic | civ 2 | civ2civ3 | experimental | alien ...

# save
set threaded_save disabled
set autosave TURN|GAMEOVER|QUITIDLE|INTERRUPT
set saveturns 1

set scorelog  enabled
set scorefile $DIR.score

# Nationset all is needed for test with >50 nations , color per team is just easier to see
#  probably better to set it before setting aifill :-)
set nationset all
set cityname GLOBAL_UNIQUE 
set plrcolormode TEAM_ORDER

# 3 settlers, 3 strong Defenders , 3 workers , 1 explorer, 1 diplomat
set startunit cccDDDwwwxs
set startpos VARIABLE

# game 
set mapsize FULLSIZE
set topology WRAPX|ISO|HEX

# 1000% time, to have enought time to see what happens 
set spaceship_travel_time 1000

EOF

Serv "##### MAP #####"

Serv "set gameseed $( R 1-2147483647)"
Serv "set mapseed $( R 1-2147483647)"

Serv "set landmass $land"

Serv "set size $size"

gen=(
'RANDOM'
'FRACTAL'
'ISLAND'
'FRACTURE'
'FAIR'
)
#  no more FAIR, may cause problem with generator wrt other parameters
#    see https://osdn.net/projects/freeciv/ticket/47580 for a patch (2023 march)
# g=$(R 0-3)
g=$(R 0-4)
Serv "set generator ${gen[$g]}"

# be wild
Serv "set temperature $(( $(R 0-5) * 20 ))"
Serv "set wetness $(( $(R 0-5) * 20 ))"

Serv "set citymindist $(R 1-11)"

Serv "set globalwarming enabled"
# res is either in 1..100 or in  100 * 1..100
i=$(R 0-1)
j=$(R 1-100)
res=$(( $i * $j + $(( 1 - $i )) * 100 * $j ))
Serv "set globalwarming_percent $res"

Serv "set nuclearwinter enabled"
# res is either in 1..100 or in  100 * 1..100
i=$(R 0-1)
j=$(R 1-100)
res=$(( $i * $j + $(( 1 - $i )) * 100 * $j ))
Serv "set nuclearwinter_percent $res"

i=$(R 0-1)
Serv "set alltemperate	${enable[$i]}"

Serv "set flatpoles $(R 0-100)"

i=$(R 0-1)
Serv "set separatepoles	${enable[$i]}"
i=$(R 0-1)
Serv "set singlepole 	${enable[$i]}"

Serv "set steepness  $(R 0-60)"

#
tp=(
'DISABLED'
'CLOSEST'
'CONTINENT'
)
t=$(R 0-2)
Serv "set teamplacement ${tp[$t]}"

Serv "set dispersion $(R 0-10)"


Serv "##### game #####"
Serv "set endturn $(R 2000-5000)"

# Tech and gold accordingly
tech=(
0
3
6
12
24
48
96
)
t=${tech[ $(R 0-6) ]}
# We randomize a little bit more, mostly for higher number of tech
if [ "$t" != "0" ]; then
	m=$(( ($t - 3) / 2 ))
	t=$(R ${m}-${t})
fi
Serv "set techlevel $t"

# average gold =  50 + 50 per tech 
typeset -i g=$((  $(R 0-100) + $(R 0-$(( $t * 100 )) ) ))
[ $g -gt 10000 ] && g=10000
Serv "set gold $g"

vic=(
'set victories SPACERACE'
'set victories ALLIED'
'set victories CULTURE'
'set victories ALLIED|SPACERACE'
'set victories ALLIED|CULTURE'
'set victories CULTURE|SPACERACE'
'set victories CULTURE|SPACERACE|ALLIED'
)
v=$(R 0-6)
Serv "${vic[$v]}"

hap=(
'DISABLED'
'NATIONAL'
'ALLIED'
)
h=$(R 0-2)
Serv "set happyborders ${hap[$h]}"

list=(
'DISABLED'
'NORMAL'
'FREQUENT'
'HORDES'
)
l=$(R 0-3)
Serv "set barbarians ${list[$l]}"

Serv "set onsetbarbs $(R 0-120)"

list=(
25
50
100
200
400
)
l=$(R 0-4)
Serv "set sciencebox ${list[$l]}"

#  phasemode	(ALL) PLAYER TEAM	! to be tested
list=(
ALL
PLAYER
TEAM
)
l=$(R 0-2)
Serv "set phasemode ${list[$l]}"


Serv "##### migration #####" 
Serv "# migration		-  Whether to enable citizen migration"
l=$(R 0-1)
Serv "set migration ${enable[$l]}"

if [ "$l" == "1" ]; then
	Serv "# mgr_turninterval	- How often citizens try to migrate."
	l=$(R 2-7)
	l=$(( $l * $l ))
	Serv "set mgr_turninterval $l"
	
	Serv "# mgr_foodneeded	- Whether destination food is checked."
	l=$(R 0-1)
	Serv "set mgr_foodneeded ${enable[$l]}"
	
	Serv "# mgr_distance		- How far citizens will migrate."
	Serv "set mgr_distance $(( $(R 0-11) - 5 ))"
	
	Serv "# mgr_worldchance 	- Chance for inter-nation migration."
	l=$(R 0-6)
	l=$(( $l * $l ))
	Serv "set mgr_worldchance $l"
	
	Serv "# mgr_nationchance	- Chance for intra-nation migration."
	l=$(R 0-10)
	l=$(( $l * $l ))
	Serv "set mgr_nationchance $l"
fi
	
Serv "##### military #####"
Serv "set occupychance $((  $(R 0-4) * 25 ))"

l=$(R 0-1)
Serv "set restrictinfra ${enable[$l]}"

l=$(R 0-1)
Serv "set unreachableprotects ${enable[$l]}"

Serv "set razechance $(( $(R 0-3) * 10 ))"

l=$(R 0-1)
Serv "set killstack ${enable[$l]}"

 
Serv "##### AI #####" 

# traitdistribution (FIXED) EVEN
distr=(
'EVEN'
'FIXED'
)
l=$(R 0-1)
Serv "set traitdistribution ${distr[$l]}"

Serv "# let s have some fun : give some random AI level, and create random teams , this will be unfair" 
Serv "set aifill $aifill" 

# stronger first, to bias toward stronger AI (random pick = team %6 , so for example in case of 9, cheating have more chance (2/9) than novice (1/9) )
ait=(
'cheating'
'experimental'
'hard'
'normal'
'easy'
'novice'
)
# Team 1 display with Uppercase  = team 0 in lower case   (but team AI*500 500 works, so .... need to fix this off-by-one stuff in the DISPLAY)
Serv "# Be sure to have at least 2 teams, AI*1 is alone in its own team."

j=$(R 0-5)
Serv "${ait[$j]} AI*1" 
Serv "team AI*1 1"

coherent=$(R 0-1)
if [ $aif -le 6  ]; then
	# be random if number of AI is less than size of the list of aitrait.
	coherent=0
else
	# 50% chance to be coherent in a team, 50% to be full random
	coherent=$(R 0-1)
fi

for (( i=2; i<=$aif; i++ )); do
	Serv 

	t=$(R 2-$aif)
	Serv "team AI*$i $t"

	if [ "$coherent" == "0" ]; then
		Serv "# FULL random teams, with random ailevel for each nation"
		j=$(R 0-5)
	else
		Serv "# COHERENT team, AIlevel = TeamNumber modulo 6"
		#  ( teams 2 8 14 are hard, 3 9 15 normal .... )
		j=$(( $t % 6 ))
	fi
	Serv "${ait[$j]} AI*$i" 
done

for f in $INCLUDES; do
	Serv "##########################"
	Serv "# include file $f"
	cat $f >>$name
done 

##########################  Finish the .serv file with autogames additions , and if desired map image generation ########


cat >>$name <<EOF

##################################################
# no human needed
set minplayers 0

# server only autogame
set timeout -1

# The doc says to set this for autogames
set ec_turns 0
set ec_chat disabled

save

start

EOF

# image can be done only after mapgeneration 
if [ "$IMG" != "0" ]; then
	# terrain cities units borders, for all players, each 10 turns
	Serv "mapimg define 'zoom=1:map=tcub:show=all:turns=$IMG:format=ppm|ppm'"
	Serv "##########################"
fi


ls -l $name
echo " $name has been created"


# freeciv-server [option ...]
#  -h, --help            Print a summary of the options
#  -l, --log FILE        Use FILE as logfile
#  -p, --port PORT       Listen for clients on port PORT	#  on linux 32768-60000 are open port, just pick one randomly 
#  -r, --read FILE       Read startup script FILE		{  <---- the parameters file we are creating here

if [ "$RUN" != "0" ]; then
	#SERVER="freeciv-server"
	#SERVER="/Big/clang/FC31/bin/FC31clang-server"

	cd $DIR
	LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 $SERVER -p $(R 32769-59999 ) -l serv.log -r ${DIR}.serv 2>&1 |tee  console.log

	# game is finished, quick search for error messages
	cat console.log |grep -e runtime -e "^1" -e saved |grep -B1 -e runtime -e "^1" > game.error
	cat serv.log | grep "^1" > serv.log.error

	if [ "$IMG" != "0" ] && [ $(which convert) ]; then
		# save space, convert 1MB Sz05-Ai031-Lm27-20230330-172315-T01234-M-bc--tuZ1Pall.map.ppm to several kB T01234.png
		for f in $(ls Sz*.ppm) ; do
			nam=$( echo $f |cut -d- -f6)
			convert $f $nam.png && rm $f
		done
		# make an animated gif	# display with  ` animate xyz.gif `
		convert -delay 10 -loop 0 *.png $(echo $f |cut -d- -f-5).gif
	fi

	cd ..
	mv $DIR $DIR.done
fi

#####################################################
# ? todo ?
#	techlossforgiveness  -1 200
#	conquercost	0 100
#	diplbulbcost	0 100
#
#	set startpos VARIABLE|DEFAULT	(i dont like others)
#
#	borders  (ENABLED) DISABLED SEE_INSIDE EXPAND	# maybe useless for AI, but can test
#
#	contactturns 0 100
#
#	disasters                 +~ 10 (0, 1000)
#
#	diplchance # poison is not aggressive !
#
#	diplomacy ALL: AI: TEAM: DISABLED: NOMIXED:
#
#	multiresearch   xor techpenalty 
#	team_pooled_research (enabled) disabled
#	techleak   0 (100) 300
#
#	revealmap  "" DEAD START
#
#	other kind of mapsize ,  XSIZE, PLAYER ...
#
# ??? todo ??? other rulesets , everything would be the best :-)
#####################################################



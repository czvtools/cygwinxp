#!/bin/bash

# 		Download Cygwin packages compatible with Windows XP
#         ===================================================
#
#    Created based on information from the FruitBat.org:
#               http://www.fruitbat.org/Cygwin/timemachine.html
#    Setup files will be downloaded into current directory.
#	Repo structure will be created into "./CygwinXP" directory.
#    Once downloaded use the setup to install from local repository.
#
#                                            czvtools @ 2016
#

alias wget="wget --timeout=5" 	# a shorter timeout is desired

# Download the official mirrors list and the known compatible setup file
( mkdir -p ./CygwinXP && cd ./CygwinXP && { [[ -s ./mirrors.lst ]] || wget https://cygwin.com/mirrors.lst; } )
# 32bit version
[[ -s setup-x86-2.874.exe ]] || wget ftp://www.fruitbat.org/pub/cygwin/setup/snapshots/setup-x86-2.874.exe
mkdir -p ./CygwinXP/cygwinxp.local/x86
( 	cd ./CygwinXP/cygwinxp.local/x86 \
	&& [[ -s setup.ini ]] || { wget ftp://www.fruitbat.org/pub/cygwin/circa/2016/08/30/104223/x86/setup.bz2 \
	&& bunzip2 setup.bz2 && mv setup setup.ini; } )
# 64 bit version
[[ -s setup-x86_64-2.874.exe ]] || wget ftp://www.fruitbat.org/pub/cygwin/setup/snapshots/setup-x86_64-2.874.exe
mkdir -p ./CygwinXP/cygwinxp.local/x86_64
( 	cd ./CygwinXP/cygwinxp.local/x86_64 \
	&& [[ -s setup.ini ]] || { wget ftp://www.fruitbat.org/pub/cygwin/circa/64bit/2016/08/30/104235/x86_64/setup.bz2 \
	&& bunzip2 setup.bz2 && mv setup setup.ini; } )

# Mirrors will be used to retrieve packages in paralel wihtout loading only a single site
typeset -A MIRRORS 
typeset -i M=0
while IFS=";" read U a; do
	MIRRORS[$M]="$U"
	((M=M+1))
done < ./CygwinXP/mirrors.lst

# retrieve one package from the first random valid place (last 3 are best candidates that we don't want to stress)
get_one () {
	# Attempt from multiple servers because most of the content doesn't change so often
	wget "${MIRRORS[$((RANDOM%M))]}$1" \
		|| wget "${MIRRORS[$((RANDOM%M))]}$1" \
		|| wget "${MIRRORS[$((RANDOM%M))]}$1" \
		|| wget "${MIRRORS[$((RANDOM%M))]}$1" \
		|| wget "${MIRRORS[$((RANDOM%M))]}$1" \
		|| wget "http://ftp.cc.uoc.gr/mirrors/cygwin/$1" \
		|| wget "http://cygwin.mirror.constant.com/$1" \
		|| wget "ftp://www.fruitbat.org/pub/cygwin/circa/2016/08/30/104223/$F" \
	&& mkdir -p ../${F%/*} && mv ${F##*/} ../${F%/*}
}

# Retrieve just the "32bit" version... replace "x86" with "x86_64" for the 64 bit
cd ./CygwinXP/cygwinxp.local/x86

# extract from setup.ini the packages to download (only latest version) including sources
COUNT=0   # used to give an idea about the progress
for F in $(grep -E "^@|^install:|^source" setup.ini | grep -A2 '^@' | grep -E "^install:|^Asource:" | awk '{print $2}'); do
	((COUNT=COUNT+1))
	if [[ -f ../$F ]]; then
		continue  # skip packages that are already present
	elif [[ $COUNT -lt 1 ]]; then
	     continue  # skip a certain number of packages... should be customized
	else
		echo "===== $COUNT : $F" # download packages in background...
		get_one "$F" >/dev/null 2>&1 &
	fi
	while [[ $(jobs | wc -l) -gt 3 ]]; do sleep 1 ; done   #... 3 at the same time.
done

# check which packages we have with incorrect size... should be deleted and re-downloaded on next run
COUNT=0
grep -E "^@|^install:|^source" setup.ini | grep -A2 '^@' | grep -E "^install:|^Asource:" | awk '{print $2, $3}' > file.tmp
exec 5<file.tmp
while read F S <&5; do
	((COUNT=COUNT+1))
	# using this was "ls" make it slow, but it works
	[[ $(ls -l ../$F | awk '{print $5}') -eq $S ]] || { echo "$COUNT: $F $S"; rm -f "../$F"; }
done
exec 5<&-
rm -f file.tmp

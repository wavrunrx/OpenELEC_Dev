#!/usr/bin/env bash
set -e

# "OpenELEC_DEV" ; An automated development build updater script for OpenELEC
#
# Copyright (c) February 2012, Eric Bixler
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#	* Redistributions of source code must retain the above copyright
#	  notice, this list of conditions and the following disclaimer.
#	* Redistributions in binary form must reproduce the above copyright
#	  notice, this list of conditions and the following disclaimer in the
#	  documentation and/or other materials provided with the distribution.
#	* Neither the name of the <organization> nor the
#	  names of its contributors may be used to endorse or promote products
#	  derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY Eric Bixler ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL Eric Bixler BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


###### script version
VERSION="16"


###### if no options specified; we continue as normal

options_found="0"


###### restart scanning of argv, less 1; we want to see if there are more then one option characters passed.

OPTIND="1"


###### what branch do we use


if [ `cat /etc/arch | awk '{ print $1 }'` = "RPi.arm" ] ;
then
	mode="http://sources.openelec.tv/tmp/image/openelec-rpi"
else
	mode="http://sources.openelec.tv/tmp/image/openelec-frodo"
fi


###### set the temporary file location based on what device we are using...(the rPi does not have enough RAM to download the image to /dev/shm

arch=$(cat /etc/arch)
if [ "$arch" = "RPi.arm" ] ;
then
	temploc="/storage/downloads/xbmc-update"
else
	temploc="/dev/shm/xbmc-update"
fi


###### options

while getopts ":craospilqzvbh--:help" opt ;
do
	case $opt in

	c)
		options_found=1
		# quick check to see if we're up-to-date
		mkdir -p $temploc/
		arch=$(cat /etc/arch)
		curl -silent $mode/ | grep $arch | sed -e 's/<li><a href="//' -e 's/[^ ]* //' -e 's/<\/a><\/li>//' > $temploc/temp
		if [ $(wc -l $temploc/temp | cut -c -1) -gt "1" ] ;
		then
			cat $temploc/temp | tail -1 > $temploc/temp2
		else
			mv $temploc/temp $temploc/temp2
		fi
		PAST=$(cat /etc/version | tail -c 6 | tr -d 'r')
		PRESENT=$(cat $temploc/temp2 | tail -c 15 | cut -c 0-5)
		if [ `echo $PRESENT | sed 's/.\{4\}$//'` == "-" ] ;
		then
			# this is for coming from revisions 9999 and lower
			PRESENT=$(cat $temploc/temp2 | tail -c 15 | sed 's/.\{8\}$//' | tr -d "\-r"})
		else
			# this is for coming from revisions 10000 and higher
			PRESENT=$(cat $temploc/temp2 | tail -c 15 | sed 's/.\{8\}$//' | tr -d "r")
		fi
		if [ "$PRESENT" -gt "$PAST" ] ;
		then
			echo
			echo "Updates are Available"
			echo "Local:   $PAST"
			echo "Remote:  $PRESENT"
		else
			echo
			echo "No Updates Available"
		fi
		rm -rf $temploc/
		unset arch
		unset PAST
		unset PRESENT
		;;

	r)
		options_found=1
		# displays the remote build number
		mkdir -p $temploc/
		arch=$(cat /etc/arch)
		curl -silent $mode/ | grep $arch | sed -e 's/<li><a href="//' -e 's/[^ ]* //' -e 's/<\/a><\/li>//' > $temploc/temp
		if [ $(wc -l $temploc/temp | cut -c -1) -gt "1" ] ;
		then
			cat $temploc/temp | tail -1 > $temploc/temp2
		else
			mv $temploc/temp $temploc/temp2
		fi
		echo
		echo "Newest Remote Release for $arch: `cat $temploc/temp2 | tail -c 15 | sed 's/.\{8\}$//' | tr -d "\-r"`"
		rm -rf $temploc/
		unset arch
		;;
			
	a)
		options_found=1
		# show all remotely available builds for your architecture, and build date
		arch=$(cat /etc/arch)
		mkdir -p $temploc/
		curl -silent $mode/ | grep $arch | sed -e 's/<li><a href="//' -e 's/[^ ]* //' -e 's/<\/a><\/li>//' > $temploc/temp
		echo
		echo "Builds Available for your Architecture:  ($arch)"
		echo "---------------------------------------"
		list=$(cat $temploc/temp)
		if [[ -s $list ]] ;
        then
        	echo "There are no available builds for your architecture at this time."
        	echo "Please check again later."
        	echo
        	exit 1
        fi
		for i in $list
		do
		    echo -n "$i  --->  Compiled On: "; echo -n "$i" | cut -f 4-4 -d'-' | sed 's/......$//;s/./& /4' | sed 's/./& /7' | awk '{ print "[ "$2"/"$3"/"$1" ]" }'
		done
		rm -rf $temploc/
		unset arch
		unset list
		;;

	o)
		options_found=1
		# show all old archived builds for your architecture, as well as compilation date
		arch=$(cat /etc/arch)
		mkdir -p $temploc/
		curl -silent $mode/archive/ | grep $arch | sed -e 's/<li><a href="//' -e 's/[^ ]* //' -e 's/<\/a><\/li>//' > $temploc/temp
		echo
		echo "Archival Builds Avaliable for your Architecture:  ($arch)"
		echo "------------------------------------------------"
		list=$(cat $temploc/temp)
		for i in $list
		do
			echo -n "$i  --->  Compiled On: "; echo -n "$i" | cut -f 4-4 -d'-' | sed 's/......$//;s/./& /4' | sed 's/./& /7' | awk '{ print "[ "$2"/"$3"/"$1" ]" }'
		done
		if [[ ! -s $temploc/temp ]] ;
        then
        	echo "There are no archived builds for your architecture at this time."
        	echo
        fi
		rm -rf $temploc/
		unset arch
		unset list
		;;

	i)
		options_found=1
		# check to see if the appropriate files are in the right place, for a reboot
		SYS_KERN=$(ls /storage/.update/* 2> /dev/null | wc -l)
		if [ "$SYS_KERN" = "4" ] ;
		then
			echo
			echo "KERNEL & SYSTEM images are already in place."
			echo "Please reboot your HTPC when possible"
			echo "to complete the update."
			echo
			echo "Would you like to reboot now (y/n) ?"
			read -n1 -p "==| " reb
			echo
				if [[ "$reb" != "Y" ]] && [[ "$reb" != "y" ]] && [[ "$reb" != "N" ]] && [[ "$reb" != "n" ]] && [[ "$reb" != "yes" ]] && [[ "$reb" != "no" ]] && [[ "$reb" != "Yes" ]] && [[ "$reb" != "No" ]] ;
				then
					echo
					echo "Unrecognized Input."
					echo "Please answer (y/n)"
					echo "Exiting Now."
					echo
					unset reb
					exit 1
				elif [[ "$reb" = "Y" || "$reb" = "y" || "$reb" = "Yes" || "$reb" = "yes" ]] ;
				then
					sleep 1
					echo
					echo "Rebooting..."
					unset reb
					sync
					sleep 1
					/sbin/reboot
					exit 0
				elif [[ "$reb" = "N" || "$reb" = "n" || "$reb" = "No" || "$reb" = "no" ]] ;
				then
					sleep 1
					echo
					echo "Exiting Now."
					echo
					unset reb
					exit 0
				fi
		else
			echo
			echo "No KERNEL/SYSTEM images are in-place."
			fi
		;;

	s)
		options_found=1
		# checking for a script update, and notifying. no actual update going on here.
		rsvers=$(curl --silent https://raw.github.com/wavrunrx/OpenELEC_Dev/master/openelec-nightly_latest.sh | grep "VERSION=" | grep -v grep | sed 's/[^0-9]*//g')
		if [ "$rsvers" -gt "$VERSION" ] ;
		then
			echo
			echo "*---| Script Update Avaliable."
			echo "*---| Current Version: $VERSION"
			echo "*---| New Version: $rsvers"
			echo
			echo "*---| Re-Run -|Without Options|- to Update"
		else
			echo
			echo "No Script Updates Available at this Time."
			echo "Check Back Later."
		fi
		;;

	l)
		options_found=1
		# whats our current revision
		echo
		echo "My Local Build: `cat /etc/version | tail -c 6 | tr -d 'r'`"
		;;

	q)	
		options_found=1
		# supress output -- intentionally undocumented (needed only for GUI interaction)
		echo() { :; }
		options_found=0
		update_yes=1
		;;
		
	z)	
		options_found=1
		arch=$(cat /etc/arch)
		# roll back or forward to a version of our choosing
		echo
		echo "Are you sure you want to switch to an older/newer Build (y/n) ?"
		read -n1 -p "==| " old
			if [[ $old != "Y" ]] && [[ $old != "y" ]] && [[ $old != "N" ]] && [[ $old != "n" ]] && [[ $old != "yes" ]] && [[ $old != "no" ]] && [[ $old != "Yes" ]] && [[ $old != "No" ]] ;
			then
				echo
				echo
				echo "Unrecognized Input."
				sleep 2
				echo "Please answer (y/n)"
				echo "Exiting."
				echo
				exit 1
			elif [[ $old = "Y" || $old = "y" || $old = "Yes" || $old = "yes" ]] ;
			then
				echo
				echo
				echo -ne "Please Wait...\033[0K\r"
				arch=$(cat /etc/arch)
				mkdir -p $temploc/
				curl -silent $mode/ | grep $arch | sed -e 's/<li><a href="//' -e 's/[^ ]* //' -e 's/<\/a><\/li>//' > $temploc/temp
				curl -silent $mode/archive/ | grep $arch | sed -e 's/<li><a href="//' -e 's/[^ ]* //' -e 's/<\/a><\/li>//' >> $temploc/temp
				echo -ne "\033[0K\r"
				echo
				echo "Builds avaliable for your architecture: $arch"
				echo
				cat $temploc/temp | sort -n  | sed '$d' > $temploc/temp2
				echo "==================================="
				echo
				list=$(cat $temploc/temp2)
				if [[ ! -s $list ]] ;
        		then
        			echo "There are no available builds for your architecture at this time."
        			echo "Please check again later."
        			echo
        			echo "Exiting Now."
        			echo
        			unset list
        			exit 1
        		fi
				for i in $list
				do
					echo -n "Build: " ; echo -n "$i" | cut -f 5-5 -d'-' | sed '$s/........$//' | tr -d "r" ; echo -n "-----> Compiled On: " ; echo -n "$i" | cut -f 4-4 -d'-' | sed 's/......$//;s/./& /4' | sed 's/./& /7' | awk '{ print "[ "$2"/"$3"/"$1" ]" }' ; echo
				done
				echo "==================================="
				echo
				echo "Enter the Build/Revision number you want from the list above (Ex: "11327")"
				read -p "==| " fbrev
				if ! [[ "$fbrev" =~ ^[0-9]+$ ]] ; 
				then
					echo
					echo "Error: Not a valid Build"
					echo "Please choose a build from the list displayed above"
					rm -rf $temploc/
					exit 1
				fi
				fn=$(grep "$fbrev" $temploc/temp2 | awk '{print $1}')
				echo
				echo "Downloading..."
				echo -ne "Please Wait..\033[0K\r"
				fe=$(curl --silent $mode/$fn --head | head -n1 | wc -m)
				if [ "$fe" = "17" ] ;
				then
					wget -O $temploc/$fn $mode/$fn
				else
					wget -O $temploc/$fn $mode/archive/$fn
				fi
				echo -ne "\033[0K\r"
				extract="$temploc/$fn"
				echo
				echo "Extracting Files..."
				echo -ne "Please Wait...\033[0K\r"
				tar -xjf $extract -C $temploc/
				echo -ne "\033[0K\r"
				echo "Done!"
				sleep 2
				echo
				###### Move KERNEL & SYSTEM to /storage/.update/
				echo "Moving Images to /storage/.update"
				echo -ne "Please Wait...\033[0K\r"
				find $temploc -type f -name "KERNEL" -exec /bin/mv {} /storage/.update \;
				find $temploc -type f -name "SYSTEM" -exec /bin/mv {} /storage/.update \;
				mv $temploc/OpenELEC-*/target/*.md5 /storage/.update
				echo -ne "\033[0K\r"
				echo "Done!"
				sleep 2
				###### Compare md5-sums
				sysmd5=$(cat /storage/.update/SYSTEM.md5 | awk '{print $1}')
				kernmd5=$(cat /storage/.update/KERNEL.md5 | awk '{print $1}')
				kernrom=$(md5sum /storage/.update/KERNEL | awk '{print $1}')
				sysrom=$(md5sum /storage/.update/SYSTEM | awk '{print $1}')
				if [ "$sysmd5" = "$sysrom" ] ;
				then
					echo
					echo "md5 ==> SYSTEM: OK!"
					rm -f /storage/.update/SYSTEM.md5
					sys_return=0
				else
					sys_return=1
				echo "---   WARNING   ---"
				echo "SYSTEM md5 MISMATCH!"
				echo "--------------------"
				echo "There is an integrity problem with the SYSTEM package"
				echo "Notify one of the developers on the Forums or IRC that"
				echo "the SYSTEM image of $fn.tar.bz2 is corrupt"
				sleep 3
				rm -f /storage/.update/SYSTEM
				rm -f /storage/.update/SYSTEM.md5
				rm -rf $temploc/
				sync
				fi
				sleep 1
				if [ "$kernmd5" = "$kernrom" ] ;
				then
					echo "md5 ==> KERNEL: OK!"
					rm -f /storage/.update/KERNEL.md5
					kern_return=0
				else
				kern_return=1
				echo "---   WARNING   ---"
				echo "KERNEL md5 MISMATCH!"
				echo "--------------------"
				echo "There is an integrity problem with the KERNEL package"
				echo "Notify one of the developers on the Forums or IRC that"
				echo "the KERNEL image of $fn.tar.bz2 is corrupt"
				sleep 3
				rm -f /storage/.update/KERNEL
				rm -f /storage/.update/KERNEL.md5
				rm -rf $temploc/
				sync
				fi
				return=$(($kern_return+$sys_return))
				if [[ "$return" = "2" ]] ;
				then
					echo "md5 mismatch detected."
					echo "Update Terminated."
					unsetv
					exit 1
				fi
				###### some feedback
				echo "File Integrity: PASSED!"
				echo
				echo -ne "Continuing...\033[0K\r"
				sleep 2
				echo -ne "\033[0K\r"
				###### Cleanup
				rm -rf $temploc/
				###### ask if we want to reboot now
				echo "Update Preperation Complete."
				sleep 2
				echo "You must reboot to complete the update."
				echo "Would you like to reboot now (y/n) ?"
				read -n1 -p "==| " reb
				if [[ "$reb" != "Y" ]] && [[ "$reb" != "y" ]] && [[ "$reb" != "N" ]] && [[ "$reb" != "n" ]] && [[ "$reb" != "yes" ]] && [[ "$reb" != "no" ]] && [[ "$reb" != "Yes" ]] && [[ "$reb" != "No" ]] ;
				then
					echo
					echo "Unrecognized Input."
					echo "Please answer (y/n)"
					echo "Exiting."
					echo
					exit 1
				elif [[ "$reb" = "Y" || "$reb" = "y" || "$reb" = "Yes" || "$reb" = "yes" ]] ;
				then
					sleep 1
					echo
					echo "Rebooting..."
					sync
					sleep 1
					/sbin/reboot
					exit 0
					elif [[ "$reb" = "N" || "$reb" = "n" || "$reb" = "No" || "$reb" = "no" ]] ;
					then
						sleep 1
						echo
						echo
						echo "Please reboot to complete the update."
						echo "Exiting."
						exit 0
						fi
				## everything went well: we're done !
				exit 0	
			elif [[ $old = "N" || $old = "n" || $old = "No" || $old = "no" ]] ;
			then
				echo
				echo
				echo "User aborted process."
				sleep 2
				echo "Exiting."
				echo
				exit 0
			fi
		;;

	v)
		options_found=1
		# whats our script's version
		echo
		echo "OpenELEC_DEV Version: $VERSION"
		;;

	b)
		# reboot -- intentionally undocumented (needed only for GUI interaction)
		options_found=1
		/sbin/reboot
		;;

	h|help)
		options_found=1
		# options avaliable and usage.
		echo
		echo "Usage:  $0 [-iozacrlsvh]"
		echo
		echo "-i                   check if SYSTEM & KERNEL are already in-place; suggest reboot."
		echo "-o                   list all avaliable archival builds for your architecture."
		echo "-z                   roll back or forward to a version of our choosing."
		echo "-a                   list all avaliable builds for your architecture."
		echo "-c                   quick check to see if we're up-to-date."
		echo "-r                   check the remote build revision."
		echo "-l                   what's our local build revision."
		echo "-s                   check for new script version"
		echo "-v                   script version."
		echo "-h/--help            help."
		exit
		;;

	\?)
		# terminate if invalid option is used
				echo "Invalid option used: -$OPTARG" >&2
				echo "Run with -h/--help"
				echo
				exit 1
		;;
	esac
done


###### allows multiple options to be calculated and displayed as if it were the only one passed

shift $(($OPTIND - 1))


###### if options are specified, we wont proceede any further, unless -z is passed


if [ "$options_found" -ge "1" ] ;
then
	exit 0
fi


###### changelog

changelog ()
{
echo "Github Commit/Change Log:"
echo "https://github.com/wavrunrx/OpenELEC_Dev/commits/master"
}


###### removes temporary files that have been created if the user prematurly aborts the update process; i.e. CTRL + C

trap ctrl_c 2
ctrl_c ()
{
echo -ne "\n\n"
unsetv
rm -rf $temploc/
echo -ne "SIGINT Interrupt caught"
echo -ne "\nTemporary files removed\n"
echo -ne "\nBye !\n"
exit 1
}


###### for cleanup purposes, we're removing some enviroment variables we've set, after the script is run or aborted

unsetv ()
{
unset options_found
unset kern_return
unset currentsys
unset update_yes
unset sys_return
unset SYS_KERN
unset PRESENT
unset VERSION
unset kernmd5
unset kernrom
unset sysrom
unset OPTIND
unset FOLDER
unset branch
unset sysmd5
unset rsvers
unset status
unset PAST
unset mode
unset arch
unset reb
unset old
unset yn
}


###### check that were actually running a devel build already; otherwise cancel the opertation, with an explanation of why

currentsys=$(cat /etc/version | cut -f 1 -d'-')
if [ "$currentsys" != "devel" ] ;
then
	echo
	echo "Your Version:"
	echo "Release: $currentsys"
	echo
	echo "You're currently on a Stable release of OpenELEC."
	echo "To use this script, you first need to manually"
	echo "migrate OpenELEC to a development build. Be aware"
	echo "that development builds are inherently unstable"
	echo "and should not be used in production enviroments."
	echo "Usability of your HTPC may be adversly effected."
	echo
	echo "Once you are running a development build, you may"
	echo "keep your system up-to-date by re-running this script"
	echo "from time to time."
	echo
	echo "Visit the following locations to get started if you"
	echo "accept the risks of using pre-release software:"
	echo "---------------------------------------------------"
	echo
	echo "A How-To for Manually Updating OpenELEC:"
	echo "http://wiki.openelec.tv/index.php?title=Updating_OpenELEC"
	echo 
	echo "Location of development builds:"
	echo "http://sources.openelec.tv/tmp/image/"
	echo
	echo "---------------------------------------------------"
	echo
	echo "Exiting Now."
	echo
	exit 1
fi

###### making sure github is alive and ready to update the script if nessessary.

echo
echo -ne "Checking Update Server's State...\033[0K\r"
sleep 2
echo -ne "\033[0K\r"
echo -ne "Please Wait...\033[0K\r"
ping -qc 3 raw.github.com > /dev/null
echo -ne "\033[0K\r"
if [ "$?" = "0" ] ;
then
	echo -ne "Update Server Active.\033[0K\r"
	sleep 1
	echo -ne "\033[0K\r"
	###### check if a script update is in progress
	if [ ! -f /tmp/update_in_progress ] ;
	then
		###### file does not exist :: first run
		###### checking script version; auto updating and re-running new version; if available 
		rsvers=$(curl --silent https://raw.github.com/wavrunrx/OpenELEC_Dev/master/openelec-nightly_latest.sh | grep "VERSION=" | grep -v grep | sed 's/[^0-9]*//g')
		if [ "$rsvers" -gt "$VERSION" ] ;
		then
			echo
			echo "*---| Script Update Available."
			echo "*---| Current Version: $VERSION"
			echo "*---| New Version: $rsvers"
			echo
			echo "Changelog:"
			echo
			changelog
			sleep 3
			echo
			echo "*---| Updating OpenELEC_DEV Now:"
			sleep 1
			curl –-silent https://raw.github.com/wavrunrx/OpenELEC_Dev/master/openelec-nightly_latest.sh > `dirname $0`/openelec-nightly_$rsvers.sh
			echo "Done !"
			echo
			echo
			###### indicate update in progress to next script instance
			touch /tmp/update_in_progress
			###### run a new version of update script
			sh `dirname $0`/openelec-nightly_$rsvers.sh
			###### remove update indication flag
 			rm -f /tmp/update_in_progress
			###### swapping  script old with new
			rm -f `dirname $0`/openelec-nightly_latest.sh
			mv `dirname $0`/openelec-nightly_$rsvers.sh `dirname $0`/openelec-nightly_latest.sh
			chmod 755 `dirname $0`/openelec-nightly_latest.sh
			###### exit old script
			exit
		else
			echo -ne "Script Update Not Avaliable."
			sleep 2
			echo -ne "\033[0K\r"
			echo -ne "Continuing...\033[0K\r"
			sleep 1
			echo -ne "\033[0K\r"
		fi
	fi
else
	echo 
	echo "* Script Update Server Not Responding"
	echo "* Checking again on the next run."
	echo "---------------------------------"
	echo -ne "Continuing...\033[0K\r"
	sleep 3
	echo -ne "\033[0K\r"
	echo
fi


###### make .update

mkdir -p /storage/.update


###### checking for a previous run: if SYSTEM & KERNEL files are still in ~/.update then we havent rebooted since we last ran.
###### this check prevents us from unnecessarily redownloading the update package.

SYS_KERN=$(ls /storage/.update/* 2> /dev/null | wc -l)
if [ "$SYS_KERN" = "2" ] ;
then
echo
echo
echo "KERNEL & SYSTEM are already in place."
echo "You must reboot to complete the update."
echo "Would you like to reboot now (y/n) ?"
read -n1 -p "==| " reb
if [[ $reb != "Y" ]] && [[ $reb != "y" ]] && [[ $reb != "N" ]] && [[ $reb != "n" ]] && [[ $reb != "yes" ]] && [[ $reb != "no" ]] && [[ $reb != "Yes" ]] && [[ $reb != "No" ]] ;
then
	echo
	echo
	echo "Unrecognized Input."
	sleep 2
	echo "Please answer (y/n)"
	echo "Exiting."
	echo
	unsetv
	rm -rf $temploc/
	exit 1
elif [[ $reb = "Y" || $reb = "y" || $reb = "Yes" || $reb = "yes" ]] ;
then
	echo
	echo
	echo
	echo "Rebooting..."
	unsetv
	rm -rf $temploc/
	sync
	sleep 2
	/sbin/reboot
	exit 0
elif [[ $reb = "N" || $reb = "n" || $reb = "No" || $reb = "no" ]] ;
then
	echo
	echo
	echo "Please reboot to complete the update."
	sleep 2
	echo "Exiting."
	unsetv
	rm -rf $temploc/
	exit 0
	fi
fi


###### create the temporary working directory; delete if it already exists; (script would terminate if anything is already in there)

if [ -d "$temploc" ] ;
then
	rm -rf $temploc/
	mkdir -p $temploc
else
	mkdir -p $temploc
fi


###### Captures remote filename & extension

arch=$(cat /etc/arch)
curl -silent $mode/ | grep $arch | sed -e 's/<li><a href="//' -e 's/[^ ]* //' -e 's/<\/a><\/li>//' > $temploc/temp


###### remove all but the newest build from out list

if [ $(wc -l $temploc/temp | cut -c -1) -gt "1" ] ;
then
	cat $temploc/temp | tail -n 1 > $temploc/temp2
else
	mv $temploc/temp $temploc/temp2
fi


#####

## filename w/o extension (architecture agnostic)
FOLDER=$(cat $temploc/temp2 | sed '$s/........$//')

## capture local build revision
PAST=$(cat /etc/version | tail -c 6 | tr -d 'r')

## capture remote build revision (allows revision growth to 5 digits)
PRESENT=$(cat $temploc/temp2 | tail -c 15 | cut -c 0-5)


###### remote build revision (allows revision growth to 5 digits -- 0-9999, & 10000-99999)

if [ `printf $PRESENT | sed 's/.\{4\}$//'` == "-" ] ;
then
	# this is for coming from revisions 9999 and lower ... hopefully nobody's using any nightly builds this old !
	PRESENT=$(cat $temploc/temp2 | tail -c 15 | sed 's/.\{8\}$//' | tr -d "\-r"})
else
	# this is for coming from revisions 10000 and higher
	PRESENT=$(cat $temploc/temp2 | tail -c 15 | sed 's/.\{8\}$//' | tr -d "r")
fi


###### this checks to make sure we are actually running an official development build. if we dont check this; the comparison routine will freak out if our local
###### build is larger then the largest (newest) build on the openelec snapshot server.

if [ "$PRESENT" -lt "$PAST" ] ;
then
	echo
	echo "You are currently using an unofficial development build of OpenELEC."
	echo "This isn't supported, and will yield unusual results if we continue."
	echo "Your build is a higher revision then whats available on the official"
	echo "snapshot server, as seen here: http://sources.openelec.tv/tmp/image/"
	echo
	echo "Local:  $PAST"
	echo "Remote: $PRESENT"
	echo
	sleep 2
	echo "Exiting Now."
	echo
	unsetv
	exit 1
fi


###### this is only comes into play if the option -q is passed. if so, we supress output if an update isnt available. if one is, we dont care, and want to exit (this will be used in the addon gui)

if [ "$update_yes" = "1" ] ;
then
	exit 0
fi


###### if there are no builds avaliable on the server for your specific architecture, we are going to notify you, and gracefully exit

arch=$(cat /etc/arch)
curl -silent $mode/ | grep $arch | sed -e 's/<li><a href="//' -e 's/[^ ]* //' -e 's/<\/a><\/li>//' > $temploc/temp
if [[ -s $temploc/temp ]] ;
then
	echo "There are no builds avaliable for your architecture on the devel server at this time."
	echo "Please check again later. You may also check manually for yourself here:"
	echo "http://sources.openelec.tv/tmp/image/"
	echo
	rm -rf $temploc/
	unsetv
	echo "Exiting Now."
	echo
	exit 1
fi


###### compare local and remote revisions; decide if we have updates ready

if [ "$PRESENT" -gt "$PAST" ] ;
then
	sleep 1
	echo -ne "\033[0K\r"
	echo
	echo
	echo "#### WARNING:"
	echo "#### UPDATING TO OR FROM DEVELOPMENT BUILDS MAY HAVE POTENTIALLY UNPREDICTABLE EFFECTS"
	echo "#### ON THE STABILITY AND OVERALL USABILITY OF YOUR SYSTEM. SINCE NEW CODE IS LARGELY"
	echo "#### UNTESTED, DO NOT EXPECT SUPPORT ON ANY ISSUES YOU MAY ENCOUNTER AFTER UPDATING."
	echo "#### IF WERE TO BE OFFERED, IT WILL BE LIMITED TO DEVELOPMENT LEVEL DEBUGGING."
	echo
	echo
	echo -ne "Please Wait...\033[0K\r"
	sleep 6
	echo -ne "\033[0K\r"
	echo "===| OpenELEC"
	echo "Updates Are Available."
	echo "Local:   $PAST          Compiled: `cat /etc/version | cut -f 2-2 -d'-' | sed 's/......$//;s/./& /4' | sed 's/./& /7' | awk '{ print "[ "$2"/"$3"/"$1" ]" }'`" 
	echo "Remote:  $PRESENT          Compiled: `echo $FOLDER | cut -f 4-4 -d'-' | sed 's/......$//;s/./& /4' | sed 's/./& /7' | awk '{ print "[ "$2"/"$3"/"$1" ]" }'`"
	echo
	## The remote build is newer then our local build. Asking for input.
	echo "Would you like to update (y/n) ?"
	read -n1 -p "==| " yn
	if [[ $yn != "Y" ]] && [[ $yn != "y" ]] && [[ $yn != "N" ]] && [[ $yn != "n" ]] && [[ $yn != "yes" ]] && [[ $yn != "no" ]] && [[ $yn != "Yes" ]] && [[ $yn != "No" ]] ;
	then
		echo
		echo
		echo "Unrecognized Input."
		sleep 2
		echo "Please answer (y/n)"
		echo "Exiting."
		echo
		unsetv
		exit 1
	elif [[ $yn = "Y" || $yn = "y" || $yn = "Yes" || $yn = "yes" ]] ;
	then
		sleep .5
		echo
		echo
		echo
		echo "Downloading Image:"
		wget $mode/`cat $temploc/temp2` -P "$temploc/"
		echo "Done!"
		extract="$temploc/$FOLDER.tar.bz2"
		sleep 1
	elif [[ $yn = "N" || $yn = "n" || $yn = "No" || $yn = "no" ]] ;
	then
		echo
		echo
		echo "User aborted process."
		sleep 2
		echo "Exiting."
		echo
		unsetv
		exit 0
	fi
else
	## The remote build is not newer then what we've got already. Exit.
	rm -rf $temploc/
	echo -ne "\033[0K\r"
	echo
	echo "===| OpenELEC"
	echo "No Updates Available."
	echo "Local:   $PAST          Compiled: `cat /etc/version | cut -f 2-2 -d'-' | sed 's/......$//;s/./& /4' | sed 's/./& /7' | awk '{ print "[ "$2"/"$3"/"$1" ]" }'`" 
	echo "Remote:  $PRESENT          Compiled: `echo $FOLDER | cut -f 4-4 -d'-' | sed 's/......$//;s/./& /4' | sed 's/./& /7' | awk '{ print "[ "$2"/"$3"/"$1" ]" }'`"
	echo
	echo "Check back later."
	echo
	unsetv
	exit 0
fi


###### extract/move SYSTEM & KERNEL images to the proper location for update

echo
echo "Extracting Files..."
echo -ne "Please Wait...\033[0K\r"
tar -xjf $extract -C $temploc/
echo -ne "\033[0K\r"
echo "Done!"
sleep 2


###### Move KERNEL & SYSTEM  and respective md5's to /storage/.update/
echo
echo "Moving Images to /storage/.update"
echo -ne "Please Wait...\033[0K\r"
find $temploc -type f -name "KERNEL" -exec /bin/mv {} /storage/.update \;
find $temploc -type f -name "SYSTEM" -exec /bin/mv {} /storage/.update \;
mv $temploc/OpenELEC-*/target/*.md5 /storage/.update
echo -ne "\033[0K\r"
echo "Done!"
sleep 2


###### Compare md5-sums

sysmd5=$(cat /storage/.update/SYSTEM.md5 | awk '{print $1}')
kernmd5=$(cat /storage/.update/KERNEL.md5 | awk '{print $1}')
kernrom=$(md5sum /storage/.update/KERNEL | awk '{print $1}')
sysrom=$(md5sum /storage/.update/SYSTEM | awk '{print $1}')

if [ "$sysmd5" = "$sysrom" ] ;
then
	echo
	echo "md5 ==> SYSTEM: OK!"
	sys_return=0
else
	sys_return=1
	echo "---   WARNING   ---"
	echo "SYSTEM md5 MISMATCH!"
	echo "--------------------"
	echo "There is an integrity problem with the SYSTEM package"
	echo "Notify one of the developers on the Forums or IRC that"
	echo "the SYSTEM image of $fn.tar.bz2 is corrupt"
	sleep 3
	rm -f /storage/.update/SYSTEM
	rm -f /storage/.update/SYSTEM.md5
	rm -rf $temploc/
	sync
fi

sleep 1

if [ "$kernmd5" = "$kernrom" ] ;
then
	echo "md5 ==> KERNEL: OK!"
	kern_return=0
else
	kern_return=1
	echo "---   WARNING   ---"
	echo "KERNEL md5 MISMATCH!"
	echo "--------------------"
	echo "There is an integrity problem with the KERNEL package"
	echo "Notify one of the developers on the Forums or IRC that"
	echo "the SYSTEM image of $fn.tar.bz2 is corrupt"
	sleep 3
	rm -f /storage/.update/KERNEL
	rm -f /storage/.update/KERNEL.md5
	rm -rf $temploc/
	sync
fi


###### the system rom is evaluated first.
###### if an error is found, the process is terminated and we would never know if the kernel image was broken as well or not.
######
###### this way we know that if the sum of $kern_return, and $sys_return is anything over "1", that one or both of the images are broken, and we've already been
###### notified which one it was above. exit.

return=$(($kern_return+$sys_return))
if [[ "$return" = "2" ]] ;
then
	echo "md5 mismatch detected."
	echo "Update Terminated."
	unsetv
	exit 1
fi


echo "File Integrity Check: PASSED!"
echo
echo -ne "Continuing...\033[0K\r"
sleep 2
echo -ne "\033[0K\r"


###### create a backup of our current, and new build for easy access if needed for a emergency rollback

if [ -d /storage/downloads/OpenELEC_r$PAST ] ;
then
	rm -rf /storage/downloads/OpenELEC_r$PAST
fi

echo "Creating backup of NEW SYSTEM & KERNEL images."
echo -ne "Please Wait...\033[0K\r"
mkdir -p /storage/downloads/OpenELEC_r$PRESENT
cp /storage/.update/KERNEL /storage/.update/SYSTEM /storage/.update/KERNEL.md5 /storage/.update/SYSTEM.md5 /storage/downloads/OpenELEC_r$PRESENT
echo -ne "\033[0K\r"
echo
echo "---- Important Notice ----"
echo "     In the need of an emergency rollback:"
echo "-->  A backup copy of your *NEW* SYSTEM & KERNEL images (revision $PRESENT) have been created here:"
echo "     /storage/downloads/OpenELEC_r$PRESENT"
echo
echo "Creating backup of PREVIOUS SYSTEM & KERNEL images."
echo -ne "Please Wait...\033[0K\r"
mkdir -p /storage/downloads/OpenELEC_r$PAST
cp /flash/KERNEL /flash/SYSTEM /storage/downloads/OpenELEC_r$PRESENT/KERNEL.md5 /storage/downloads/OpenELEC_r$PRESENT/SYSTEM.md5 /storage/downloads/OpenELEC_r$PAST
echo -ne "\033[0K\r"
echo
echo "     In the need of an emergency rollback:"
echo "-->  A backup copy of your *PREVIOUS* SYSTEM & KERNEL images (revision $PAST) have been created here:"
echo "     /storage/downloads/OpenELEC_r$PAST"
echo
echo "---- Important Notice ----"
echo "-->  NEVER mix SYSTEM & KERNEL images from differing architectures, or build revisions."
echo "-->  You will cause irreparable damage to your operating system which will require a clean re-install."
sleep 5


###### Cleanup

rm -rf $temploc/


###### ask if we want to reboot now

echo
echo
echo "Update Preperation Complete."
sleep 2
echo "You must reboot to finish the update."
echo "Would you like to reboot now (y/n) ?"
read -n1 -p "==| " reb
echo
if [[ "$reb" != "Y" ]] && [[ "$reb" != "y" ]] && [[ "$reb" != "N" ]] && [[ "$reb" != "n" ]] && [[ "$reb" != "yes" ]] && [[ "$reb" != "no" ]] && [[ "$reb" != "Yes" ]] && [[ "$reb" != "No" ]] ;
then
	echo
	echo "Unrecognized Input."
	echo "Please answer (y/n)"
	echo "Exiting."
	echo
	unsetv
	exit 1
elif [[ "$reb" = "Y" || "$reb" = "y" || "$reb" = "Yes" || "$reb" = "yes" ]] ;
then
	sleep 1
	echo
	echo "Rebooting..."
	unsetv
	sync
	sleep 1
	/sbin/reboot
	exit 0
elif [[ "$reb" = "N" || "$reb" = "n" || "$reb" = "No" || "$reb" = "no" ]] ;
then
	sleep 1
	echo
	echo "Please reboot to complete the update."
	echo "Exiting."
	unsetv
	exit 0
fi


## everything went well: we're done !

exit 0
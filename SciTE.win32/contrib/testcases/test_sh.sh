#!/bin/sh
#
# FritzBox - OpenWrt Bootstrap 
# "Thorstens shell script Abenteuer"
#
# Weiterentwicklung von roadmans bootstrap.sh, (16.02.2012)
# https://www.ip-phone-forum.de/threads/openwrt-system-f%C3%BCr-die-fritzbox.245505/
#
# Home: https://gist.github.com/arjunae/b77b6eb1857c78ce14af40b38f081131
#
# = Erstellt ein chroot fähiges openwrt filesystem.
# = initialisiert alle Voraussetzungen für die Nutzung von opkg.
# = Lic: FreeBSD-3Clause / 01.09.2019 / Marcedo@habMalNe@Frage.de
#
# = 2019-09-01 - Initiale Entwickler Version
# = 2019-09-04 - Aufräumarbeiten, Hilfe und Suche implementiert
#	- auch mit busybox umgebungen kompatibel
# 	- todo: add opkg.conf repository settings
# 
# "Einstellungen" "FritzBox"
# OWRT_TARGET = "AR7/generic"; OWRT_SYSTEM = "mipsel_mips32" # 7270 ?
# OWRT_TARGET = "malta/be"; OWRT_SYSTEM = "mips_24kc" # 7390
# OWRT_TARGET = "lantiq"; OWRT_SYSTEM = "mips_24kc" # 3370,7320,7360sl,7362sl,7412,7490
# FritzBox 3370|7490=lantiq,mips24kc 
# FritzBox 4040=ipq40xx, ?
#
# Specify an openwrt release to use
OPENWRT_RELEASE=18.06.4
OPENWRT_TARGET="malta/be" # BigEndian
OPENWRT_SYSTEM="mips_24kc" # eg. FritzBox7390
# Define which packages to fetch from where
PACKAGES_KERNEL="libc,libgcc,libpthread"
PACKAGES_BASE="busybox,opkg,zlib,libuclient,uclient-fetch,libubox,usign" 
PACKAGES_USER="libpcre,wget-nossl" 
PACKAGES_ALL="" #< Those will be searched for in all REPOS
#=====================================
# Set target folder names
PKGCACHE=./pkgcache
TARGETFOLDER=./openwrt-$OWRT_RELEASE
init_repos(){
OWRT_RELEASE=$OPENWRT_RELEASE
OWRT_TARGET=$OPENWRT_TARGET
OWRT_SYSTEM=$OPENWRT_SYSTEM
# OpenWrt Repository structure:
# 1) Platform specific packages (kernel modules / libc)
REPO_TARGET="http://downloads.openwrt.org/releases/$OWRT_RELEASE/targets/$OWRT_TARGET/packages/"
TASK_TARGET="REPO_TARGET|$REPO_TARGET|$(echo $PACKAGES_KERNEL | tr -d '[:blank:]')"
# 2) Base packages (system libraries / busybox)   
REPO_BASE="http://downloads.openwrt.org/releases/$OWRT_RELEASE/packages/$OWRT_SYSTEM/base/"
TASK_BASE="REPO_BASE|$REPO_BASE|$(echo $PACKAGES_BASE | tr -d '[:blank:]')"
# 3) User Space packages (pcre wget-nossl)
REPO_USER="http://downloads.openwrt.org/releases/$OWRT_RELEASE/packages/$OWRT_SYSTEM/packages/" 
TASK_USER="REPO_USER|$REPO_USER|$(echo $PACKAGES_USER | tr -d '[:blank:]')"
# A Task is defined as "RepoShortName|RepoURL|RepoSearch"
JOBS="$TASK_TARGET $TASK_BASE $TASK_USER"
# Fetch package lists for all Repos 
# -takes $JOBS collections ([space] delimited)
# -create a tdb file per Repository
# -Store results in an iterateble pseudo array QUEUE ('|' delimited)
#
}
fetch_tdb() {
printf "  Updating package list \n"
for task in $JOBS; do
  repo_name=$(echo $task | cut -d'|' -f 1)
  repo_url=$(echo $task | cut -d'|' -f 2)
  repo_order=$(echo $task | cut -d'|' -f 3) 
  printf "[ Fetching Package list for $repo_name ]\n"
  if [ $HAVE_CURL = 1 ];then curl -Ls "$repo_url" | sed -ne 's,^.*href="\([^"]*.ipk\)".*$,\1,p' > $PKGCACHE/$repo_name.pkg.tdb;
  elif [ $HAVE_WGET = 1 ];then wget -q -O - "$repo_url" | sed -ne 's,^.*href="\([^"]*.ipk\)".*$,\1,p' > $PKGCACHE/$repo_name.pkg.tdb ;fi;
  entrycount=$(cat $PKGCACHE/$repo_name.pkg.tdb | wc -w)
  printf " ($entrycount) $repo_url\n"
  if [ "$entrycount" = "0" ];then failed;fi
  QUEUE=$QUEUE"$repo_name|$repo_url|$repo_order|"
done
}
#
# Search tdbs to get full qualified package names 
# -takes shorthand names defined in QUEUE
# -sorts them into # delimited pseudo arrays 
# -returns INSTALL_PKG
#
find_pkg() {
printf "  Searching packages  \n"
iterator=0
PACKAGES_ALL=$(echo $PACKAGES_ALL | tr -d '[:blank:]')
for task in $JOBS; do
 iterator=`expr $iterator + 1`
 NAME=$(echo $QUEUE | cut -d'|' -f $iterator)
 iterator=`expr $iterator + 1`
 URL=$(echo $QUEUE | cut -d'|' -f $iterator)
 iterator=`expr $iterator + 1`
 PACKS=$(echo $QUEUE | cut -d'|' -f $iterator)
 echo "[ Searching in $NAME ]" 
 IFS=,
 unset order
 # Search for packages which have predefined Repositories 
 for pkg in $PACKS; do   
    pkgfile=$(getpkgfilename $pkg "${NAME}.pkg.tdb") 
    if test "${pkgfile}" != ""; then 
        printf " {$pkg} == {$pkgfile}\n"
        order=$order"$pkgfile "
    else echo " {$pkg} was not found -> ignored"
    fi   
 done
 # Search for packages in all Repositories
 PKG_NOTFOUND=$PACKAGES_ALL
 for pkg in $PACKAGES_ALL; do   
    pkgfile=$(getpkgfilename $pkg "${NAME}.pkg.tdb") 
    if test "${pkgfile}" != ""; then 
        printf " {$pkg} == {$pkgfile}\n"
        order=$order"$pkgfile "
        PCK_NOTFOUND=$(echo $PCK_NOTFOUND|sed -ne 's,'"$pkg"',,p'|  tr -d "[:blank:]")
    fi
 done
 # create a map by using a tricky dynamically named Variable: 
 eval TASK_$NAME=`echo \"$URL#$order\"`
 unset IFS
done
if test "$PCK_NOTFOUND" != ""; then echo " {$PCK_NOTFOUND} not found -> ignored";fi 
INSTALL_PKG="$TASK_REPO_TARGET,$TASK_REPO_BASE,$TASK_REPO_USER"
}
#
# Download and extract Packages
#
install_pkg(){
echo " Download & Install "
IFS=,
for TASK in $INSTALL_PKG; do
 REPO_URL=$(echo $TASK | cut -d'#' -f 1)
 REPO_PKGLIST=$(echo $TASK | cut -d'#' -f 2)
 unset IFS
 for FILE in $REPO_PKGLIST; do
   FILE=$(echo "$FILE" |  tr -d "[:blank:]")
   getpkg $REPO_URL $FILE || failed
   extract_pkgfile $FILE || failed
 done
IFS=,
done
}
#
# Downloads a Package
# - using curl or wget
#
getpkg() {
   local repo_url=$1
	local filename=$2
	[ -f "$PKGCACHE/$filename" ] && echo "Already fetched: $filename" && return 0
	printf "Fetching $filename...\n"
    if [ $HAVE_CURL = 1 ];then curl --progress-bar -o "$PKGCACHE/$filename.part" "$repo_url$filename" ;
    elif [ $HAVE_WGET = 1 ];then wget -q -O "$PKGCACHE/$filename.part" "$repo_url$filename";fi; 
	mv -f "$PKGCACHE/$filename.part" "$PKGCACHE/$filename"
	return 0
}
#
# Translates a packages shortname to its filename
#
getpkgfilename() {
	local pkg=$1
    local pkgdb=$2
 	echo $(cat "$PKGCACHE/$pkgdb" | grep "^${pkg}_" | sed -ne '$p') || return 1
	return 0
} 
#
# Extract pakages Files
# Populate opkgs info folder with
# - packagename.list
# - packagename.control
#
extract_pkgfile() {
	local pkgfile=$1
    local pkg_shortname=$(echo $pkgfile | cut -d '_' -f 1)
	echo "Extracting $pkgfile..."
    tar zxOf $PKGCACHE/$pkgfile ./control.tar.gz | tar zxf - -C $PKGCACHE || return 1
    mv $PKGCACHE/control $TARGETFOLDER/usr/lib/opkg/info/${pkg_shortname}.control
	tar zxOf $PKGCACHE/$pkgfile ./data.tar.gz | tar zxf - -C $TARGETFOLDER
    files=$(tar zxOf $PKGCACHE/$pkgfile ./data.tar.gz | tar ztf - | grep -e "[^/]$")
    echo $files > ${pkg_shortname}.list
    mv *.list $TARGETFOLDER/usr/lib/opkg/info/
    rm -f $PKGCACHE/prerm $PKGCACHE/postinst $PKGCACHE/conffiles
	return 0
}
#
# Creates Dependency file 'status'
# - Iterate through opkg control files
# - Retrieve status relevant lines
# - Mark package as Installed 
#
create_opkg_status(){
partfile=$PKGCACHE/status.part
rm -f $partfile; touch $partfile 
# Retrieve status relevant lines from all control files to file status
for filename in $TARGETFOLDER/usr/lib/opkg/info/*.control; do
 for entry in Package: Version: Depends: Architecture: ; do
    line=$(grep $entry $filename)
    if [ "$line" != "" ]; then echo "$line" >> $PKGCACHE/status.part; fi
 done
 printf "Status: install ok installed \n" >> $partfile
 printf "Installed-Time: $(date '+%s')\n" >> $partfile
 printf "\n" >> $partfile
done 
mv $partfile $TARGETFOLDER/usr/lib/opkg/status
}
#
# Ensure that the Environment provides the required functionality
#
check_prereq(){
 msg_ok="OK: available"
 msg_nok="FAIL: not available"
 printf "checking for grep => "
 mytest=$(echo "gg hh" | grep gg -c)
 if [ ${mytest} = "1" ]; then echo $msg_ok; HAVE_GREP=1; else echo $msg_nok; failed; fi;
 printf "checking for sed => " 
 mytest=$(echo "gg hh"| sed -ne 's,gg ,gg,p')
 if [ ${mytest} = "gghh" ]; then echo $msg_ok; HAVE_SED=1; else echo $msg_nok; failed; fi;
 printf "checking for cut => "
 mytest=$(echo "gg|hh" | cut -d'|' -f 2)
 if [ ${mytest} = "hh" ]; then echo $msg_ok; HAVE_CUT=1; else echo $msg_nok; failed; fi;
 printf "checking for wc => "
 mytest=$(echo "gg hh" | wc -w)
 if [ ${mytest} = "2" ]; then echo $msg_ok; HAVE_WC=1; else echo $msg_nok; failed; fi;
 printf "checking for tar => "
 which tar >/dev/null 2>&1
 if [ $? = "0" ]; then echo $msg_ok; HAVE_TAR=1; else echo $msg_nok; fi;
 printf "checking for tr => "
 mytest=$(echo "gghh " | tr -d "[:blank:])")
 if [ ${mytest} = "gghh" ]; then echo $msg_ok; HAVE_TR=1; else echo $msg_nok; fi;
 printf "checking for date => "
 date >/dev/null 2>&1
 if [ $? = "0" ]; then echo $msg_ok; HAVE_DATE=1; else echo $msg_nok; fi;
 printf "checking for curl => "
 which curl >/dev/null 2>&1
 if [ $? = "0" ]; then echo $msg_ok; HAVE_CURL=1; else echo $msg_nok; HAVE_CURL=0; fi;
 printf "checking for wget => "
 which wget >/dev/null 2>&1
 if [ $? = "0" ]; then echo $msg_ok; HAVE_WGET=1; else echo $msg_nok; HAVE_WGET=0; fi;
 printf "checking for connectivity => "
 if [ $HAVE_CURL = 1 ];then mytest=$(curl -Ls "http://downloads.openwrt.org" | grep -c "</html>");
 elif [ $HAVE_WGET = 1 ];then mytest=$(wget -q -O - "http://downloads.openwrt.org" | grep -c "</html>");fi;
 if [ ${mytest} = "1" ]; then echo $msg_ok; HAVE_INET=1; else echo $msg_nok; failed; fi;
 printf "checking for write permission => "
 touch $PKGCACHE 2>&1
 if [ $? = "0" ]; then echo $msg_ok; HAVE_WRITE=1; else echo $msg_nok; failed; fi;
}
failed() {
	echo "Error creating root file system."
	exit 1
}
print_help(){
printf " FritzBox - OpenWrt Bootstrap \nCommand line Arguments\n"
printf " -h|--help  you are reading it now\n"
printf " -s|--search search for packages\n"
printf " -c|--dirclean remove generated Folders\n"
printf " --OWRT-RELEASE\n"
printf "   Default: 18.06.4\n"
printf " --REPO-SYSTEM and --REPO-PACKAGE\n"
printf "    {AR7/generic} {mipsel_mips32} == 7270 ... \n"
printf "    {malta/be} {mips_24kc} == 7390 ... \n"
printf "    {lantiq} {mips_24kc} == 3370,7320,7360sl,7362sl,7412,7490 ...\n"
printf " Example:\n  ./bootstrap --OWRT-RELEASE 18.06.1\n"
}
# main 
#
# Parse commandline Arguments
# Code von https://pretzelhands.com/posts/command-line-flags vielen Dank!  
# Default values of arguments
OTHER_ARGUMENTS=""
# Loop through arguments and process them
for arg in "$@"
do
  case $arg in
  -c|--dirclean)
    echo "removing $TARGETFOLDER" 
    rm -rf $TARGETFOLDER
    echo "removing $PKGCACHE" 
    rm -rf $PKGCACHE
    exit 0
    shift # Remove argument value from processing
    ;;
  --OWRT-RELEASE)
    CMDL_OWRT_RELEASE="$2"
    shift # Remove argument name from processing
    shift # Remove argument value from processing
    ;;
  --REPO-SYSTEM)
    CMDL_REPO_TARGET="$2"
    shift # Remove argument name from processing
    shift # Remove argument value from processing
    ;;
  --REPO-PACKAGE)
    CMDL_REPO_SYSTEM="$2"
    shift # Remove argument name from processing
    shift # Remove argument value from processing
    ;;
  -s|--search)
    CMDL_SEARCH="$2"
    CMDL_REPO_SEARCH="$2"
    shift # Remove argument name from processing
    shift # Remove argument value from processing
    ;;
  -h|--help)
    CMDL_SEARCH="$2"
    shift # Remove argument name from processing
    print_help
    exit 0
    ;;
  *)
    OTHER_ARGUMENTS=${OTHER_ARGUMENTS}"$1 "
    if [ "$1" != "" ]; then shift; fi # Remove generic argument from processing
    ;;
  esac
done

# Prefer CMDLine defined Environment
if [ "$CMDL_REPO_SYSTEM" != "" ]; then OPENWRT_TARGET=$CMDL_REPO_TARGET;fi
if [ "$CMDL_REPO_PACKAGE" != "" ]; then OPENWRT_SYSTEM=$CMDL_REPO_SYSTEM;fi
if [ "$CMDL_OWRT_RELEASE" != "" ]; then OPENWRT_RELEASE=$CMDL_OWRT_RELEASE;fi
if [ "$CMDL_REPO_SEARCH" != "" ]; then PACKAGES_KERNEL="";PACKAGES_BASE="";PACKAGES_USER="";PACKAGES_ALL=$CMDL_REPO_SEARCH;fi
#

# Done Parsing Args, begin work
mkdir -p $PKGCACHE
rm -rf $TARGETFOLDER
mkdir -p $TARGETFOLDER
mkdir -p $TARGETFOLDER/usr/lib/opkg/info

init_repos
check_prereq
fetch_tdb
find_pkg
if [ "$CMDL_REPO_SEARCH" != "" ]; then exit 0;fi
install_pkg
create_opkg_status

mkdir -p $TARGETFOLDER/var/lock
mkdir -p $TARGETFOLDER/tmp
return 0

echo "Root file system successfully created under ${TARGETFOLDER}."
echo "Creating ${TARGETFOLDER%/}.tar.gz..."
tar -zcf ${TARGETFOLDER%/}.tar.gz ${TARGETFOLDER}
exit 0


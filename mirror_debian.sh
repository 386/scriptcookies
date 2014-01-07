#!/bin/bash

# install tools
# sudo apt-get install debmirror

LOG_DIR="/disk_3T/debian_mirrors/log"
LOG="$LOG_DIR/$(date '+%F.%T').txt"
test -d $LOG_DIR || mkdir -p $LOG_DIR

# save mirror log
exec &> $LOG

MIRROR_DIR="/disk_3T/debian_mirrors"
test -d $MIRROR_DIR || mkdir -p $MIRROR_DIR

APT_MIRROR="$MIRROR_DIR/mirrors.aliyun.com"

# Set up keyring to correctly verify Release signatures
# **NOTE**: May NOT WORKS
GNUPGHOME="$HOME/.gnupg"
test -f $GNUPGHOME/pubring.gpg || gpg --no-default-keyring --keyring pubring.gpg --import /usr/share/keyrings/debian-archive-keyring.gpg
test -f $GNUPGHOME/trustedkeys.gpg || gpg --no-default-keyring --keyring trustedkeys.gpg --import /usr/share/keyrings/debian-archive-keyring.gpg

# Arch=         -a      # Architecture. For debian can be i386, powerpc or amd64.
# sparc, only starts in dapper, it is only the later models of sparc.
#
arch=amd64,i386

# Minimum debian system requires main, restricted
# Section=      -s      # Section (One of the following - main/restricted/universe/multiverse).
# You can add extra file with $Section/debian-installer. ex: main/debian-installer,universe/debian-installer,multiverse/debian-installer,restricted/debian-installer
#
section=main,non-free,contrib

# Release=      -d      # Release of the system (Dapper, Edgy, Feisty, Gutsy, Hardy, Intrepid), and the -updates and -security ( -backports can be added if desired)
#
release=wheezy,wheezy-proposed-updates

# Server=       -h      # Server name, minus the protocol and the path at the end
# CHANGE "*" to equal the mirror you want to create your mirror from. au. in Australia  ca. in Canada.
# This can be found in your own /etc/apt/sources.list file, assuming you have debian installed.
#
server=mirrors.aliyun.com

# Dir=          -r      # Path from the main server, so http://my.web.server/$dir, Server dependant
#
inPath=/debian

# Proto=        -e      # Protocol to use for transfer (http, ftp, hftp, rsync)
# Choose one - http is most usual the service, and the service must be avaialbe on the server you point at.
#

# 由于当前阿里云rsync暂时处于内测阶段，所以暂时使用http协议，等以后开放了再换回rynsc协议--2014-01-06 10:35
#proto=rsync
proto=http


# NOTE: debmirror uses -aL --partial by default.
#       However, if you provide the --rsync-options
#       paramter (which we do) then you HAVE to provide
#       it -aL --partial in addition to whatever You
#       want to add (e.g. --bwlimit) If you don't
#       debmirror will exit with thousands of files
#       missing.
rsync_options="-aL --partial --no-iconv"

# Outpath=              # Directory to store the mirror in
# Make this a full path to where you want to mirror the material.
#
outPath=$APT_MIRROR

# The --nosource option only downloads debs and not deb-src's
# The --progress option shows files as they are downloaded
# --source \ in the place of --no-source \ if you want sources also.
# --nocleanup  Do not clean up the local mirror after mirroring is complete. Use this option to keep older repository


# Mirror debian 10.04 && 12.04
echo "Start mirror aliyun debian mirrors at $(date)"
debmirror       -a $arch \
                -s $section \
                -h $server \
                -d $release \
                -r $inPath \
                --progress \
                --i18n \
                -e $proto \
                --rsync-options="$rsync_options" \
                -v \
                $outPath
echo "Mirror aliyun debian finished at $(date)"

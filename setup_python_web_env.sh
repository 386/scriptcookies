#!/usr/bin/env bash

#######################################################################
# Usage  : setup python work env script
# Author : Liang Lin
# Mail   : lin.liang@tcl.com
# Date   : 2014-04-22
# PS     : Feel free to contact me for any questions about this script
#######################################################################

#set -x

export PS4='\033[01;32m+[${BASH_SOURCE}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }\033[00m'

function warn()
{
    echo "$0:" "$@" >&2
}

function die()
{
    rc=$1
    shift
    warn "$@"
    exit $rc
}

function update_apt_source()
{
    UBUNTU_CODENAME=$(lsb_release -cs)
    if [ -z $UBUNTU_CODENAME ];then
        die 1 "No UBUNTU_CODENAME assigend"
    fi

    local tmp_source=$(mktemp -u)
    cat >> $tmp_source << EOF
deb $UBUNTU_MIRROR/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
deb $UBUNTU_MIRROR/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
deb $UBUNTU_MIRROR/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
deb $UBUNTU_MIRROR/ubuntu/ $UBUNTU_CODENAME-proposed main restricted universe multiverse
deb $UBUNTU_MIRROR/ubuntu/ $UBUNTU_CODENAME-backports main restricted universe multiverse
EOF
    local APT_FILE="/etc/apt/sources.list"
    sudo mv $APT_FILE $APT_FILE.bak
    sudo mv $tmp_source $APT_FILE
    sudo apt-get update && sudo apt-get -y upgrade
}

function install_packages()
{
    # install useful packages
    sudo apt-get install -y vim git chromium-browser ipython ctags curl python-dev python-mysqldb nginx

    # set mysql password with no interactive
    echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
    sudo apt-get -y install mysql-server

    # update pip
    sudo easy_install -i $PYPI_MIRROR -U pip

    # install python modules
    sudo pip install Flask Flask-Script Flask-SQLAlchemy Flask-Cache Flask-RESTful Flask-WTF \
        Flask-login Flask-Migrate Flask-Mail gunicorn jieba xlwt gevent pytz python-memcached \
        raven[flask] Fabric -i $PYPI_MIRROR
}

function config_packages()
{
    # config git
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global color.ui auto

    # set pip mirror
    test -d $HOME/.pip || mkdir -p $HOME/.pip
    rm -f $HOME/.pip/pip.conf
    cat >> $HOME/.pip/pip.conf <<EOF
[global]
index-url=$PYPI_MIRROR
EOF

    # set easy_install mirror
    rm -f $HOME/.pydistutils.cfg
    cat >> $HOME/.pydistutils.cfg <<EOF
[easy_install]
index-url=$PYPI_MIRROR
find-links=$PYPI_MIRROR
EOF

}

function init_var()
{
    # work mail
    GIT_EMAIL="$1"
    MYSQL_PASSWORD="$2"
    test -z "$GIT_EMAIL" && usage
    test -z "$MYSQL_PASSWORD" && usage
    GIT_USERNAME="$(whoami)"
    UBUNTU_MIRROR="http://172.26.32.18"  # No end slash
    PYPI_MIRROR="http://172.26.32.18/pypi/simple/"
}


function usage()
{
    cat <<EOF
    Usage:
       bash $0 your_mail mysql_password

    Args:
       your_mail: your work mail address
       mysql_password: the root mysql password to use when install mysql server

    Example:
       bash $0 foo@example.com secret

EOF
    exit
}

function main()
{
    init_var $@
    update_apt_source
    install_packages
    config_packages
}

main $@

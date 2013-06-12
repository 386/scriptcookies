#!/bin/bash -oe

function init_var()
{
    GIT_USERNAME='crazygit'
    GIT_EMAIL="lianglin999@gmail.com"
}


# 因为要修改源等和安装软件，需要root权限，所以先获得ROOT权限
#function is_root()
#{
#    ROOT_UID=0
#
#    if [ $UID -ne $ROOT_UID ];then
#        echo "This script need ROOT right, Please run as root."
#        exit
#    fi
#}


# 使用163的更新源，同时加上JDK的源
function update_apt_source()
{
    UBUNTU_CODENAME=$(lsb_release -cs)
    if [ -z $UBUNTU_CODENAME ];then
        echo "No UBUNTU_CODENAME assigend"
        exit 1
    fi
    JDK_URL="deb http://archive.canonical.com/ lucid partner"
    APT_FILE="/etc/apt/sources.list"
    sudo mv $APT_FILE $APT_FILE.bak

    cat >> $APT_FILE << EOF
deb http://mirrors.163.com/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ $UBUNTU_CODENAME-proposed main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ $UBUNTU_CODENAME-backports main restricted universe multiverse
$JDK_URL
EOF
    # 添加nvidia显卡驱动地址
    sudo add-apt-repository ppa:ubuntu-x-swat/x-updates
    # 添加fcitx源
    sudo add-apt-repository ppa:fcitx-team/nightly
    sudo apt-get update && sudo apt-get -y upgrade
}


# 安装常用软件
function install_software()
{
    sudo apt-get install -y vim vim-gnome git-core chromium-browser ipython tree sun-java6-jdk \
        flashplugin-installer python-pip virtualbox nvidia-current \
        nvidia-current nvidia-settings vlc stardict etckeeper ctags curl

    sudo pip install markdown flake8

    #安装 fcitx输入法
    sudo apt-get install -y fcitx fcitx-config-gtk fcitx-sunpinyin fcitx-googlepinyin fcitx-module-cloud \
         fcitx-table-all
    im-switch -s fcitx -z default
}


# 不需要ROOT权限
function config_software()
{
    # 配置Git信息
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global color.ui auto

    # 配置vim
    ssh -o StrictHostKeyChecking=no git@github.com
    git clone git://github.com/crazygit/vimconf.git ~/.vim
    bash ~/.vim/install.sh

    # 给man pages添加颜色
    BASHRC_FILE="$HOME/.bashrc"
    cat >> $BASHRC_FILE <<'EOF'

#color man pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

EOF
    # 让命令行支持vi模式
    echo "set -o vi" >> $BASHRC_FILE
    # 给命令行提示符号颜色
    sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' $BASHRC_FILE
    # 增加记录HISTORY的条数
    sed -i 's/HISTSIZE=1000/HISTSIZE=10000/' $BASHRC_FILE
    sed -i 's/HISTFILESIZE=2000/HISTFILESIZE=20000/' $BASHRC_FILE
}

function download_githubs
{
    current_user=$USER
    github_dir=/data/github
    sudo mkdir -p $github_dir
    sudo chown -R $current_user:$current_user /data
    if [ ! -d $github_dir ];then
        echo "Create <$github_dir> dir failed. use $HOME instead"
        github_dir=$HOME/github
        mkdir -p $github_dir
    fi
    cd $github_dir
    git clone https://github.com/crazygit/crazygit.github.com.git
    git clone https://github.com/crazygit/scriptcookies.git
    cd $github_dir/crazygit.github.com && git remote set-url origin git@github.com:crazygit/crazygit.github.com.git
    init_blog=$github_dir/crazygit.github.com/init_env.sh
    test -f $init_blog && bash $init_blog
    cd $github_dir/scriptcookies && git remote set-url origin git@github.com:crazygit/scriptcookies.git
}


function main()
{
   init_var
   update_apt_source
   install_software
   config_software
   download_githubs
}

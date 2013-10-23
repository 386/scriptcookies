#!/bin/bash -oe

# FIXME:
#==================================================
# NOTE:
# 运行脚本之前，先给当前用户不要输入密码的权限
# 运行如下命令:
# $ sudo sed -i 's/%sudo ALL=(ALL) ALL/%sudo ALL=(ALL) NOPASSWD:ALL/' /etc/sudoers
#==================================================

export PS4='[+${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]}:] '


function init_var()
{
    GIT_USERNAME='crazygit'
    GIT_EMAIL="lianglin999@gmail.com"
}


# 使用ustc的更新源，同时加上JDK的源
function update_apt_source()
{
    # 修改source.list
    UBUNTU_CODENAME=$(lsb_release -cs)
    if [ -z $UBUNTU_CODENAME ];then
        echo "No UBUNTU_CODENAME assigend"
        exit 1
    fi

    JDK_URL="deb http://us.archive.ubuntu.com/ubuntu/ hardy multiverse"
    APT_FILE="/etc/apt/sources.list"
    sudo mv $APT_FILE $APT_FILE.bak
    tmp_source=$(mktemp -u)

    cat >> $tmp_source << EOF
deb http://mirrors.ustc.edu.cn/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ $UBUNTU_CODENAME-proposed main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ $UBUNTU_CODENAME-backports main restricted universe multiverse
$JDK_URL
EOF
    sudo mv $tmp_source $APT_FILE

    # 添加nvidia显卡驱动地址
    #sudo add-apt-repository -y ppa:ubuntu-x-swat/x-updates

    # 添加fcitx源
    sudo add-apt-repository -y ppa:fcitx-team/nightly
    sudo apt-get update && sudo apt-get -y upgrade
}


# 安装常用软件
function install_software()
{
    # 安装常用软件
    sudo apt-get install -y vim vim-gnome git-core chromium-browser ipython tree \
        flashplugin-installer python-pip virtualbox vlc stardict ctags curl meld expect \

    sudo apt-get install -y gnome-session-fallback  # gnome-classic 桌面
    sudo apt-get install -y nautilus-open-terminal  # 右键打开终端
    sudo pip install markdown flake8

    #安装显卡驱动
    #sudo apt-get install -y nvidia-current nvidia-settings

    #安装 fcitx输入法
    sudo apt-get purge -y ibus
    sudo apt-get install -y fcitx fcitx-config-gtk fcitx-sunpinyin fcitx-googlepinyin fcitx-module-cloudpinyin \
         fcitx-table-all
    im-switch -s fcitx -z default

    # 安装JDK, 设置自动同意安装协议
    export DEBIAN_FRONTEND=noninteractive
    echo "sun-java6-bin shared/accepted-sun-dlj-v1-1 boolean true" | sudo debconf-set-selections
    sudo -E apt-get install -y sun-java6-jdk
}


function config_software()
{
    # 设置标题栏最大，最小化居右（适用于ubuntu12.xx）
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

    # 配置Git信息
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global color.ui auto

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

PS1='[ \[\033[01;34m\]\w\[\033[00m\] ]\n\[\033[01;32m\]\u@\h\[\033[00m\]:\$ '

EOF
    # 让命令行支持vi模式
    echo "set -o vi" >> $BASHRC_FILE
    # 增加记录HISTORY的条数
    sed -i 's/HISTSIZE=1000/HISTSIZE=10000/' $BASHRC_FILE
    sed -i 's/HISTFILESIZE=2000/HISTFILESIZE=20000/' $BASHRC_FILE
}


function download_githubs
{
    # add github.com to known_hosts for first time to connect github.com
    ssh -o StrictHostKeyChecking=no git@github.com

    # 安装vim
    git clone https://github.com/crazygit/vimconf.git ~/.vim
    bash ~/.vim/install.sh
    cd ~/.vim && git remote set-url origin git@github.com:crazygit/vimconf.git

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
    # 下载常用git库
    git clone https://github.com/crazygit/crazygit.github.com.git
    git clone https://github.com/crazygit/scriptcookies.git
    cd $github_dir/crazygit.github.com && git remote set-url origin git@github.com:crazygit/crazygit.github.com.git
    init_blog=$github_dir/crazygit.github.com/init_env.sh
    test -f $init_blog && bash $init_blog
    cd $github_dir/scriptcookies && git remote set-url origin git@github.com:crazygit/scriptcookies.git
}


function add_github_hooks()
{
    wget https://gist.github.com/crazygit/6027772/raw/987ab611d917c109a1dab811dfe22cfbca9651e5/pre-commit -O /tmp/pre-commit
    chmod +x /tmp/pre-commit
    cp /tmp/pre-commit ~/.vim/.git/hooks
    find $github_dir -type d  -name hooks -exec cp /tmp/pre-commit {} \;
    rm -vf /tmp/pre-commit
}

function install_dev_packages()
{
    sudo apt-get install -y mysql-server-5.5        # mysql数据库
    sudo apt-get install -y apache2
    sudo apt-get install -y php5 php5-gd php5-mysql libapache2-mod-php5
    sudo apt-get install -y phpmyadmin
}


function main()
{
   init_var
   update_apt_source
   install_software
   config_software
   download_githubs
   add_github_hooks
}

main
sudo shutdown -h now

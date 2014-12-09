#!/usr/bin/env bash

#############################################################
# Linux下面配置;
# https://code.google.com/p/goagent/wiki/GoAgent_Linux
# 配置文件修改
# https://code.google.com/p/goagent/wiki/ConfigIntroduce

# 常见问题
# https://code.google.com/p/goagent/wiki/FAQ
#############################################################

#############################################################
# ** NOTE **
#
# 安装Goagent需要使用到的依赖
# sudo apt-get install -y python-dev python-greenlet python-gevent python-vte \
#   python-openssl python-crypto python-appindicator
#############################################################

GOAGENT_URL="https://nodeload.github.com/goagent/goagent/legacy.zip/3.0"
GOAENT_DIR="$HOME/bin"
APP_ID=""

function die()
{
    echo "$1"
    exit 1
}

version=$(curl -Is $GOAGENT_URL | grep -o 'filename=.*.zip' | cut -d '-' -f 3)
test -z "$version" &&
    die "Get goagent version faild" ||
        echo "Get goagent $version"

test -d $GOAGET_DIR ||
    (mkdir -p $GOAGET_DIR || die "Create $GOAGET_DIR Failed")

test -f "$GOAENT_DIR/$version.zip" ||
    (echo "Download $version.zip ..." &&
        wget -q $GOAGENT_URL -O $GOAENT_DIR/$version.zip || die "Download $version.zip failed")


rm -rf $GOAENT_DIR/goagent-goagent-* &&
    unzip -oqd $GOAENT_DIR $GOAENT_DIR/$version.zip || die "Invalid $GOAENT_DIR/$version.zip file"

test -d $GOAENT_DIR/goagent-$version &&
    echo "mv origin $GOAENT_DIR/goagent-$version to $GOAENT_DIR/goagent-$version-bak" &&
        mv $GOAENT_DIR/goagent-$version $GOAENT_DIR/goagent-$version-bak

mv $GOAENT_DIR/goagent-goagent-* $GOAENT_DIR/goagent-$version
python $GOAENT_DIR/goagent-$version/server/uploader.zip



# TO DO:
#
# * 自动上传新版本的goagent服务端
# * 配置客户端的appid
# * 导入证书
# * 添加开机自动运行Goagent，可以使用goagnet自带的添加到开机运行脚本
# 添加更新goagent脚本到开机自动运行

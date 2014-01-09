#!/usr/bin/env bash

#############################################################
# Linux下面配置;
# https://code.google.com/p/goagent/wiki/GoAgent_Linux
# 配置文件修改
# https://code.google.com/p/goagent/wiki/ConfigIntroduce

# 常见问题
# https://code.google.com/p/goagent/wiki/FAQ
#############################################################

function die()
{
    echo "$1"
    exit 1
}

# 安装依赖
# sudo apt-get install -y python-dev python-greenlet python-gevent python-vte \
#   python-openssl python-crypto python-appindicator python-openssl

GOAGENT_URL="https://nodeload.github.com/goagent/goagent/legacy.zip/3.0"
GOAENT_DIR="$HOME/bin"

version=$(curl -Is $GOAGENT_URL | grep -o 'filename=.*.zip' | cut -d '-' -f 3)
echo $version
test -z "$version" && die "Get goagent version faild"
test -f "$version.zip" ||
    (echo "Download $version.zip ..." &&
        wget -q $GOAGENT_URL -O /tmp/$version.zip || die "Download $version.zip failed")

test -d $GOAGET_DIR ||
    (mkdir -p $GOAGET_DIR || die "Create $GOAGET_DIR Failed")

unzip -oqd $GOAENT_DIR /tmp/$version.zip || die "Invalid /tmp/$version.zip file"
test -d $GOAENT_DIR/goagent-$version &&
    echo "mv origin $GOAENT_DIR/goagent-$version to $GOAENT_DIR/goagent-$version-bak" &&
        mv $GOAENT_DIR/goagent-$version $GOAENT_DIR/goagent-$version-bak

mv $GOAENT_DIR/goagent-goagent-* $GOAENT_DIR/goagent-$version &&
    rm -f /tmp/$version.zip

# TO DO:
#
# * 自动上传新版本的goagent服务端
# * 配置客户端的appid
# * 导入证书
# * 添加开机自动运行Goagent，可以使用goagnet自带的添加到开机运行脚本
# 添加更新goagent脚本到开机自动运行

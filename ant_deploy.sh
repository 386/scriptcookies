#!/usr/bin/env bash

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

function set_env()
{
    ANT_HOME="/home/linliang/bin/apache-ant-1.9.2"
    JAVA_HOME="/usr/local/lib/jdk1.7.0_45"
    ANDROID_HOME="/home/linliang/bin/adt-bundle-linux-x86-20131030/sdk"
    PROJECT_NAME="JustTest"
    PROJECT_PATH="$HOME/$PROJECT_NAME"
    ANDROID_TARGET=$(android list targets -c | head -1)

    test -d $ANT_HOME || die 1 "Can not find ANT_HOME"
    test -d $ANDROID_HOME || die 1 "Can not find ANDROID_HOME"
    test -d $PROJECT_PATH || die 1 "Can not find PROJECT_PATH"
    test -f $ANDROID_DOT_JAR || die 1 "Can not find ANDROID_DOT_JAR"
    test -z "$ANDROID_TARGET" || die 1 "Can not find ANDROID_TARGET"

    export ANT_HOME=$ANT_HOME
    export JAVA_HOME=$JAVA_HOME
    export ANDROID_HOME=$ANDROID_HOME
    export PATH=${PATH}:${ANT_HOME}/bin:${ANDROID_HOME}/tools
}

function relase_apk()
{
    cd $PROJECT_PATH
    android update project --target $ANDROID_TARGET --name $PROJECT_NAME  --path $PROJECT_PATH --subprojects
    ant release
}

function main()
{
    set_env
    relase_apk
}

#################################################
# TO DO
#
# 1. android项目提交代码时需要忽略的文件
#     local.properties  这个文件记录了本地的sdk路径，实际自动部署时不能用
# 2. 需要修改的文件
#     ant.properties 添加一些key信息
# 3. proguard-project.txt 混淆操作，有待看如何配置
# 4. 看完官方文档apk发布的相关文章
################################################

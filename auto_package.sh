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
    ANDROID_SDK_HOME="/home/linliang/bin/adt-bundle-linux-x86-20131030/sdk"
    ANDROID_TOOLS_DIR="$ANDROID_SDK_HOME/tools"
    ANDROID_PLATFORM_TOOLS_DIR="$ANDROID_SDK_HOME/platform-tools"
    ANDROID_BUILD_TOOLS_DIR="$ANDROID_SDK_HOME/build-tools/android-4.4"
    ANDROID_DOT_JAR="$ANDROID_SDK_HOME/platforms/android-19/android.jar"
    APKBUILDER="/home/linliang/github/scriptcookies/apkbuilder.sh"
    test -d $ANDROID_TOOLS_DIR || die 1 "Can not find ANDROID_TOOLS_DIR"
    test -d $ANDROID_PLATFORM_TOOLS_DIR || die 1 "Can not find ANDROID_PLATFORM_TOOLS_DIR"
    test -d $ANDROID_BUILD_TOOLS_DIR || die 1 "Can not find ANDROID_BUILD_TOOLS_DIR"
    test -f $ANDROID_DOT_JAR || die 1 "Can not find ANDROID_DOT_JAR"
    test -f $APKBUILDER || die 1 "Can not find APKBUILDER"

    export PATH=$PATH:$ANDROID_SDK_HOME
    export PATH=$PATH:$ANDROID_TOOLS_DIR
    export PATH=$PATH:$ANDROID_PLATFORM_TOOLS_DIR
    export PATH=$PATH:$ANDROID_BUILD_TOOLS_DIR


    ANDROID_TARGET=$(android list targets -c | head -1)
    PROJECT_NAME="JustTest"
    PROJECT_PATH="$HOME/$PROJECT_NAME"
    ACTIVITY_NAME="JustTest"
    PACKAGE="com.test"
}


function create_update_project()
{
    if [ -f $PROJECT_PATH/AndroidManifest.xml ];then
        android update project --target $ANDROID_TARGET --name $PROJECT_NAME  --path $PROJECT_PATH --subprojects
    else
        android create project --target $ANDROID_TARGET --name $PROJECT_NAME  --path $PROJECT_PATH --package $PACKAGE --activity $ACTIVITY_NAME
    fi
}

function build()
{
    cd $PROJECT_PATH || die 1 ' Can not change to PROJECT_PATH'

    # gen R files
    mkdir -p gen
    aapt package -f -m -J gen -S res -M AndroidManifest.xml -I $ANDROID_DOT_JAR

    # gen classes files
    target_version=$(javac -version 2>&1| cut -d ' ' -f2 |cut -d '.' -f1-2)
    javac -target $target_version -bootclasspath $ANDROID_DOT_JAR -d bin $(find $PROJECT_PATH -iname "*.java" | xargs)

    # convert classes files to dex
    dx --dex --output=bin/classes.dex bin

    # package resources
    aapt package -f -M AndroidManifest.xml -S res -I $ANDROID_DOT_JAR -F bin/resources.ap_


    # gen apk
    ######################################################################################
    # NOTE:
    # 使用apkbuilder工具生成apk， 但是由于apkbuilder已经被建议不使用了，所以在此废弃它
    # 采用ant方式自动部署
    ######################################################################################
}

function main()
{
    set_env
    create_update_project
    build
}

main

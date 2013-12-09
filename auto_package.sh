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
    test -d $ANDROID_TOOLS_DIR || die 1 "Can not find ANDROID_TOOLS_DIR"
    test -d $ANDROID_PLATFORM_TOOLS_DIR || die 1 "Can not find ANDROID_PLATFORM_TOOLS_DIR"
    test -d $ANDROID_BUILD_TOOLS_DIR || die 1 "Can not find ANDROID_BUILD_TOOLS_DIR"

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


function main()
{
    set_env
    create_update_project
}

main

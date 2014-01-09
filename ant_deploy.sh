#!/usr/bin/env bash

#################################################
# NOTE:
# android项目提交代码时需要忽略的目录和文件
#    目录: gen, bin
#    文件: local.properties  这个文件记录了本地的sdk路径，实际自动部署时不能用
# TO DO:
#    配置混淆文件
#    具体参看: http://proguard.sourceforge.net/index.html
################################################

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
    ######################################################
    # EDIT BELOW VARIABLES AS NEEDED
    ######################################################

    ANT_HOME="$HOME/bin/apache-ant-1.9.2"
    JAVA_HOME="/usr/local/lib/jdk1.7.0_45"
    ANDROID_HOME="$HOME/bin/adt-bundle-linux-x86-20131030/sdk"
    PROJECT_NAME="JustTest"
    PROJECT_PATH="$HOME/$PROJECT_NAME"
    ANDROID_TARGET=$(android list targets -c | head -1)
    KEY_ALIAS_NAME="your-key-alias-name"
    KEY_PASSWORD="your-key-password"
    KEYSTORE="$PROJECT_PATH/your-keystore"
    KEYSTORE_PASSWORD="your-keystorepass"
    DNAME="CN=user, OU=TCL, O=TCL Communication, L=Cheng Du, ST=Si Cuan, C=Unknown"
    GEN_APK="bin/$PROJECT_NAME-release.apk"
    ANT_PROPERTIES=$PROJECT_PATH/ant.properties
    PROJECT_PROPERTIES=$PROJECT_PATH/project.properties
    PROGUARD_CFG=$PROJECT_PATH/proguard.cfg

    # Check needed variables
    test -d $ANT_HOME || die 1 "Can not find ANT_HOME"
    test -d $ANDROID_HOME || die 1 "Can not find ANDROID_HOME"
    test -d $PROJECT_PATH || die 1 "Can not find PROJECT_PATH"
    test -f $ANDROID_DOT_JAR || die 1 "Can not find ANDROID_DOT_JAR"
    test -n "$ANDROID_TARGET" || die 1 "Can not find ANDROID_TARGET"

    export ANT_HOME=$ANT_HOME
    export JAVA_HOME=$JAVA_HOME
    export ANDROID_HOME=$ANDROID_HOME
    export PATH=${PATH}:${ANT_HOME}/bin:${ANDROID_HOME}/tools
}


function check_sign()
{

    set +x
    echo -e "SIGN INFO\n"
    echo -e "=========================================================\n"
    jarsigner -verify -verbose -certs $GEN_APK
    echo -e "=========================================================\n"
    set -x
}


function relase_apk()
{
    cd $PROJECT_PATH
    android update project --target $ANDROID_TARGET --name $PROJECT_NAME  --path $PROJECT_PATH --subprojects
    ant release
}

function edit_ant_priority()
{

    cat >> $ANT_PROPERTIES <<EOF
key.alias=$KEY_ALIAS_NAME
key.alias.password=$KEY_PASSWORD
key.store=$KEYSTORE
key.store.password=$KEYSTORE_PASSWORD
EOF
}

function edit_proguard()
{
    sed -i 's/^#proguard.config/proguard.config/'  $PROJECT_PROPERTIES
}

function create_key()
{
    # keytool是jdk中自带的工具
    # 以下 -keypass , -storepass, -dname 可以不在参数行设置，输入命令后会自动提示输入，有助于保护密码的安全性
    # 各个参数的意思请参考
    # http://developer.android.com/tools/publishing/app-signing.html

    rm -f $KEYSTORE
    keytool -genkey -v -alias $KEY_ALIAS_NAME -keyalg RSA -keysize 2048  -keypass $KEY_PASSWORD \
        -validity 10000 -keystore $KEYSTORE -storepass $KEYSTORE_PASSWORD \
        -dname "$DNAME"
}


function update_project()
{
    android update project --target $ANDROID_TARGET \
            --name $PROJECT_NAME  --path $PROJECT_PATH --subprojects
}


function main()
{
    set_env
    update_project
#    create_key
    edit_ant_priority
    edit_proguard
    relase_apk
    check_sign
}

main


#function sign_key()
#{
#    jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE -storepass $KEYSTORE_PASSWORD \
#        -keypass $KEY_PASSWORD $APK $KEY_ALIAS_NAME
#}

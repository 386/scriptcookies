#!/usr/bin/env bash

##################################################
# *** TO DO ***

# 更新记录
# 参考: https://support.dnspod.cn/Support/api
##################################################

##################################################
# ***注意***
# 本脚本依赖如下xml文件解析工具，如果没有,请执行如
# 下命令安装
# $ sudo apt-get install xml-twig-tools


# ***按自己的需求修改如下变量***

USERNAME=""
PASSWORD=""
DOMAIN=""           # 如: example.com,
SUB_DOMAIN=""       # 如: mail, 代表域名为 mail.example.com
##################################################

API_PRE_URL="https://dnsapi.cn"
export PS4='\033[01;32m+[${BASH_SOURCE}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }\033[00m'
set -x

function query_domain_ip()
{
    dns_server="114.114.114.114"
    host $1 $dns_server | grep "has address" | head -1 | awk '{ print $4}'
}


function get_api_info()
{
    API_URL=$1
    cond=$2
    shift 2
    param=""
    while [ $# -gt 0 ] ; do
        param="$param&$1"
        shift
    done
    curl -s -X POST \
        -d "login_email=$USERNAME&login_password=$PASSWORD&format=xml&lang=cn$param" \
        -H "User-Agent: dnspod-bash/0.0.1 (crazygit@foxmail.com)" \
        $API_PRE_URL/$API_URL | xml_grep --cond "$cond" --text_only
}


function get_domain_ip()
{
    host_ip=`curl -s "http://members.3322.org/dyndns/getip"`
    domain_ip=`query_domain_ip "$DOMAIN"`
    subdomain_ip=`query_domain_ip "$SUB_DOMAIN.$DOMAIN"`
    echo -e "Current Host IP: $host_ip\n"
    echo -e "Current Domain <$DOMAIN> IP: $domain_ip\n"
    echo -e "Current Sub Domain <$SUB_DOMAIN.$DOMAIN> IP: $subdomain_ip\n"
}


function check_api_version()
{
    echo -e "开始验证Dnspod api版本和用户信息\n"
    version=`get_api_info "Info.Version" "//message"`
    if [ "$version" != '4.6' ];then
        echo -e "获取Dnspod api信息失败\n"
        echo -e "本脚本建立在Dnspod api 4.6上，请检查你的用户信息是否正确\n"
        exit 1
    else
        echo -e "Dndpod api版本和用户信息验证成功\n"
    fi
}


function get_domain_id()
{
    echo -e "开始获取域名<$DOMAIN> id\n"
    DOMAIN_ID=`get_api_info "Domain.Info" "//id" "domain=$DOMAIN"`
    if [ -n "$DOMAIN_ID" ];then
        echo -e "获取域名<$DOMAIN> id成功, id为: $DOMAIN_ID"
        return ""
    else
        echo -e "获取域名<$DOMAIN> id失败, 请检查你的域名是否正确"
        exit 1
    fi
}


function get_record_id()
{
    echo -e "开始获取记录<$DOMAIN> id\n"
    RECORD_ID=`get_api_info "Record.List" "//records//id"  "domain_id=$DOMAIN_ID" "sub_domain=$SUB_DOMAIN"`
    if [ -n "$RECORD_ID" ];then
        echo -e "获取记录<$SUB_DOMAIN.$DOMAIN> id成功, id为: $RECORD_ID"
    else
        echo -e "获取记录<$SUB_DOMAIN.$DOMAIN> id失败, 请检查你的记录是否正确"
        exit 1
    fi
}

function main()
{
    check_api_version
    get_domain_ip
    get_domain_id
    get_record_id
}

main

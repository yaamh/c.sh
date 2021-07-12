#!/bin/bash

_C_infodir=$HOME/.c
_C_cinfo=$_C_infodir/.cinfo
_C_hinfo=$_C_infodir/.hinfo
_C_chistory=$_C_infodir/.chistory

#呼出搜索路径
function cfind
{
    local cdir=$(find * -type d | fzf --bind ctrl-j:down --bind ctrl-k:up)
    if [ -n "$(echo $cdir | grep "\S")" ];then
        cd $cdir
    fi
}

#呼出历史路径
function cdir_history
{
    local cdir=$(tac $_C_chistory | awk '!a[$0]++' | fzf --bind ctrl-j:down --bind ctrl-k:up)
    if [ -n "$(echo $cdir | grep "\S")" ];then
        cd $cdir
    fi
}

#更新路径历史纪录
function cupdate_history
{
    if [ "$(tail -n 1 $_C_chistory)" == "$PWD" ];then
        return
    fi
    echo ${PWD} >> $_C_chistory
    local num=$(($(wc -l $_C_chistory | cut -d " " -f 1)-100))
    if [ $num -gt 0 ];then
        sed -i '1,'"$num"'d' $_C_chistory
    fi  
}

#打印收藏夹
function clist
{ 
    local l=1

    local sortfile=$(cat $_C_cinfo | sort)

    echo $sortfile | sed "s/ /\n/g" > $_C_cinfo

    echo ""
    for line in $(cat $_C_cinfo)
    do 
        echo $line $l
        let l++
    done
    echo ""
}

#打印命令收藏夹
function hlist
{ 
    local l=1

    echo ""
    cat $_C_hinfo | sort | awk '{print NR" "$0}'
    echo ""
    cat $_C_hinfo | sort | awk '{print $0 >> "'${_C_hinfo}tmp'"}'
    
    if [ -f "${_C_hinfo}tmp" ];then
        mv ${_C_hinfo}tmp $_C_hinfo
    fi
}
        
#删除路径
function cdel
{
    if [ $# -eq 0 ];then
        sed -i "\%^${PWD}$%d" $_C_cinfo
        return
    fi

    local str=$(echo $*|grep "[^0-9 ]")
    if [ "$str" != "" ];then
        echo  "err del params"
        return
    fi
    
    local maxline=$(cat $_C_cinfo|wc -l)
    arr=($(echo $@ | sed 's/ /\n/g'|sort -u -r))

    if [ ${arr[0]} -gt $maxline ];then
        echo "err del line:${arr[0]}"
        return 
    fi
    for line in ${arr[@]}
    do
        sed -i "${line}d" $_C_cinfo
    done
}

#删除命令
function hdel
{
    local maxline=$(cat $_C_hinfo|wc -l)
    local arr=("$@")
    arr=($(echo ${arr[@]} | sed 's/ /\n/g'|sort -u -r))
    
    if [ ${arr[0]} -gt $maxline ];then
        echo "err del line:${arr[0]}"
        return
    fi
    for line in ${arr[@]}
    do
        sed -i "${line}d" $_C_hinfo
    done
}

#添加收藏夹
function cadd
{
    local next=0
    local dir=""

    if [ $# -eq 0 ];then
        for line in $(cat $_C_cinfo)
        do
            if [ $line == $PWD ];then
                echo "same dir:$PWD"
                next=1
                break
            fi
        done
        if [ $next -ne 1 ];then
            echo $PWD >> $_C_cinfo
        fi
    fi

    next=0
    while [ $# -ne 0 ];do
        if [ -d $1 ];then
            dir=$(cd $1;echo $PWD)
            for line in $(cat $_C_cinfo)
            do
                if [ $line == $dir ];then
                    echo "same dir:$dir"
                    next=1
                    break
                fi
            done
            if [ $next -ne 1 ];then
                echo $dir >> $_C_cinfo
            fi
            next=0
        else
            echo "err dir:$dir"
        fi
        shift
    done
}

#添加命令收藏夹
function hadd
{
    local cmd="$*"
    
    if [ $# -eq 0 ];then
        return
    fi
    
    while read line
    do 
        if [ "line" == "$cmd" ];then
            echo "same cmd:$cmd"
            return
        fi
    done < $_C_hinfo
    echo -ne "$cmd\n" >> $_C_hinfo
}

#清空收藏夹
function cclear
{
    cat /dev/null > $_C_cinfo
}

#清空命令收藏夹
function hclear
{
    cat /dev/null > $_C_hinfo
}

#进入收藏夹
function cdir
{
    if [ $# -eq 0 ];then
        local cdir=$(cat $_C_cinfo | fzf --bind ctrl-j:down --bind ctrl-k:up)
        if [ -n "$(echo $cdir | grep "\S")" ];then
            cd $cdir
        fi
        return
    fi

    local dir=""
    local str=$(echo $1|grep "[^0-9]")
    if [ "$str" != "" ];then
       dir=$*
    else
        dir=$(sed -n "$1p" $_C_cinfo)   
        local maxline=$(cat $_C_cinfo|wc -l)
        if [ $1 -gt $maxline ];then
            echo "cdir err params,> max lines"
            return
        fi
    fi
    
    cd $cdir
}

#执行命令
function hcmd
{
    if [ $# -eq 0 ];then
        local hcmd=$(cat $_C_hinfo | fzf --bind ctrl-j:down --bind ctrl-k:up)
        if [ -n "$(echo $hcmd | grep "\S")" ];then
            eval $hcmd
        fi
        return
    fi
    
    local str=$(echo $*|grep "[^0-9]")
    if [ "$str" != "" ];then
        eval $*
        return
    fi
    
    local maxline=$(cat $_C_hinfo|wc -l)
    if [ $1 -gt $maxline ];then
        echo "cmd err params, > max lines"
        return
    fi
    
    eval $(sed -n "$1p" $_C_hinfo)
}


#help
function cUSAGE
{
    echo "usage"
    echo "=============="
    echo "c [num]           :enter path"
    echo "c [list/-l]       :show path list"
    echo "c add/-a          :add cur path to list"
    echo "c del/-d [num]    :delete path"
    echo "c clear           :clear path"
    echo "c help/-h         :help"
    echo "c find/-f         :find path"
    echo "c history/-hi     :find history path"
    echo "按tab支持自动补全和智能补全"
}

#help
function hUSAGE
{
    echo "usage"
    echo "=============="
    echo "h [num]           :exec cmd"
    echo "h [list/-l]       :show cmd list"
    echo "h add/-a cmd      :add cmdh to list"
    echo "h del/-d [num]    :delete cmd"
    echo "h clear           :clear cmd"
    echo "h help/-h         :help"
    echo "按tab支持自动补全和智能补全"
}

#自动补全功能
function c
{
    case ${1} in
        "list"|"-l")
            clist
            ;;
        "add"|"-a")
            shift
            cadd $@
            ;;
        "del"|"-d")
            shift
            cdel $@
            ;;
        "clear"|"-c")
            cclear
            ;;
        "help"|"-h")
            cUSAGE
            ;;
        "history"|"-hi")
            cdir_history
            ;;
        "find"|"-f")
            cfind
            ;;
        *)
            cdir $@
            ;;
    esac
}

function h
{
    case ${1} in
        "list"|"-l")
            hlist
            ;;
        "add"|"-a")
            shift
            hadd $@
            ;;
        "del"|"-d")
            shift
            hdel $@
            ;;
        "clear"|"-c")
            hclear
            ;;
        "help"|"-h")
            hUSAGE
            ;;
        *)
            hcmd $@
            ;;
    esac
}

function _checkstr
{
    if [[ $# -eq 1 ]];then
        return 1
    fi
    
    local s1=$1
    local s2=$2
    local str=$s1
    local char=""
    
    for i in $(seq ${#s2})
    do
        char=${s2:i-1:1}
        if [[ $str == ${str#*${char}} ]];then
            return 0
        else
            str=${str#*${char}}
        fi
        
        if [[ $str == "" && ${s1:${#s1}-1:1} != ${char} ]];then
            return 0
        fi
    done
    return 1
}
    
function _getstrcomm
{
    local len=$#
    local arr=($@)
    local char=""
    local tstr=""
    
    local s1=${arr[0]}
    while [ true ]
    do
        char=${s1:0:1}
        if [[ $char == "" ]];then
            echo ${arr[0]}
            return
        fi
        
        for i in $(seq $(($len-1)))
        do
            tstr=${arr[$i]}
            if [[ ${tstr:0:1} != $char ]];then
                tstr=${arr[0]}
                echo ${tstr%*${s1}}
                return
            fi
            arr[i]=${tstr:1}
        done
        s1=${s1:1}
    done
}

function _ch
{
    local cur prev
    local comm=""
    local info=""
    COMPREPLY=()
    
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}
    
    if [[ ${prev} == c ]];then
        info=$_C_cinfo
    elif [[ ${prev} == h ]];then
        info=$_C_hinfo
    fi
    
    while read line
    do 
        if [[ ${prev} == h ]];then
            line="'${line}'"
        fi
        
        local arg=("${line}" "${cur}")
        _checkstr "${arg[@]}"
        if [[ $? -eq 1 ]];then
            COMPREPLY[${#COMPREPLY[*]}]="${line}"
        fi
    done < $info
}
    
    
complete -o nospace -F _ch c
complete -o nospace -F _ch h
    
#不存在则创建
if [ ! -d "$_C_infodir" ];then
    mkdir $_C_infodir
fi
  
if [ ! -f "$_C_cinfo" ];then
    touch $_C_cinfo
fi

if [ ! -f "$_C_chistory" ];then
    touch $_C_chistory
fi

if [ ! -f "$_C_hinfo" ];then
    touch $_C_hinfo
fi

alias cd='cupdate_history;cd'
alias chi='c -hi'
alias cf='c -f'
alias vf='vi $(fzf)'





#!/bin/bash

cinfo=$HOME/.cinfo


#打印收藏夹
function list
{ 
    local l=1

    if [ ! -f "$cinfo" ];then
        touch $cinfo
        return
    fi

    local sortfile=$(cat $cinfo | sort)

    echo $sortfile | sed "s/ /\n/g" > $cinfo

    echo ""
    for line in $(cat $cinfo)
    do 
        echo $line $l
        let l++
    done
    echo ""
}
        



#删除路径
function del
{
    if [ $# -eq 0 ];then
        sed -i "\%^${PWD}$%d" $cinfo
        return
    fi

    local str=$(echo $*|grep "[^0-9 ]")
    if [ "$str" != "" ];then
        echo  "err del params"
        return
    fi
    
    local maxline=$(cat $cinfo|wc -l)
    local arr=("$@")
    arr=$(echo ${arr[@]} | sed 's/ /\n/g'|sort -u)

    if [ ${arr[0]} -gt $maxline ];then
        echo "err del line:${arr[0]}"
        return 
    fi
    for line in ${arr[0]}
    do
        sed -i "${line}d" $cinfo
    done
}

#添加收藏夹
function add
{
    local next=0
    local dir=""

    if [ $# -eq 0 ];then
        for line in $(cat $cinfo)
        do
            if [ $line == $PWD ];then
                echo "same dir:$PWD"
                next=1
                break
            fi
        done
        if [ $next -ne 1 ];then
            echo $PWD >>$cinfo
        fi
    fi

    next=0
    while [ $# -ne 0 ];do
        if [ -d $1 ];then
            dir=$(cd $1;echo $PWD)
            for line in $(cat $cinfo)
            do
                if [ $line == $dir ];then
                    echo "same dir:$dir"
                    next=1
                    break
                fi
            done
            if [ $next -ne 1 ];then
                echo $dir >> $cinfo
            fi
            next=0
        else
            echo "err dir:$dir"
        fi
        shift
    done
}

#清空收藏夹
function clear
{
    cat /dev/null > $cinfo
}

#进入收藏夹
function cdir
{
    if [ $# -eq 0 ];then
        list 
        return
    elif [ $# -gt 1 ];then
        echo "cdir err params, > max params num"
        return
    fi

    local str=$(echo $1|grep "[^0-9]")
    if [ "$str" != "" ];then
        echo "cdir err params,err line num"
        return
    fi

    local maxline=$(cat $cinfo|wc -l)
    if [ $1 -gt $maxline ];then
        echo "cdir err params,>max lines"
        return
    fi

    cd $(sed -n "$1p" $cinfo)
}



#help
function USAGE
{
    echo "usage"
}



function c
{
    case ${1} in
        "list"|"-l")
            list
            ;;
        "add"|"-a")
            shift
            add $@
            ;;
        "del"|"-d")
            shift
            del $@
            ;;
        "clear"|"-c")
            clear
            ;;
        "help"|"-h")
            help
            ;;
        *)
            cdir $@
            ;;
    esac
}



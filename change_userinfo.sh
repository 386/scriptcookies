#!/bin/bash

# 改变当前git库所有分支git 历史提交人的信息

git filter-branch --env-filter '
an="$GIT_AUTHOR_NAME"
am="$GIT_AUTHOR_EMAIL"
cn="$GIT_COMMITTER_NAME"
cm="$GIT_COMMITTER_EMAIL"

if [ "$GIT_COMMITTER_NAME" = "Liang Lin" -o "$GIT_COMMITTER_NAME" = "Lin Liang" -o "$GIT_COMMITTER_NAME" = "linliang" -o "$GIT_COMMITTER_NAME" = "lianglin" ]
then
    cn="crazygit"
    cm="lianglin999@gmail.com"
fi
if [ "$GIT_AUTHOR_NAME" = "Liang Lin" -o "$GIT_AUTHOR_NAME" = "Lin Liang" -o "$GIT_AUTHOR_NAME" = "linliang" -o "$GIT_AUTHOR_NAME" = "lianglin" ]
then
    an="crazygit"
    am="lianglin999@gmail.com"
fi

export GIT_AUTHOR_NAME="$an"
export GIT_AUTHOR_EMAIL="$am"
export GIT_COMMITTER_NAME="$cn"
export GIT_COMMITTER_EMAIL="$cm"
'  -f -- --all

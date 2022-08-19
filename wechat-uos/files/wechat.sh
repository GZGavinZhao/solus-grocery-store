#!/bin/bash
wechat_pid=`pidof weixin`
if test  $wechat_pid ;then
    kill -9 $wechat_pid
fi
bwrap --dev-bind / / \
    --bind /usr/share/wechat-uos/license/etc/os-release /etc/os-release \
    --bind /usr/share/wechat-uos/license/etc/lsb-release /etc/lsb-release \
    --bind /usr/lib64/wechat-uos/ /usr/lib/license/ \
    --bind /usr/share/wechat-uos/license/var/ /var/ \
    /usr/share/wechat-uos/weixin "$@"

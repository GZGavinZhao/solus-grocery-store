#!/usr/bin/python

# Created For Solus Operating System

from pisi.actionsapi import get, pisitools, shelltools

NoStrip = ["/opt", "/usr", "/etc"]
IgnoreAutodep = True

# Suffix = "-1" Not applicable to this application

def setup():
    shelltools.system("pwd")
    shelltools.system("ar xf sogoupinyin_%s_amd64.deb" % (get.srcVERSION()))
    shelltools.system("tar xvf data.tar.xz")
    # shelltools.system("ln -s /opt/sogoupinyin/entries/icons/hicolor/128x128/fcitx-sogoupinyin.png /usr/share/pixmaps/sogoupinyin.png")

def install():
    pisitools.insinto("/", "opt")
    pisitools.insinto("/", "usr")
    pisitools.insinto("/", "etc")
#!/usr/bin/python

# Created For Solus Operating System

from pisi.actionsapi import get, pisitools, shelltools

NoStrip = ["/opt", "/usr"]
IgnoreAutodep = True

# Suffix = "-1" Not applicable to this application

def setup():
    shelltools.system("pwd")
    shelltools.system("ar xf netease-cloud-music_%s_amd64_ubuntu_20190428.deb" % (get.srcVERSION()))
    shelltools.system("tar xvf data.tar.xz")

def install():
    pisitools.insinto("/", "opt")
    pisitools.insinto("/", "usr")
#!/usr/bin/python

# Created For Solus Operating System

from pisi.actionsapi import get, pisitools, shelltools

NoStrip = ["/opt", "/usr", "/etc"]
IgnoreAutodep = True

# Should not change.
Suffix = "-1"

def setup():
    shelltools.system("pwd")
    shelltools.system("ar xf microsoft-edge-dev_%s-1_amd64.deb" % (get.srcVERSION()))
    shelltools.system("tar xvf data.tar.xz")
    shelltools.system("ln -s /opt/microsoft/msedge-dev/product_logo_128_dev.png /usr/share/pixmaps/microsoft-edge-dev.png")

def install():
    pisitools.insinto("/", "opt")
    pisitools.insinto("/", "usr")
    pisitools.insinto("/", "etc")
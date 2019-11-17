# Copyright (C) 2019 Eduardo Righes <eduardo.righes@gmail.com>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Dummy driver code"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

inherit module

SRCREV = "master"

SRC_URI = "\
    git://github.com/eduardorighes/driver-book-dummy \
    file://COPYING \
    "
SRC_URI[sha256sum] = "8c62475ecc32902152cbef11aef3880c100eca69fb18178a55659d65a7f016ce"

S = "${WORKDIR}/git"

RPROVIDES_${PN} += "kernel-module-dummy"

#!/bin/sh

#
# Format and display a file like man
#

[ -z "$1" ] && echo "Usage : $(basename "$0") file" && exit 1
groff -mman -Tutf8 "$1" | less


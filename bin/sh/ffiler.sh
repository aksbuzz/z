#!/bin/bash

###############################################################################
# Copyright (C) 2015 Phillip Smith
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################

set -eu

bomb() {
  echo "BOMBS AWAY: $1" >&2
  exit 1;
}

usage() {
  printf 'Usage: %s [options] file1 file2 fileN\n' "$0"
  printf 'File filer; sort files into a structured directory tree.\n'
  printf 'Example: %s -sm -dm file.txt\n\n' "$0"
  printf 'Options:\n'
  printf '   %-10s %-50s\n' \
    '-s X' 'Filing structure to use. X can be one of:' \
    ''     'm = File by modified timestamp of file' \
    ''     's = File by first X chars of the md5 hash of the file name (faster than -S)' \
    ''     'S = File by first X chars of the md5 hash of the file contents (slow)' \
    ''     'f = File by first X chars of file name (eg, -f3 a/f/i/afile.txt)' \
    ''     't = File by mime-type of file (eg, image/jpeg)' \
    '-d NUM' 'Depth of tree structure (see documentation)' \
    '-M'   'Move files into tree structure (This is the default)'  \
    '-C'   'Copy files into tree structure'  \
    '-L'   'Symbolic link files into tree structure'  \
    '-H'   'Hard link files into tree structure'  \
    '-v'   'Verbose output' \
    '-n'   'Dry run only (do not touch files; implies -v)' \
    '-h'   'This help'
}

dirsplitfilename() {
  string=$1
  depth=$2
  output=
  for ((X=0; X < $depth; X++)) ; do
    char=${string:$X:1}
    # replace non-alphanumeric with an underscore
    if [[ ! $char =~ [A-Za-z0-9] ]] ; then
      char=_
    fi
    output="${output}${char}/"
  done
  echo "$output"
}

declare file_method=undefined
declare file_depth=
declare verbose=
declare dry_run=
declare action=m

### fetch our cmdline options
while getopts ":hs:d:MCLHvn" opt; do
  case $opt in
    s)  file_method=$OPTARG ;;
    d)  file_depth=$OPTARG  ;;
    M)  action=m            ;;  # action == move
    C)  action=c            ;;  # action == copy
    L)  action=l            ;;  # action == sym-link
    H)  action=h            ;;  # action == hard-link
    n)  dry_run=1
        verbose=1           ;;
    v)  verbose=1           ;;
    h)  usage
        exit 0              ;;
    \?) echo "ERROR: Invalid option: -$OPTARG" >&2
        usage
        exit 1              ;;
    :)  echo "ERROR: Option -$OPTARG requires an argument." >&2
        exit 1              ;;
    esac
done
shift $((OPTIND-1))

# make these vars readonly to prevent accidentally changing them beyond this point
readonly file_method file_depth action dry_run verbose

# validate user input
[[ ! $file_method =~ ^[msSft]$ ]] && { bomb "Invalid filing method: $file_method"; }
if [[ $file_method == 'm' ]] ; then
  # depth is the timestamp granularity: ymdHMS
  [[ ! $file_depth =~ ^[ymdHMS]$ ]] && { bomb "Invalid tree depth: $file_depth"; }
elif [[ $file_method =~ ^[Ssf]$ ]] ; then
  # depth is a number
  [[ ! $file_depth =~ ^[0-9]+$ ]] && { bomb "Invalid tree depth: $file_depth"; }
fi

for X in "$@" ; do
  fname="${1:-}"
  shift

  # validate the given user input
  [[ -z "${fname}" ]]   && { usage; exit -1; }
  # TODO: recurse into directories if given by user
  #[[ -d "${fname}" ]] && recurse_this_directory_please
  [[ ! -f "${fname}" ]] && { bomb "File not found: ${fname}"; }

  # strip any leading path from the file name
  base_fname=${fname##*/}

  # find the canonical path for the file
  canon_fname=$(readlink --canonicalize "$fname")

  # get the file modified timestamp in epoch format
  mod_tz_epoch=$(stat --format=%Y "$fname")

  # work out the destination path for this file
  declare destdir=''
  case $file_method in
    m)
      case $file_depth in
        y) destdir=$(date --date=@${mod_tz_epoch} +%Y/)                   ;;
        m) destdir=$(date --date=@${mod_tz_epoch} +%Y/%m-%b/)             ;;
        d) destdir=$(date --date=@${mod_tz_epoch} +%Y/%m-%b/%d/)          ;;
        H) destdir=$(date --date=@${mod_tz_epoch} +%Y/%m-%b/%d/%H/)       ;;
        M) destdir=$(date --date=@${mod_tz_epoch} +%Y/%m-%b/%d/%H/%M/)    ;;
        S) destdir=$(date --date=@${mod_tz_epoch} +%Y/%m-%b/%d/%H/%M/%S)  ;;
      esac ;;
    s) md5hash=$(printf '%s' "$base_fname" | md5sum | awk '{ print $1 }')
       destdir=$(dirsplitfilename "$md5hash" $file_depth)      ;;
    S) md5hash=$(md5sum "$fname" | awk '{ print $1 }')
       destdir=$(dirsplitfilename "$md5hash" $file_depth)      ;;
    f) destdir=$(dirsplitfilename "$base_fname" $file_depth)   ;;
    t) destdir=$(file --brief --mime-type "$fname")           ;;
  esac

  if [[ ! -d "$destdir" ]] ; then
    [[ -n $verbose ]] && printf 'Create destination: %s\n' "$destdir"
    [[ -z $dry_run ]] && mkdir -p "$destdir"
  fi

  # give feedback
  if [[ -n $verbose ]] ; then
    case $action in
      m) printf '[Move] %s  =>  %s\n' "$fname" "$destdir" ;;
      c) printf '[Copy] %s  =>  %s\n' "$fname" "$destdir" ;;
      l) printf '[Symlink] %s  =>  %s\n' "$fname" "$destdir" ;;
      h) printf '[Hardlink] %s  =>  %s\n' "$fname" "$destdir" ;;
    esac
  fi

  # do the action
  if [[ -z $dry_run ]] ; then
    case $action in
      m) mv -f "$fname" "$destdir" ;;
      c) cp -f "$fname" "$destdir" ;;
      l) ln -f --symbolic "$canon_fname" "$destdir" ;;
      h) ln -f "$fname" "$destdir" ;;
  esac
  fi
done

exit 0

#!/usr/bin/env bash

# print_image filename inline base64contents
#   filename: Filename to convey to client
#   inline: 0 or 1
#   base64contents: Base64-encoded contents
print_image() {
  printf '\033]1337;File='
  if [[ -n "$1" ]]; then
    printf 'name='`printf "%s" "$1" | base64`";"
  fi
  if $(base64 --version 2>&1 | grep GNU > /dev/null)
  then
    BASE64ARG=-d
  else
    BASE64ARG=-D
  fi
  printf "%s" "$3" | base64 $BASE64ARG | wc -c | awk '{printf "size=%d",$1}'
  printf ";inline=$2"
  printf ":"
  printf "%s" "$3"
  printf '\a\n'
}

error() {
  echo "ERROR: $@" 1>&2
}

usage() {
  echo "Usage: imgcat file ..." 1>& 2
  echo "   or: imgcat < file" 1>& 2
  exit "$1"
}

## Main

if [ ! -t 0 -a $# -eq 0 ]; then
  usage 1
fi

# Look for command line flags.
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--h|--help)
      usage 0
      ;;
    -*)
      error "Unknown option flag: $1"
      usage 1
      ;;
    *)
      if [ -r "$1" ] ; then
        print_image "$1" 1 "$(base64 < "$1")"
      else
        error "imgcat: $1: No such file or directory"
        exit 2
      fi
      ;;
  esac
  shift
done

# Read and print stdin
if [ -t 0 ]; then
  print_image "" 1 "$(cat | base64)"
fi

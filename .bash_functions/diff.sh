# Use Git’s colored diff when available
if hash git &>/dev/null ; then
  diff() {
    git diff --no-index --color-words "$@"
  }
fi

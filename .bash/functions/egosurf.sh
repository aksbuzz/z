egosurf() {
  git branch > /dev/null 2>&1 || {
    echo 'not a git repository!' >&2
    return 1
  }
  test -f ~/.gitconfig || {
    echo 'no git config file found' >&2
    return 2
  }

  local whoami=`grep '^\s*name\s*=' ~/.gitconfig | sed -r 's/^\s*name\s*=\s*//'`

  test -n "$whoami" || {
    echo 'who am i?' >&2
    return 3
  }

  git log --author="$whoami" $@
}

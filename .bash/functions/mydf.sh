# pretty-print df
mydf() {
  for fs ; do

    if [ ! -d $fs ]
    then
      echo -e $fs" :No such file or directory" ; continue
    fi

    local info=( $(command df -P $fs | awk 'END{ print $2,$3,$5 }') )
    local free=( $(command df -Pkh $fs | awk 'END{ print $4 }') )
    local nbstars=$(( 20 * ${info[1]} / ${info[0]} ))
    local out="["
    for ((j=0;j<20;j++)); do
      if [ ${j} -lt ${nbstars} ]; then
        out=$out"*"
      else
        out=$out"-"
      fi
    done
    out=${info[2]}" "$out"] ("$free" free on "$fs")"
    echo -e $out
  done
}

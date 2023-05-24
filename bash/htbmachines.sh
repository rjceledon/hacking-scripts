#!/bin/bash
# Script made by rjceledon inspired in hack4u.io course from s4vitar
# 29-11-22

#Colors
greencolor="\e[0;32m\033[1m"
endcolor="\033[0m\e[0m"
redcolor="\e[0;31m\033[1m"
bluecolor="\e[0;34m\033[1m"
yellowcolor="\e[0;33m\033[1m"
purplecolor="\e[0;35m\033[1m"
turquoisecolor="\e[0;36m\033[1m"
graycolor="\e[0;37m\033[1m"

tput civis

# Global variables
mainurl="https://htbmachines.github.io/bundle.js"

function ctrl_c() {
  echo -e "\n\n${yellowcolor}[!] Exiting...${endcolor}"
  tput cnorm
  exit 1
}

# CTRL + C
trap ctrl_c INT

function help_panel() {
  echo -e "\n${greencolor}[+] Usage: $0 [-h] [-u] [-m MACHINE_NAME] [-d f|m|d|i] [-o l|w] [-s \"SKILL1 SKILL2\"] [-l MACHINE_NAME]${endcolor}\n"
  echo -e "\t${purplecolor}u) Update and download machines database${endcolor}"
  echo -e "\t${turquoisecolor}m) Search by machine name${endcolor}"
  echo -e "\t${turquoisecolor}d) Search by machine difficulty: Facil, Media, Dificil, Insane${endcolor}"
  echo -e "\t${turquoisecolor}o) Search by machine Operative System: Linux, Windows${endcolor}"
  echo -e "\t${turquoisecolor}s) Search by machine skills${endcolor}"
  echo -e "\t${turquoisecolor}l) Get YouTube link of machine by name${endcolor}"
  echo -e "\t${greencolor}h) Show this help panel${endcolor}\n"
}

function update_data() {
  echo -e "\n${purplecolor}[+] Launching database update...${endcolor}"
  echo -e "${purplecolor}[+] Fetching database info...${endcolor}"
  curl -s $mainurl > .bundle.js.tmp
  if [ ! -f bundle.js ]; then
    echo -e "${yellowcolor}[!] File does not exist, building data...${endcolor}"
    js-beautify .bundle.js.tmp > bundle.js
    echo -e "${purplecolor}[+] Data has been successfully built${endcolor}\n"
  else
    echo -e "${purplecolor}[+] File already exists, checking data version${endcolor}"
    localdbmd5="$(md5sum bundle.js | awk '{print $1}')"
    remotedbmd5="$(js-beautify .bundle.js.tmp | md5sum | awk '{print $1}')"
    if [ $remotedbmd5 != $localdbmd5 ]; then
      echo -e "${yellowcolor}[!] Versions do not match, updating local files...${endcolor}"
      js-beautify .bundle.js.tmp > bundle.js
      echo -e "${purplecolor}[+] Version was succesfully updated${endcolor}\n"
    else
      echo -e "${purplecolor}[+] Version is up to date${endcolor}\n"
    fi
  fi
  rm -f .bundle.js.tmp
}

function item_not_found() {
  item=$2
  context=$1
  echo -e "\n${yellowcolor}[!] $context${endcolor} ${redcolor}$item${endcolor} ${yellowcolor}not found in database, use a different name${endcolor}\n"
}

function search_machine() {
  machinename="$1"
  if [ ! -f bundle.js ]; then
    update_data
  fi
  machineinfo="$(cat bundle.js | awk "/name: \"$machinename\"/,/resuelta: /" | grep -vE "id: |sku: |ip: |resuelta: " | tr -d '",' | sed 's/^ *//')"
  if [ "$machineinfo" ]; then
    echo -e "\n${turquoisecolor}[+] Listing machine ${endcolor}${bluecolor}$machinename${endcolor}${turquoisecolor} information:\n\n$machineinfo${endcolor}\n"
  else
    item_not_found "Machine" $machinename
  fi
}

function get_link() {
  machinename="$1"
  if [ ! -f bundle.js ]; then
    update_data
  fi
  youtubelink="$(cat bundle.js | awk "/name: \"$machinename\"/,/youtube: /" | tail -n 1 | awk 'NF{print $NF}' | tr -d '",')"
  if [ "$youtubelink" ]; then
    echo -e "\n${turquoisecolor}[+] YouTube link for machine ${endcolor}${bluecolor}$machinename${endcolor}${turquoisecolor} is:${endcolor} ${redcolor}$youtubelink${endcolor}\n"
  else
    item_not_found "Machine" $machinename
  fi
}

function search_difficulty() {
  difficulty="$1"
  if [[ $difficulty == "facil" || $difficulty == "f" || $difficulty == "Facil" || $difficulty == 'F' ]]; then
    difficulty="Fácil"
  elif [[ $difficulty == 'media' || $difficulty == 'm' || $difficulty == 'M' ]]; then
    difficulty="Media"
  elif [[ $difficulty == 'dificil' || $difficulty == 'd' || $difficulty == 'Dificil' || $difficulty == 'D' ]]; then
    difficulty="Difícil"
  elif [[ $difficulty == 'insane' || $difficulty == 'i' || $difficulty == 'I' ]]; then
    difficulty="Insane"
  fi
  if [ ! -f bundle.js ]; then
    update_data
  fi
  machinelist="$(tac bundle.js | awk "/dificultad: \"$difficulty\"/,/name: /" | grep "name: " | awk 'NF{print $NF}' | tr -d '",' | sort | column)"
  if [ "$machinelist" ]; then
    echo -e "\n${turquoisecolor}[+] Listing machines with difficulty ${endcolor}${bluecolor}$difficulty${endcolor}${turquoisecolor}:\n\n$machinelist${endcolor}\n"
  else
    item_not_found "Difficulty" $difficulty
  fi
}

function search_os() {
  os="$1"
  if [[ $os == "linux" || $os == "l" || $os == "L" ]]; then
    os="Linux"
  elif [[ $os == 'windows' || $os == 'w' || $os == 'W' ]]; then
    os="Windows"
  fi
  if [ ! -f bundle.js ]; then
    update_data
  fi
  machinelist="$(tac bundle.js | awk "/so: \"$os\"/,/name: /" | grep "name: " | awk 'NF{print $NF}' | tr -d '",' | sort | column)"
  if [ "$machinelist" ]; then
    echo -e "\n${turquoisecolor}[+] Listing machines with Operative System ${endcolor}${bluecolor}$os${endcolor}${turquoisecolor}:\n\n$machinelist${endcolor}\n"
  else
    item_not_found "Operative System" $os
  fi
}

function search_os_difficulty() {
  os="$1"
  difficulty="$2"
  if [[ $os == "linux" || $os == "l" || $os == "L" ]]; then
    os="Linux"
  elif [[ $os == 'windows' || $os == 'w' || $os == 'W' ]]; then
    os="Windows"
  fi
  if [[ $difficulty == "facil" || $difficulty == "f" || $difficulty == "Facil" || $difficulty == 'F' ]]; then
    difficulty="Fácil"
  elif [[ $difficulty == 'media' || $difficulty == 'm' || $difficulty == 'M' ]]; then
    difficulty="Media"
  elif [[ $difficulty == 'dificil' || $difficulty == 'd' || $difficulty == 'Dificil' || $difficulty == 'D' ]]; then
    difficulty="Difícil"
  elif [[ $difficulty == 'insane' || $difficulty == 'i' || $difficulty == 'I' ]]; then
    difficulty="Insane"
  fi

  if [ ! -f bundle.js ]; then
    update_data
  fi
  machinelist="$(tac bundle.js | awk "/dificultad: \"$difficulty\"/,/name: /" | grep -E "dificultad: |so: |name: " | grep "so: \"$os\"" -A 1 | grep "name: " | awk 'NF{print $NF}' | tr -d '",' | sort | column)"
  if [ "$machinelist" ]; then
    echo -e "\n${turquoisecolor}[+] Listing machines with Operative System ${endcolor}${bluecolor}$os${endcolor}${turquoisecolor} and difficulty${endcolor} ${bluecolor}$difficulty${endcolor}${turquoisecolor}:\n\n$machinelist${endcolor}\n"
  else
    item_not_found "Operative System and difficulty" "$os - $difficulty"
  fi
}

function search_skill() {
  skill=$(echo "$1" | tr ' ' '|')
  if [ ! -f bundle.js ]; then
    update_data
  fi
  machinelist="$(tac bundle.js | awk "/skills: /,/name: /" | grep -E "skills: |name: " | sed 's/skills: //' | grep -iE "$skill" -A 1 | grep "name: " | awk 'NF{print $NF}' | tr -d '",' | sort | column)"
  if [ "$machinelist" ]; then
    echo -e "\n${turquoisecolor}[+] Listing machines with skills ${endcolor}${bluecolor}$1${endcolor}${turquoisecolor}:\n\n$machinelist${endcolor}\n"
  else
    item_not_found "Skill" "$1"
  fi
}
# Indexes
declare -i parametercounter=0
declare -i osselection=0
declare -i difficultyselecion=0

while getopts ":m:d:o:s:l:hu" arg; do
  case $arg in
    m)
      machinename=$OPTARG
      let "parametercounter=1"
      ;;
    d)
      difficulty=$OPTARG
      let "parametercounter=4"
      let "difficultyselecion=1"
      ;;
    o)
      os=$OPTARG
      let "parametercounter=5"
      let "osselection=1"
      ;;
    s)
      skill=${OPTARG}
      let "parametercounter=6"
      ;;
    l)
      machinename=$OPTARG
      let "parametercounter=3"
      ;;
    h)
      ;;
    u)
      let "parametercounter=2"
      ;;
  esac
done

if [ $parametercounter -eq 1 ]; then
  search_machine $machinename
elif [ $parametercounter -eq 2 ]; then
  update_data
elif [ $parametercounter -eq 3 ]; then
  get_link $machinename
elif [[ $osselection -eq 1 && $difficultyselecion -eq 1 ]]; then
  search_os_difficulty $os $difficulty
elif [ $parametercounter -eq 4 ]; then
  search_difficulty $difficulty
elif [ $parametercounter -eq 5 ]; then
  search_os $os
elif [ $parametercounter -eq 6 ]; then
  search_skill "$skill"
else
  help_panel
fi

tput cnorm
exit 0

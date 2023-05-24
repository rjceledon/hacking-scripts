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

#CTRL C
tput civis
function ctrl_c() {
  echo -e "\n\n${redcolor}[!] Exiting...${endcolor}\n"
  tput cnorm
  exit 1
}
trap ctrl_c INT

#Help Pane
function help_panel(){
  echo -e "\n${turquoisecolor}[+] Usage: $0 -m MONEY -t TECHNIQUE martingala|reverselb [-v]\n"
  echo -e "\t${turquoisecolor}m) Set money quantity to play with"
  echo -e "\t${turquoisecolor}t) Set technique to use: Martingala, Reverse Labouchere"
  echo -e "\t${turquoisecolor}v) Set verbosity to see each round output\n"
}

function martingala_technique(){
  echo -e "\n${turquoisecolor}[+] Current budget is${endcolor} ${greencolor}$money$\n${endcolor}"
  echo -ne "${bluecolor}[+] Enter your initial bet: ${endcolor}" && tput cnorm && read initialbet && tput civis
  
  while [[ "$evenodd" != "even" && "$evenodd" != "odd" ]]; do
    echo -ne "${bluecolor}[+] Enter your bet option (even/odd): ${endcolor}" && tput cnorm && read evenodd && tput civis
  done

  highestmoney=$money

  echo -e "\n${turquoisecolor}[+] Starting roulette betting ${redcolor}$evenodd${endcolor} ${turquoisecolor}with initial bet ${endcolor}${greencolor}$initialbet\$${endcolor}"

  losingnumbers="[ "
  roundcounter=0
  currentbet=$initialbet
  
  while [ $money -gt 0 ]; do
    let roundcounter++
    money=$(($money - $currentbet))
  
    log "${purplecolor}\n[+] You bet ${endcolor}${greencolor}$currentbet\$${endcolor}${purplecolor}, your budget is ${endcolor}${yellowcolor}$money\$${endcolor}"
    
    randomnumber=$(($RANDOM % 37))

    if [ $randomnumber -eq 0 ]; then
      reward=0
      currentbet=$(($currentbet * 2))
      losingnumbers+="$randomnumber "
    
      log "${purplecolor}[+] Result: ${endcolor}${redcolor}$randomnumber, you lose${endcolor}"

    elif [ $(($randomnumber % 2)) -eq 0 ]; then
      if [ "$evenodd" == "even" ]; then
        reward=$(($currentbet * 2))
        currentbet=$initialbet
        losingnumbers="[ "
        log "${purplecolor}[+] Result: ${endcolor}${greencolor}$randomnumber, you win${endcolor}"

      elif [ "$evenodd" == "odd" ]; then
        reward=0
        currentbet=$(($currentbet * 2))
        losingnumbers+="$randomnumber "
        log "${purplecolor}[+] Result: ${endcolor}${redcolor}$randomnumber, you lose${endcolor}"
      
      fi

    else
      if [ "$evenodd" == "even" ]; then
        reward=0
        currentbet=$(($currentbet * 2))
        losingnumbers+="$randomnumber "
        log "${purplecolor}[+] Result: ${endcolor}${redcolor}$randomnumber, you lose${endcolor}"
      
      elif [ "$evenodd" == "odd" ]; then
        reward=$(($currentbet * 2))
        currentbet=$initialbet
        losingnumbers="[ "
        log "${purplecolor}[+] Result: ${endcolor}${greencolor}$randomnumber, you win${endcolor}"
      
      fi
    fi
    money=$(($money + $reward))
    
    if [ ${#mysequence[@]} -ge ${#longestsequence[@]} ]; then
      longestsequence=(${mysequence[@]})
    fi

  done

  losingnumbers+="]"

  echo -e "\n${redcolor}[!] You have ran out of money to continue after ${endcolor}${graycolor}$roundcounter${endcolor}${redcolor} rounds, your final budget is ${endcolor}${greencolor}$money\$${endcolor}"
  echo -e "\n${redcolor}[!] The highest amount of money reached was ${endcolor}${yellowcolor}$highestmoney\$${endcolor}${redcolor} and the list of losing numbers is the following:\n\n${endcolor}${bluecolor}$losingnumbers${endcolor}\n"

}

function reduce_array(){
  if [ ${#mysequence[@]} -gt 2 ]; then
    unset mysequence[0]
    unset mysequence[-1]
    mysequence=(${mysequence[@]})
  else
    restore_array
  fi
}

function restore_array(){
  log "${purplecolor}[+] Reinitializing sequence"
  
  mysequence=(${initialsequence[@]})
  initialmoney=$money
  
  log "${purplecolor}[+] Resetting money limit to ${endcolor}${yellowcolor}$money\$${endcolor}"
}

function reverselb_technique(){
  echo -e "\n${turquoisecolor}[+] Current budget is${endcolor} ${greencolor}$money$\n${endcolor}"
  
  currentbet=0
  initialmoney=$money 
  highestmoney=$initialmoney
  
  echo -ne "${bluecolor}[+] Enter your initial sequence numbers separated by blank spaces: ${endcolor}" && tput cnorm && read usersequence && tput civis
  
  while [[ "$evenodd" != "even" && "$evenodd" != "odd" ]]; do
    echo -ne "${bluecolor}[+] Enter your bet option (even/odd): ${endcolor}" && tput cnorm && read evenodd && tput civis
  done
  
  declare -a initialsequence
  for number in $(echo $usersequence | tr " " "\n"); do initialsequence+=($number); done
  
  declare -a mysequence=(${initialsequence[@]})
  
  losingnumbers="[ "
  roundcounter=0

  declare -a longestsequence=(${mysequence[@]})

  while [ $money -gt 0 ]; do

    let roundcounter++
    
    log "\n${purplecolor}[+] Using sequence ${endcolor}${bluecolor}[${mysequence[@]}]${endcolor}"
    
    if [ ${#mysequence[@]} -gt 1 ]; then
      currentbet=$((${mysequence[0]} + ${mysequence[-1]}))
    else
      currentbet=${mysequence[0]}
    fi
    
    money=$(($money - $currentbet))
    
    log "${purplecolor}[+] You bet ${endcolor}${greencolor}$currentbet\$${endcolor}${purplecolor}, your budget is ${endcolor}${yellowcolor}$money\$${endcolor}"
    
    randomnumber=$(($RANDOM % 37))

    if [ $randomnumber -eq 0 ]; then
      log "${purplecolor}[+] Result: ${endcolor}${redcolor}$randomnumber, you lose${endcolor}"
      
      losingnumbers+="$randomnumber "
      reward=0
      reduce_array

    elif [ $(($randomnumber % 2)) -eq 0 ]; then
      if [ "$evenodd" == "even" ]; then
        losingnumbers="[ "
        
        log "${purplecolor}[+] Result: ${endcolor}${greencolor}$randomnumber, you win${endcolor}"
        
        reward=$(($currentbet * 2))
        mysequence+=($currentbet)
        mysequence=(${mysequence[@]})

        log "${purplecolor}[+] Refactoring sequence to ${endcolor}${bluecolor}[${mysequence[@]}]${endcolor}"
        
        currentbet=$((${mysequence[0]} + ${mysequence[-1]}))
      
      elif [ "$evenodd" == "odd" ]; then
        losingnumbers+="$randomnumber "
        
        log "${purplecolor}[+] Result: ${endcolor}${redcolor}$randomnumber, you lose${endcolor}"
        
        reward=0
        reduce_array
      fi

    else
      if [ "$evenodd" == "even" ]; then
        losingnumbers+="$randomnumber "
        
        log "${purplecolor}[+] Result: ${endcolor}${redcolor}$randomnumber, you lose${endcolor}"
        
        reward=0
        reduce_array
    
      elif [ "$evenodd" == "odd" ]; then
        losingnumbers="[ "
        
        log "${purplecolor}[+] Result: ${endcolor}${greencolor}$randomnumber, you lose${endcolor}"
        
        reward=$(($currentbet * 2))
        mysequence+=($currentbet)
        mysequence=(${mysequence[@]})

        log "${purplecolor}[+] Refactoring sequence to ${endcolor}${bluecolor}[${mysequence[@]}]${endcolor}"
        
        currentbet=$((${mysequence[0]} + ${mysequence[-1]}))
      fi
    fi

    if [ ${#mysequence[@]} -ge ${#longestsequence[@]} ]; then
      longestsequence=(${mysequence[@]})
    fi

    money=$(($money + $reward))
    
    if [ $money -ge $highestmoney ]; then
      highestmoney=$money
    fi
    
    if [ ${#initialsequence[@]} -gt 1 ]; then
      if [ $money -ge $(($initialmoney + ((${initialsequence[0]} + ${initialsequence[-1]}) * 10))) ]; then
        restore_array
      fi
    else
      if [ $money -ge $(($initialmoney + (${initialsequence[0]}  * 10))) ]; then
        restore_array
      fi
    fi

  done
  
  losingnumbers+="]"

  echo -e "\n${redcolor}[!] You have ran out of money to continue after ${endcolor}${graycolor}$roundcounter${endcolor}${redcolor} rounds, your final budget is ${endcolor}${greencolor}$money\$${endcolor}"
  echo -e "\n${redcolor}[!] The highest amount of money reached was ${endcolor}${yellowcolor}$highestmoney\$${endcolor}${redcolor} and the list of losing numbers is the following:\n\n${endcolor}${bluecolor}$losingnumbers${endcolor}\n"
  echo -e "${redcolor}[!] The longest sequence achieved was:\n\n${endcolor}${bluecolor}[${longestsequence[@]}]${endcolor}${purplecolor} - with ${endcolor}${bluecolor}${#longestsequence[@]}${endcolor}${purplecolor} elements\n"
}

function log(){
  if [[ $_V -eq 1 ]]; then
    echo -e "$@"
  fi
}

while getopts ":m:t:hv" arg; do
  case $arg in
    m)
      money=$OPTARG
      ;;
    t)
      technique=$OPTARG
      ;;
    h)
      ;;
    v)
      _V=1
      ;;
  esac
done

if [[ $money && $technique ]]; then
  if [ "$technique" == "martingala" ]; then
    martingala_technique
  elif [ "$technique" == "reverselb" ]; then
    reverselb_technique
  else
    echo -e "\n${redcolor}[!] Technique ${endcolor}${yellowcolor}$technique${endcolor}${redcolor} does not exist, please use a different one${endcolor}\n"
  fi
else
  help_panel
fi

tput cnorm
exit 0

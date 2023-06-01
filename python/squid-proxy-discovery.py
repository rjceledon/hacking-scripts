#!/usr/bin/python3
import sys, signal, requests

# GLOBAL VARIABLES
TOP50 = [20,21,22,23,25,53,80,110,111,135,139,143,179,199,389,443,445,465,514,515,587,631,636,993,995,1025,1026,1027,1028,1029,1110,1433,1720,1723,1755,1900,2000,2001,2049,2121,3306,3389,5060,5222,5223,5353,5432,5900,6000]
URL = "http://127.0.0.1"
SPROXY = {"http": "http://192.168.100.201:3128"}


# CTRL C
def def_handler(sig, frame):
    print("\n[!] Exiting...")
    sys.exit(1)

def port_discovery():
    for port in TOP50:
        r = requests.get(URL + ":" + str(port), proxies=SPROXY)

        if r.status_code != 503:
            print("\n[+] Port %d is Open:\n[+] Header:\n%s" % (port, r.text))
signal.signal(signal.SIGINT, def_handler)

# MAIN
if __name__ == '__main__':
    port_discovery()

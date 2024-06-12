# This script uses Selenium to automate Todyl license checking, filling the {USERNAME} and {PASSWORD} with an account that has view access
# And filling the {DESIRED_COMPANY} to get the license count of a specific company
import datetime
from pwn import log

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Global variables
username = "{USERNAME}"
password = "{PASSWORD}"
company = "{DESIRED_COMPANY}"

def get_chrome_driver():
    p1 = log.progress("Initializing chrome driver")

    try:
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.5735.198 Safari/537.36 Edg/95.0.1020.30"

        chrome_options = webdriver.ChromeOptions()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--window-size=1920x1080")
        chrome_options.add_argument("--ignore-certificate-errors")
        chrome_options.add_argument("--ignore-ssl-errors")
        chrome_options.add_argument(f"user-agent={user_agent}")

        driver = webdriver.Chrome(options=chrome_options)
        p1.success("Chrome driver initialized successfully")
        return driver
    except:
        p1.failure("Error initializing Chrome driver")
        exit

def main():
    driver = get_chrome_driver()
    p2 = log.progress("Getting Todyl data")
    url = "https://portal.todyl.com/session/login"
    p2.status("Loading Login site")
    driver.get(url)



    driver.find_element(By.ID, "todyl_email").send_keys(username)
    driver.find_element(By.ID, "todyl_password").send_keys(password)

    driver.find_element(By.ID, "btnLogin").click()
    p2.status("Logged in using account: " + username)
    url = "https://portal.todyl.com/deployment/license/bylicensegroup"
    driver.get(url)

    WebDriverWait(driver, 120).until(EC.presence_of_element_located((By.ID, 'org-button')))
    driver.find_element(By.ID, "org-button").click()
    p2.status("Selecting company")
    driver.find_element(By.XPATH, f"//a[contains(text(), '{company}')]").click()
    WebDriverWait(driver, 120).until(EC.presence_of_element_located((By.XPATH, "//tr[not(contains(@class, 'header-item'))]")))
    p2.status("Getting license count text")
    content = driver.find_element(By.XPATH, "//tr[not(contains(@class, 'header-item'))]").text
    p2.status("Saving license info Screenshot")
    now = datetime.datetime.now()
    timestamp = now.strftime("%Y%m%d_%H%M%S")
    driver.save_screenshot(f"TodylScreenshot_{timestamp}.png")
    driver.quit()
    p2.success("Got license text info:\n" + content)

if __name__ == "__main__":
    main()

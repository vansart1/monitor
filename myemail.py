#!/usr/bin/env python3

# Tool to easily send email through gmail through command line
# By Victor Ansart in May 2018

import sys

print(sys.version)

import smtplib
import configparser

print(sys.version)

conf_file = '/usr/local/etc/myemail_conf.ini'

#help message display
if ( len(sys.argv) != 4 ):  #display if we dont have 4 args (myemail, toAddress, subject, message)
	print("Usage: myemail <to_Address> <subject> <message>")
	print("")
	print("Tool to easily send email using gmail")
	sys.exit()

#read config file and get variable values
config = configparser.ConfigParser()
config.read(conf_file)
smtp_server_name = config['MYEMAIL']['SMTP_SERVER_NAME']
smtp_server_port = config['MYEMAIL']['SMTP_SERVER_PORT']
from_address = config['MYEMAIL']['FROM_ADDRESS']
password = config['MYEMAIL']['PASSWORD']

#create smtp server object
smtpServer=(smtp_server_name,smtp_server_port)

#load parameters into variables
to_address = sys.argv[1]
subject = sys.argv[2]
additionalMessage = sys.argv[3]

#assemble email message from data
msg = """From: Capsule <""" + from_address + """>
To: """ + to_address + """
MIME-Version: 1.0
Content-type: text/html
Subject: """ + subject + """

<p>""" + additionalMessage + """</p>"""


#code to send email in try/catch
try:
	server = smtplib.SMTP(*smtpServer)
	server.ehlo()
	server.starttls()
	server.ehlo()
	server.login(from_address,password)
	server.sendmail(from_address, to_address, msg)
	server.quit()
except:
	print("Error : unable to send email")
	sys.exit()


print("Succes!!!!")

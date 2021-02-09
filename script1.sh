#!/bin/sh

loopStatus=1

# This loop is loop 5 times to check whether httpd can start
while [ $loopStatus -lt 5 ]
do

# Check the status of the httpd service and store the status in the httpdStatus.txt file
service httpd status > httpdStatus.txt

# Extract the line 3 from httpdStatus.txt file which status line and store it in the line.txt file
sed -n '3p' <  httpdStatus.txt > line.txt

# Check whether that file include "running" word to identify whether httpd running or not and store it in the activeStatus.txt
grep "running" line.txt > activeStatus.txt

# Check the size of the activeStatus.txt file
FILENAME=/home/ansadmin/activeStatus.txt
FILESIZE=$(stat -c%s "$FILENAME")

# To get the content of the web
HTTP_CODE=$(curl --write-out "%{http_code}\n" "http://13.233.215.86:80/index.html" --output output.txt --silent)

if [[ $FILESIZE != 0 ]]
then
	httpStatus=1
	if [[ $HTTP_CODE == 200 ]]
	then
		status=1

	else
                status=2
	fi
else
	service httpd start
fi

loopStatus=`expr $loopStatus + 1`
done

TIME=$( date '+%F_%H:%M:%S' )

# Using below mysql commands update the status to the database
if [[ $status == 1 ]]
then
	mysql -h server-status.cmsehu0ofsm1.ap-south-1.rds.amazonaws.com -P 3306 -u root -proot1234 SERVER_STATUS -e "INSERT INTO STATUS (date_and_time,details) VALUES('$TIME','Tomcat is running. Content is okay.')";
elif [[ $status == 2 ]]
then
	 mysql -h server-status.cmsehu0ofsm1.ap-south-1.rds.amazonaws.com -P 3306 -u root -proot1234 SERVER_STATUS -e "INSERT INTO STATUS (date_and_time,details) VALUES('$TIME','Tomcat is running. Content is not okay.')";
fi

# Using below commands inform devops team if there any error detect
if [[ $httpStatus != 1 ]]
then
	echo "HTTPD service can't start. Please take nessary actions." | mail -s "Error Report" sasankas159@gmail.com
	mysql -h server-status.cmsehu0ofsm1.ap-south-1.rds.amazonaws.com -P 3306 -u root -proot1234 SERVER_STATUS -e "INSERT INTO STATUS (date_and_time,details) VALUES('$TIME','HTTPD service can't start.')";
fi
if [[ $HTTP_CODE != 200 ]]
then
	echo "Something wrong with web contet. Please take nessary actions." | mail -s "Error Report" sasankas159@gmail.com
	mysql -h server-status.cmsehu0ofsm1.ap-south-1.rds.amazonaws.com -P 3306 -u root -proot1234 SERVER_STATUS -e "INSERT INTO STATUS (date_and_time,details) VALUES('$TIME','Something wrong with web contet.')";
fi

# Remove created unneccesary files
rm httpdStatus.txt
rm line.txt
rm activeStatus.txt

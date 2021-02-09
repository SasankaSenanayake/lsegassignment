#!/bin/sh

# Check and store the content of the web server into output.txt
curl --write-out "%{http_code}\n" "http://13.233.215.86:80/index.html" --output output.txt

# Copy logs file and output file to one folder
cp /var/log/httpd/access_log /home/ansadmin/logs
cp /var/log/httpd/error_log /home/ansadmin/logs
cp /home/ansadmin/output.txt /home/ansadmin/logs

TIME=$( date '+%Y-%m-%d' )

# Create compressed file with logs
tar -cvf $TIME.tar logs

# Upload created compressed file into AWS S3 bucket
aws s3 cp $TIME.tar s3://sasankalseg/ > awsS3log.txt

S3FILENAME=/home/ansadmin/awsS3log.txt
S3FILESIZE=$(stat -c%s "$S3FILENAME")

# Inform devops team if script detects any error
if [ $S3FILESIZE == 0 ]
then
	echo "Can't upload file to the S3 bucket. Please take nessary actions." | mail -s "Error Report" sasankas159@gmail.com
else
	rm $TIME.tar
fi

rm awsS3log.txt
rm output.txt

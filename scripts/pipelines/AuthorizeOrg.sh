#!/bin/bash
# Srii Seelam 2024-JUN-07 - Updated Authorisation process using JWT Bearer Flow

#Check if changes need to be run against org
if [[ ( "$RUNAGAINSTORG" == "false" ) ]] 
then
    echo "NO Changes will be validated/deployed in org as RUNAGAINSTORG value if false"; 
    exit 1;
fi

echo $SALESFORCE_JWT_SECRET_KEY > ./server.key
openssl enc -aes-256-cbc --md sha1 -nosalt -base64 -d -in $ENCRIPTED_KEY -out ./server.key -K $AESKEY -iv $IVKEY
#Authorize Sandbox environment
sf org login jwt -o $USER_NAME -f ./server.key -i $CONSUMER_KEY -r $INSTANCE_URL -s -a $SANDBOX_NAME
if [ $? -eq 0 ]; then
    echo "Successfully authorized the org: $SANDBOX_NAME"
else
    echo "Failed to authorize the org. Please check the error above."
    exit 1
fi
# remove credentials file after authorising org
rm ./server.key 



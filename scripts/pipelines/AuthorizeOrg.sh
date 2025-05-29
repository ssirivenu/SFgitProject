#!/bin/bash
# Srii Seelam 2024-JUN-07 - Updated Authorisation process using JWT Bearer Flow

#Check if changes need to be run against org
if [[ ( "$RUNAGAINSTORG" == "false" ) ]] 
then
    echo "NO Changes will be validated/deployed in org as RUNAGAINSTORG value if false"; 
    exit 1;
fi

#Authorize Sandbox environment
echo $SFDX_URL > ./sf_auth_url.txt
sf org login sfdx-url -f ./sf_auth_url.txt -s -a $SANDBOX_NAME
rm ./sf_auth_url.txt #remove auth file after authorization



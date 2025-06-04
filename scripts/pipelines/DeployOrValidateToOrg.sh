#!/bin/bash     
#Srii Seelam 2024-JUN-07- Initial Version
# Deploy or Validate incremental changes to the org
# Script Arguments:
# $1 = if null, do actual deployment to Org, else do a validation only

# Create folder to store the Increment/ Changes 
mkdir changedSources
# Get Delta using the Sf git delta plugin 
echo "" # insert new line
#echo "FROM_TAG: $FROM_TAG" # if commented, HEAD~1 is used as the from commit
sf sgd source delta -f $FROM_TAG -t $TO_TAG -o "changedSources" -i .forceignore -a $API_VERSION
#sf sgd source delta -f HEAD~1 -t HEAD -o "changedSources" -i .forceignore -a $API_VERSION
if [ $? -eq 0 ]; then
    echo "Delta changes fetched successfully."
else
    echo "Failed to fetch delta changes. Please check the error above."
    exit 1
fi
echo "" # insert new line
echo "For Deployment - Contents of changedSources/package/package.xml:"
cat changedSources/package/package.xml
echo "" # insert new line
echo "Destructive Changes in changedSources/destructiveChanges/destructiveChanges.xml:"
cat changedSources/destructiveChanges/destructiveChanges.xml
echo "" # insert new line
# check if package files have no components to deploy
if ! grep -q '<types>' ./changedSources/package/package.xml ./changedSources/destructiveChanges/destructiveChanges.xml 
then 
    echo "No changes to Deploy. Please deploy any expected changes manually.";exit 0; 
fi
echo "" # insert new line
echo "DeployorValidateToOrg.sh argument is: $1"
echo ""

if [[ ($1 == "validate") && ( "RunSpecifiedTests" == "$UNITTESTS_SCOPE" ) ]] 
then
    if [[(-z SPECIFIEDTESTS) ]]
    then 
        echo "No tests were specifed"
    else
        echo "Starting Org VALIDATION with specifed tests..."
        sf project deploy start --dry-run --async --target-org $SANDBOX_NAME --test-level $UNITTESTS_SCOPE --tests $SPECIFIEDTESTS --manifest "changedSources/package/package.xml" --post-destructive-changes changedSources/destructiveChanges/destructiveChanges.xml --api-version $API_VERSION --ignore-conflicts --json > ./changedSources/asyncDeployResults.json
    fi
elif [[ ($1 == "validate")]]
then
    echo "Starting Org VALIDATION with $UNITTESTS_SCOPE..."
    sf project deploy start --dry-run --async --target-org $SANDBOX_NAME --test-level $UNITTESTS_SCOPE --manifest "changedSources/package/package.xml" --post-destructive-changes changedSources/destructiveChanges/destructiveChanges.xml --api-version $API_VERSION --ignore-conflicts --json > ./changedSources/asyncDeployResults.json
elif [[( "RunSpecifiedTests" == "$UNITTESTS_SCOPE" )]]
then 
    echo "Starting Org DEPLOYMENT with specifed tests..."
    sf project deploy start --async --target-org $SANDBOX_NAME --test-level $UNITTESTS_SCOPE --tests $SPECIFIEDTESTS --manifest "changedSources/package/package.xml" --post-destructive-changes changedSources/destructiveChanges/destructiveChanges.xml --api-version $API_VERSION --ignore-conflicts --json > ./changedSources/asyncDeployResults.json
else # argument is not provided, do a deployment to the org without running tests
    echo "Starting Org DEPLOYMENT with $UNITTESTS_SCOPE..."
    sf project deploy start --async --target-org $SANDBOX_NAME --test-level $UNITTESTS_SCOPE --manifest "changedSources/package/package.xml" --post-destructive-changes changedSources/destructiveChanges/destructiveChanges.xml --api-version $API_VERSION --ignore-conflicts --json > ./changedSources/asyncDeployResults.json
fi

echo ""
echo "Contents of changedSources/asyncDeployResults.json :"
cat changedSources/asyncDeployResults.json

# if the package.xml is empty, the pipeline fails
status="$(cat changedSources/asyncDeployResults.json | jq -r '.status' )"
result_status="$(cat changedSources/asyncDeployResults.json | jq -r '.result.status')"
message="$(cat changedSources/asyncDeployResults.json | jq -r '.message')"
deploymentId="$(cat changedSources/asyncDeployResults.json | jq -r '.result.id')"
echo ""
echo "Deployment Id is: $deploymentId"
echo "status is: $status"
echo "result_status is: $result_status"
echo "message is: $message"

# Pipeline passes if there is nothing to deploy and it is not a Pull Request.gfhgh
if [[ $status == 1  ]];
then echo ""; # insert new line after showing contents of package.xml file
    echo "Deployment initiation failed.Please check deployment error/s in the target org"; exit 1;
fi

echo "" #insert new line
sf project deploy resume -i $deploymentId -w 60
sf project deploy report -i $deploymentId --json > ./changedSources/deployReport.json
success="$(cat changedSources/deployReport.json | jq -r '.result.success')"
echo "" #insert new line
echo "success is: $success"
echo "" #insert new line
#echo "Contents of changedSources/deployReport.json :"
#cat changedSources/deployReport.json

# if deployment status is 1, deployment has failed and the pipeline should fail
if [[ $success == "false" ]];
    then echo "";
        echo "Deployment failed. Please check deployment error/s in the target org."; exit 1;
fi

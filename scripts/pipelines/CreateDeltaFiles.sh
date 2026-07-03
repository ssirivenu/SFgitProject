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
sf sgd source delta -f $FROM_TAG -t $TO_TAG -o "changedSources" -i .forceignore -a $API_VERSION --generate-delta
#sf sgd source delta -f HEAD~1 -t HEAD -o "changedSources" -i .forceignore -a $API_VERSION
echo "" # insert new line
echo "For Deployment - Contents of changedSources/package/package.xml:"
cat changedSources/package/package.xml
echo "" # insert new line
echo "Destructive Changes in changedSources/destructiveChanges/destructiveChanges.xml:"
cat changedSources/destructiveChanges/destructiveChanges.xml
echo "" # insert new line
#!/bin/bash     
#Srii Seelam 2024-JUN-07- Initial Version
# Deploy or Validate incremental changes to the org
# Script Arguments:
# $1 = if null, do actual deployment to Org, else do a validation only


IGNORE_FILE="./ignorefolders"
# Write auth file safely
echo $IGNORE_PATHS
printf '%s' "$IGNORE_PATHS" > "$IGNORE_FILE"
echo "For Deployment - Contents of Ignorefile"
cat $IGNORE_FILE
sf sgd source delta -f $FROM_TAG -t $TO_TAG -o changedSources --generate-delta -i $IGNORE_FILE -a $API_VERSION
echo "" # insert new line
echo "For Deployment - Contents of changedSources/package/package.xml with ignore file:"
cat changedSources/package/package.xml

set -x
sf sgd source delta -f $FROM_TAG -t $TO_TAG -o changedSources -s "${IGNORE_PATHS//$'\n'/-s }" -a $API_VERSION
set +x
echo "" # insert new line
echo "For Deployment - Contents of changedSources/package/package.xml with only ignore paths:"
cat changedSources/package/package.xml
echo ${IGNORE_PATHS//$'\n'/-s}
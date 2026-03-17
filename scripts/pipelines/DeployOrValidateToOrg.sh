#!/bin/bash     
# Deploy or Validate incremental changes to the org

SUMMARY_FILE="$GITHUB_STEP_SUMMARY"

# check if package files have no components to deploy
if ! grep -q '<types>' ./changedSources/package/package.xml ./changedSources/destructiveChanges/destructiveChanges.xml 
then 
    echo "No changes to Deploy. Please deploy any expected changes manually."
    echo "## ⚠️ No Changes Detected" >> $SUMMARY_FILE
    echo "No components found to deploy." >> $SUMMARY_FILE
    exit 0
fi

echo ""
echo "DeployorValidateToOrg.sh argument is: $1"
echo ""

ACTION=$1

# Determine mode
if [[ "$ACTION" == "deploy" ]]; then
  MODE="Deploy"
  DRY_RUN=""
else
  MODE="Validation"
  DRY_RUN="--dry-run"
fi

# Base command
CMD="sf project deploy start $DRY_RUN --async \
  --target-org $SANDBOX_NAME \
  --test-level $UNITTESTS_SCOPE \
  --manifest changedSources/package/package.xml \
  --post-destructive-changes changedSources/destructiveChanges/destructiveChanges.xml \
  --api-version $API_VERSION \
  --ignore-conflicts \
  --json"

# Handle specified tests
if [[ "$UNITTESTS_SCOPE" == "RunSpecifiedTests" ]]; then
  if [[ -z "$SPECIFIEDTESTS" ]]; then
    echo "❌ No tests were specified"

    echo "## ❌ $MODE Failed" >> $SUMMARY_FILE
    echo "No tests were specified while using RunSpecifiedTests." >> $SUMMARY_FILE

    exit 1
  fi

  echo "🚀 Starting Org $MODE with specified tests: $SPECIFIEDTESTS"
  CMD="$CMD --tests $SPECIFIEDTESTS"
else
  echo "🚀 Starting Org $MODE with $UNITTESTS_SCOPE"
fi

# Execute
eval "$CMD" > ./changedSources/asyncDeployResults.json

echo ""
cat changedSources/asyncDeployResults.json

# Extract values
status=$(jq -r '.status' ./changedSources/asyncDeployResults.json)
result_status=$(jq -r '.result.status' ./changedSources/asyncDeployResults.json)
message=$(jq -r '.message' ./changedSources/asyncDeployResults.json)
deploymentId=$(jq -r '.result.id' ./changedSources/asyncDeployResults.json)

echo ""
echo "Deployment Id is: $deploymentId"
echo "status is: $status"
echo "result_status is: $result_status"
echo "message is: $message"

# ❌ Initiation failure
if [[ $status == 1 ]]; then
    echo "Deployment initiation failed."

    echo "## ❌ $MODE Failed (Start Phase)" >> $SUMMARY_FILE
    echo "Message: $message" >> $SUMMARY_FILE

    exit 1
fi

# Wait for completion
sf project deploy resume -i $deploymentId -w 60
sf project deploy report -i $deploymentId --json > ./changedSources/deployReport.json

success=$(jq -r '.result.success' ./changedSources/deployReport.json)

echo ""
echo "success is: $success"

# ❌ Deployment failure
if [[ "$success" == "false" ]]; then
    echo "Deployment failed."

    echo "## ❌ $MODE Failed" >> $SUMMARY_FILE
    echo "" >> $SUMMARY_FILE

    echo "### 🔴 Component Errors" >> $SUMMARY_FILE
    echo '```' >> $SUMMARY_FILE
    jq -r '.result.details.componentFailures[]?.problem // empty' ./changedSources/deployReport.json >> $SUMMARY_FILE
    echo '```' >> $SUMMARY_FILE

    echo "### 🧪 Test Failures" >> $SUMMARY_FILE
    echo '```' >> $SUMMARY_FILE
    jq -r '.result.details.runTestResult.failures[]?.message // empty' ./changedSources/deployReport.json >> $SUMMARY_FILE
    echo '```' >> $SUMMARY_FILE

    exit 1
fi

# ✅ Success
echo "Deployment succeeded."

echo "## ✅ $MODE Succeeded" >> $SUMMARY_FILE
echo "- Org: $SANDBOX_NAME" >> $SUMMARY_FILE
echo "- Deployment Id: $deploymentId" >> $SUMMARY_FILE
#!/bin/bash

set -e

RESULT_DIR="pmdResults"
REPORT_FILE="$RESULT_DIR/PmdResults.txt"

mkdir -p $RESULT_DIR

echo "🔍 Running PMD scan on Apex classes..."

set +e
pmd check \
  --dir changedSources/force-app/main/default/classes \
  --rulesets ./pmd-rules.xml \
  --format text \
  --report-file $REPORT_FILE

PMD_EXIT_CODE=$?
set -e

# Summary output
echo "## 🔍 PMD Scan Results" >> $GITHUB_STEP_SUMMARY

if [[ -s $REPORT_FILE ]]; then
  echo "❌ Violations detected"
  
  echo '```' >> $GITHUB_STEP_SUMMARY
  cat $REPORT_FILE >> $GITHUB_STEP_SUMMARY
  echo '```' >> $GITHUB_STEP_SUMMARY

else
  echo "✅ No PMD violations found"
  echo "No PMD violations detected." >> $GITHUB_STEP_SUMMARY
fi

exit $PMD_EXIT_CODE
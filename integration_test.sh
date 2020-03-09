#!/bin/bash

set -euf -o pipefail
ACCOUNT_NAME=$1

RESULT=$(curl -fSsL http://$ACCOUNT_NAME-ci-poc.staging.resolver.com/)
echo "$RESULT"
echo "$RESULT" | grep -E 'Counter: \d+' > /dev/null
echo "Looks good"

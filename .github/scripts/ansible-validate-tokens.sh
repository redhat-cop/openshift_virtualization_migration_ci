#!/bin/bash

if [[ -z "${AUTOMATION_HUB_URL}" ]]; then
  echo "AUTOMATION_HUB_URL is not defined. Using default value."
  AUTOMATION_HUB_URL="https://console.redhat.com/api/automation-hub/"
fi

if [[ -z "${AUTOMATION_HUB_TOKEN}" ]]; then
  echo "AUTOMATION_HUB_TOKEN is not defined. Exiting"
  exit 1
fi

echo "Starting Token Validation..."
          
# DETECT HUB TYPE BASED ON URL
if [[ "$AUTOMATION_HUB_URL" == *"console.redhat.com"* ]]; then
    echo "Type: Red Hat SaaS (console.redhat.com)"
    echo "Action: Verifying Offline Token via SSO exchange..."

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token \
        -d grant_type=refresh_token \
        -d client_id="cloud-services" \
        -d refresh_token="$AUTOMATION_HUB_TOKEN")
        
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo "✅ Success: Red Hat Offline Token is valid."
    else
        echo "❌ Error: Token rejected by Red Hat SSO (HTTP $HTTP_CODE)."
        exit 1
    fi

else
    echo "Type: Private Automation Hub (On-Premise)"
    echo "Action: Verifying Bearer Token against $AUTOMATION_HUB_URL..."

    # Ensure URL ends with / if not present (simple cleanup)
    BASE_URL="${AUTOMATION_HUB_URL%/}"
               
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $AUTOMATION_HUB_TOKEN" \
        "$BASE_URL/v3/namespaces/?limit=1")
  
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo "✅ Success: Private Hub Token is valid."
    elif [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "403" ]]; then
        echo "❌ Error: Unauthorized. Check your Private Hub Token (HTTP $HTTP_CODE)."
        exit 1
    else
        echo "⚠️ Warning: Received HTTP $HTTP_CODE."
        echo "Expected 200 OK from $BASE_URL/v3/namespaces/"
        exit 1
    fi
fi
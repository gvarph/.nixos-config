# Declare an associative array
declare -A logColors

# Set the severity levels

logColors["INFO"]="\e[97m"     # White
logColors["TRACE"]="\e[96m"    # Cyan
logColors["DEBUG"]="\e[94m"    # Blue
logColors["WARN"]="\e[93m"     # Yellow
logColors["ERROR"]="\e[91m"    # Red
logColors["CRITICAL"]="\e[41m" # Red background
logColors["FATAL"]="\e[41m"    # Red background
resetColor="\e[0m"             # Reset to default terminal color

kubectl logs -f services/sg-microservice-chassis-svc --timestamps | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1}')
    json=$(echo "$line" | cut -d' ' -f2-)
    json_without_google_stuff=$(echo "$json" | jq -c -r 'with_entries(select(.key | contains("logging.googleapis.com") | not))')
    severity=$(echo "$json_without_google_stuff" | jq -r '.severity')
    message=$(echo "$json_without_google_stuff" | jq -r '.message')

    # Print base information
    echo -en "$timestamp\t${logColors[$severity]}$severity${resetColor}\t$message\t"

    # Print the rest of the JSON without severity and message
    jq -c 'del(.message, .severity)' <<<"$json_without_google_stuff"

done

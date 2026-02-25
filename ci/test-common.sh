# shellcheck shell=bash

# Common functional tests for Zulip, shared between Docker Compose and
# Helm CI.  Callers must set:
#   url        – base URL for the Zulip server
#   manage     – array: command to run manage.py
#   curl_opts  – array: extra curl flags (e.g. --insecure, --resolve …)

# Before any realm exists, the server returns a 404
curl "${curl_opts[@]:?}" -si "${url:?}" | grep -Ei '^HTTP/\S+ 404'

# Create a realm
"${manage[@]:?}" create_realm 'Testing Realm' admin@example.com 'Test Admin' \
    --password very-secret

# Realm exists after creation
curl "${curl_opts[@]}" -sfi "$url"

# / redirects to /login/
curl "${curl_opts[@]}" -sfi "$url" 2>&1 | grep -i "location: /login/"

# Login page has the name of the realm
curl "${curl_opts[@]}" -sfL "$url" | grep "Testing Realm"

# Authenticate
api_key=$(curl "${curl_opts[@]}" -sSX POST "$url/api/v1/fetch_api_key" \
    --data-urlencode username=admin@example.com \
    --data-urlencode password=very-secret | jq -r .api_key)

# Register an event queue
registered=$(curl "${curl_opts[@]}" -sfSX POST "$url/api/v1/register" \
    -u "admin@example.com:$api_key" \
    --data-urlencode 'event_types=["message"]')

queue_id=$(echo "$registered" | jq -r .queue_id)
last_event_id=$(echo "$registered" | jq -r .last_event_id)

# Post a message
curl "${curl_opts[@]}" -sfSX POST "$url/api/v1/messages" \
    -u "admin@example.com:$api_key" \
    --data-urlencode type=stream \
    --data-urlencode 'to="general"' \
    --data-urlencode topic=end-to-end \
    --data-urlencode 'content=End-to-end test message.'

# See the message come back over the event queue
queue=$(curl "${curl_opts[@]}" -sfSX GET -G "$url/api/v1/events" \
    -u "admin@example.com:$api_key" \
    --data-urlencode "queue_id=$queue_id" \
    --data-urlencode "last_event_id=$last_event_id")

echo "$queue" | jq -r '.events[] | .message.content' \
    | grep "End-to-end test message."

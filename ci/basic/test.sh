#!/bin/bash

set -eux
set -o pipefail

url="https://${hostname:?}"

# Starts off as a 404 until a realm exists
curl --insecure -si "$url" | grep -Ei '^HTTP/\S+ 404'

"${manage[@]:?}" create_realm 'Testing Realm' admin@example.com 'Test Admin' --password very-secret

# Realm exists after creation
curl --insecure -sfi "$url"

# HTTP redirects to HTTPS
curl -si "http://$hostname" 2>&1 | grep -i "location: $url"

# / redirects to /login/
curl --insecure -sfi "$url" 2>&1 | grep -i "location: /login/"

# Login page has the name of the realm
curl --insecure -sfL "$url" | grep "Testing Realm"

# Authenticate
api_key=$(curl --insecure -sSX POST "$url/api/v1/fetch_api_key" \
    --data-urlencode username=admin@example.com \
    --data-urlencode password=very-secret | jq -r .api_key)

# Make a queue
registered=$(curl --insecure -sfSX POST "$url/api/v1/register" \
    -u "admin@example.com:$api_key" \
    --data-urlencode 'event_types=["message"]')

queue_id=$(echo "$registered" | jq -r .queue_id)
last_event_id=$(echo "$registered" | jq -r .last_event_id)

# Post a message
curl --insecure -sfSX POST "$url/api/v1/messages" \
    -u "admin@example.com:$api_key" \
    --data-urlencode type=stream \
    --data-urlencode 'to="general"' \
    --data-urlencode topic=end-to-end \
    --data-urlencode 'content=This is a piping hot test message.'

# See the message come back over the event queue
queue=$(curl --insecure -sfSX GET -G "$url/api/v1/events" \
    -u "admin@example.com:$api_key" \
    --data-urlencode "queue_id=$queue_id" \
    --data-urlencode "last_event_id=$last_event_id")

echo "$queue" | jq -r '.events[] | .message.content' | grep "This is a piping hot test message."

exit 0

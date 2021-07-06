#!/bin/bash
#Regista cygnus como subscriber no orion
curl --location --request POST 'http://192.168.1.103:1026/v2/subscriptions/' \
--header 'fiware-service: iotsensor' \
--header 'fiware-servicepath: /' \
--header 'Content-Type: application/json' \
--data-raw '{
  "description": "Notify Cygnus of all changes",
  "subject": {
    "entities": [
      {
        "idPattern": ".*"
      }
    ]
  },
  "notification": {
    "http": {
      "url": "http://cygnus:5051/notify"
    }
  }
}'

#!/usr/bin/bash

LISTEN_ADDR="192.168.3.56"
WEBROOT=/var/www/html
SERVER_KEY=/home/ponto/server.key
SERVER_CRT=/home/ponto/server.crt


cd $WEBROOT

http_server="socat TCP4-LISTEN:80,reuseaddr stdio"
https_server="socat openssl-listen:443,reuseaddr,cert=server.crt,verify=0,fork stdio"
while :
        do
           #redirect stdin
           output=$(${http_server} | grep GET)
            exec 3<&0
            requested_page=$(echo "${output}" | sed -e 's|GET /||' -e 's/ HTTP.*$//')
            #echo "Requested page is:${requested_page}"
             echo ${requested_page}
            if [ -f "${requested_page}" ]
                then
                   #Code to send the page over the socket
                   cat ${requested_page} >&3
                else
                   #Page does not exist
                  echo "Page not found"
           fi
done

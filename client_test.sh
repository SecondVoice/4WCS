#!/bin/bash

#client.sh
#Author Sebastian Frohm

#A program to connect to a tcpserver. If no port where added, check "temp.txt" if previous session was a success, else
#+ scan a range of ports. Using tool netcat(nc).

server_ip=$1
port=$2

typeset -A config_array # init array
#Go through the config file, remove the '=' delimiter and add the settings to our array.
while read line
  do
          if echo $line | grep -F = &>/dev/null #no stdout and stderr
          then
                  varname=$(echo "$line" | cut -d '=' -f 1)
                  config_array[$varname]=$(echo "$line" | cut -d '=' -f 2-)
          fi
  done < config.cfg

  if [[ $server_ip -eq 0  ]]; then
          server_ip=${config_array[server_ip]}
  fi

#if no port where added, we will then try to find the correct one.
if [[ $port -eq 0 ]]; then
        temp_file=${config_array[temp_file]}
        if [[ ! -f "$temp_file" ]]; then
                echo "$temp_file not found creating new."
                echo touch $temp_file
        fi
        check_tempfile=$(grep -R "succeeded!" $temp_file | wc -l)
        if [[ $check_tempfile -eq 1 ]]; then
                port=$(cat $temp_file | grep "port_nr" | awk '{print $2}')
                echo "found port:$port in $temp_file"
        else
                #Scan each individual port in our port_array.
                #Put the result in a temporary file and check
                #for the word 'succeeded!', then break.
                port_start=${config_array[port_start]}
                port_end=${config_array[port_end]}
                port_array=$(seq $port_start $port_end)
                echo "No port where added, Scanning ports,"
                echo "$port_start to $port_end"
                for port in ${port_array[@]}
                do
                        $(nc -vv -z $server_ip $port > $temp_file 2>&1)
                        result=$(grep -R "succeeded!" $temp_file | wc -l)
                        if [[ $result -eq 1 ]]; then
                                echo "Found connection on port: $port"
                                echo "port_nr $port" >> $temp_file
                                break
                        fi
                done
                echo "Loop is done"
                if [[ $result -eq 0 ]]; then
                        echo "Found no connection, terminating"
                        exit 1
                fi
        fi
fi
echo "Connecting to server with IP:$server_ip Port:$port"
nc $server_ip $port

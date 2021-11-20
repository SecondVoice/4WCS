#!/bin/bash

#client.sh
#Author Sebastian Frohm

#A program to connect to a tcpserver and scan ports if needed. Using tool netcat(nc).
#You can add ip address and port directly when calling this script, else script will try to
#+find settings in client_config.cfg or the temp file or by plain ugly portscan.
#dont forget in the client_config.cfg to change temp_file=path/to/temp.txt.

server_ip=$1
port=$2
config="$(pwd)/client_config.cfg"

E_NO_CONNECTION=1 #no connection found


declare -A config_array # init an -Associative array (variable=value)

config_parser (){
#Go through the config file, line by line. If there is text in line,
#+ remove the '=' delimiter and add the fields on each side as variable=value to our array.
  while read line
    do
        if echo $line | grep -F = &>/dev/null #Just check if $line contains anything, then its TRUE.
                                               #+ dont print, throw it in the garbage bin /dev/null
        then
            varname=$(echo "$line" | cut -d '=' -f 1) #declare field 1 (before delimiter) as variable name.
            config_array[$varname]=$(echo "$line" | cut -d '=' -f 2-) #add everything after the delimiter
                                                                    # as a value to variable name.
        fi
    done < $config
  echo $config_array
}

config_parser $config_array

if [ -z "$server_ip" ]; then
    server_ip=${config_array[server_ip]}
    echo "no ip arg added, using $server_ip from config instead."
fi
if [ -z "$port" ]; then
    port=${config_array[port]}
    echo "no port arg added, using $port from config instead."
fi

temp_file=${config_array[temp_file]}
port_start=${config_array[port_start]}
port_end=${config_array[port_end]}

connect (){
    local flags=$1
    echo "connecting to server with IP:$server_ip Port:$port"
    nc -v $flags $server_ip $port

}

search_pattern () #the search for success!
{
    local pattern=$1
    local file=$2
    let local success=$(grep -R "$pattern" $file | wc -l)
    echo $success
}

connect #first attempt to connect

#if port and ip address not working, then we will then try to find the correct one.
if [[ -f "$temp_file" ]]; then #lets check the temp file for correct ip address and port.
    echo "checking tempfile: $temp_file"
    result=$(search_pattern 'succeeded!' $temp_file)
    if [[ $result -eq 1 ]]; then
        port=$(cat $temp_file | grep "port_nr" | awk '{print $2}')
        server_ip=$(cat $temp_file | grep "ip_nr" | awk '{print $2}')
        echo "found ip_address: $server_ip port:$port"
        connect
    fi

fi
#if no temporary file or previous result is false or previous connection failed then scan!
if [[ ! -f "$temp_file" ]] || [[ $result -eq 0 ]] || [[ $? -eq 1 ]]; then
            #Scan each individual port in our port array.
            #Put the result in a temporary file and check
            #for the word 'succeeded!', then break.
            echo "No port where added, Scanning ports,"
            echo "$port_start to $port_end"
            port_array=$(seq $port_start $port_end)
            for port in ${port_array[@]}
            do
                $(nc -vv -z $server_ip $port > $temp_file 2>&1)
                result=$(search_pattern 'succeeded!' $temp_file)
                if [[ $result -eq 1 ]]; then
                    echo "Found an open port: $port"
                    echo "writing changes to: $temp_file"
                    echo "port_nr $port" >> $temp_file
                    echo "ip_nr $server_ip" >> $temp_file
                    break
                fi
            done
            if [[ $result -eq 0 ]]; then
                echo "Found no connection, terminating"
                exit $E_NO_CONNECTION
            else
                connect
            fi
fi
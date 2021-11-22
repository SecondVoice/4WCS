#!/bin/bash
  
#client.sh
#Author Sebastian Frohm

#A program to connect to a server and scan ports if needed. Using tool netcat(nc).
#You can add ip address and port directly when calling this script, else script will try to
#+find settings in client_config.cfg or the temp file or by plain ugly portscan.
#dont forget in the client_config.cfg to change temp_file=path/to/temp.txt.

server_ip=$1
port=$2
config="$(pwd)/client_config.cfg"
E_NO_CONNECTION=1 #no connection found

declare -A config_array # init an -Associative array (variable=value)

config_parser ()
{
#Go through the config file, line by line. If there is text in line,
#+ remove the '=' delimiter and add the fields on each side as variable=value to our array.
  while read line
    do
	    if echo "$line" | grep = &>/dev/null #Just check if $line contains anything.
                                               #Don't print, redirect to garbage bin /dev/null 
	    then
            varname=$(echo "$line" | cut -d '=' -f 1) #declare field 1 (before delimiter) as variable name.
		    config_array[$varname]=$(echo "$line" | cut -d '=' -f 2-) #Add field 2 and beyond
                                                                      #+ as a value to variable name.
	    fi
    done < $config
  echo $config_array
}

config_parser $config_array

if [[ -z "$server_ip" ]]; then
    server_ip=${config_array[server_ip]}
    echo "no ip arg added, using $server_ip from ${config##*/}." #skip full path, just filename.
fi
if [[ -z "$port" ]]; then
    port=${config_array[port]}
    echo "no port arg added, using $port from ${config##*/}."
fi

temp_file=${config_array[temp_file]}
port_start=${config_array[port_start]}
port_end=${config_array[port_end]}

connect () # connect with netcat(nc)
{
    local flags=$1
    echo "connecting to server with IP:$server_ip Port:$port"
    $(echo nc -v $flags $server_ip $port)

}

search_pattern () #the search for success!
{
    local pattern=$1
    local file=$2
    let local success=$(grep "$pattern" $file | wc -l) #return linenumber.
    echo $success
}


connect #first attempt to connect

#If port and ip address not working, then we will then try to find the correct one.
if [[ -f "$temp_file" ]]; then #lets check the temp file for correct ip address and port.
    echo "checking tempfile: ${temp_file##*/}"
    result=$(search_pattern 'succeeded!' $temp_file)
    if [[ $result -eq 1 ]]; then
        port=$(grep "port_nr" $temp_file | cut -d ' ' -f 2)
        server_ip=$(grep "ip_nr" $temp_file | cut -d ' ' -f 2)
        echo "found ip_address: $server_ip port:$port"
        connect
    fi
    
fi

#If no temporary file or previous result is false or previous connection failed then scan!
#Scan each individual port in our port array. Put the result in a temporary file and check
#+for the word 'succeeded!', then break.

if [[ ! -f "$temp_file" || $result -eq 0 || $? -eq 1 ]]; then
    echo "Scanning ports $port_start to $port_end with ip: $server_ip"
    port_array=$(seq $port_start $port_end)
    for port in ${port_array[@]}
    do
        $(nc -v -z $server_ip $port &> $temp_file) #stdout and stderr to file.
        result=$(search_pattern 'succeeded!' $temp_file)
        if [[ $result -eq 1 ]]; then
            echo "Found an open port: $port"
            echo "writing changes to: $temp_file" 
            echo "port_nr $port" >> $temp_file
            echo "ip_nr $server_ip" >> $temp_file
            break
        fi
    done
	if [[ $result -eq 1 ]]; then
        connect
    else
        echo "Found no connection, terminating"
        exit $E_NO_CONNECTION
    fi
fi

#!/bin/bash
  
#config_parser.sh
#Author Sebastian Frohm

#A program to parse configfiles to an array.
#create an empty array (typeset -A array_name) before using function 'config_parser()'


config=/path/to/config.cfg
E_NO_PARAMS=1 #no parameters added

#display msg if no params added
use(){
	echo "Add a filepath to configuration: /file/path"
	exit ${E_NO_PARAMS}
}


config_parser(){
	#Go through the config file, remove the '=' delimiter and add the settings to our array.
	while read line
	do
		if echo $line | grep -F = &>/dev/null #no stdout and stderr 
		then
			varname=$(echo "$line" | cut -d '=' -f 1)
			config_array[$varname]=$(echo "$line" | cut -d '=' -f 2-)
		fi
	done < $path

  echo $config_array
  #echo $config
  #exit 0
}

#if no arguments do use()
[ $# -eq 0 ] && use

typeset -A config_array # initiate our config array.
config_parser $config_array

#server_ip=${config_array[server_ip]}
#temp_file=${config_array[temp_file]}
#port_start=${config_array[port_start]}
#port_end=${config_array[port_end]}


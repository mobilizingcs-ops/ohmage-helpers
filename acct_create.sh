#!/bin/bash
## Ohmage 2.13 Account Creation Script
## Steve Nolen
### This script takes input from user and generates user accounts.

#abstracted curl command, use -ksd if SSL cert is wrong. **this is a hack!**
curl="curl -ksd"

##################
####USER INPUT####
##################
read -p "Server: " servername
read -p "Admin Username: " admin_user
read -sp "Admin Password: " admin_pass
echo ""
	#grab a token for the user
    json=`$curl "user=$admin_user&password=$admin_pass&client=curl" https://$servername/app/user/auth_token`
    	if [[ "$json" == *success* ]]
    	then
    		echo "Success: Authenticated"
    		token=`echo $json | awk -F"\"" '/token/{print $(NF-1)}'`
    	else
    		echo "Error: Failed to Authenticate"
    		echo $json
    		exit
    	fi
read -p "Base User ID (for lausd.xxxx, enter lausd): " baseuser
read -p "Number of users to create: " numusers
read -p "Class URN (defaults to urn:class:public): " classurn
	#check if classurn was set
	if [ -z "$classurn" ]
	then
  		class=urn:class:public
	else
  		class=$classurn
	fi
	z=${#numusers} #make sure we have prepending zeros to make usernames pretty.
	#make ohmage_created file if it doesn't exist
	if [ ! -f ohmage_created ]
	then
		echo class,user,pass >> ohmage_created
	fi

##########################
####ACCT CREATION LOOP####
##########################
COUNTER=0
while [ $COUNTER -lt $numusers ]; do
	zeros=`printf "%0${z}d" $COUNTER`
	user=$baseuser.$zeros
	pass=`curl -s http://makeagoodpassword.com/password/simple/ | sed 's/././5' | awk '{print toupper(substr($0,0,1))substr($0,2)}'`
	#curl to create user
	a=`$curl "auth_token=$token&username=$user&password=$pass&client=curl&admin=false&enabled=true&new_account=false&campaign_creation_privilege=false" https://$servername/app/user/create`
	if [[ "$a" == *success* ]]
		then
			b=`$curl "auth_token=$token&client=curl&class_urn=$class&user_role_list_add=$user;restricted" https://$servername/app/class/update`
			if [[ "$b" == *success* ]]
				then
					echo "Success: Added "$user
					echo $class,$user,$pass >> ohmage_created
				else
					echo "Error: Failed to add "$user" to "$class
					echo $b
					exit
			fi		
		else
			echo "Error: Failed to add "$user
			echo $a
			exit
	fi
	COUNTER=$[ $COUNTER + 1 ]
done
echo "Success: Created accounts"
exit

#!/bin/bash
## Steve Nolen
### Script that will add a defined campaign to a number of classes

#abstracted curl command, use -ksd if SSL cert is wrong. **this is a hack!**
curl="curl -sd"
client="curl"

if [ $1 ]
 then
  class_list_file=$1
 else
  echo "Please pass the file with your class list as argument 1, exiting..."
  exit
fi

if [ $2 ]
 then
  xml_file=$2
  campaign_urn_subject=$(echo ${xml_file%.xml} | tr '[:upper:]' '[:lower:]')
  campaign_subject=${xml_file%.xml}
 else
  echo "Please pass the file with your xml as argument 2, exiting..."
  exit
fi

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
echo ""
while read class_urn
do 
 echo "Working on $class_urn ..."
 #expects class urn to match "urn:class:lausd:2014:fall:schoolname:teachername:subject:p0"
 year=$(echo $class_urn | cut -f4 -d:)
 semester_lower=$(echo $class_urn | cut -f5 -d:)
 semester="$(tr '[:lower:]' '[:upper:]' <<< ${semester_lower:0:1})${semester_lower:1}"
 period_lower=$(echo $class_urn | cut -f9 -d:)
 period="$(tr '[:lower:]' '[:upper:]' <<< ${period_lower:0:1})${period_lower:1}"
 teacher_name_lower=$(echo $class_urn | cut -f7 -d:)
 teacher_name="$(tr '[:lower:]' '[:upper:]' <<< ${teacher_name_lower:0:1})${teacher_name_lower:1}"
 campaign_name="$campaign_subject $period $teacher_name $year $semester"
 campaign_urn=${class_urn/class/campaign}":$campaign_urn_subject"
 create=`curl -F "auth_token=$token" -F "client=$client" -F "running_state=running" -F "privacy_state=shared" -F "class_urn_list=$class_urn" -F "xml=@$xml_file;type=text/xml" -F "campaign_name=$campaign_name" -F "campaign_urn=$campaign_urn" https://$servername/app/campaign/create`
  if [[ "$create" == *success* ]]
    then
      echo "$campaign_urn added to $class_urn"
    else
      echo "$create"
  fi
done < "$class_list_file"
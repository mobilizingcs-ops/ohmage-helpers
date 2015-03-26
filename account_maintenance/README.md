# Account maintenance scripts
A few helper scripts to ease some ohmage account maintenance annoyances.

## users_from_csv.rb
Populates a class with generated users based on their personal info in a csv file.
#### Arguments
  * path to csv file (currently requires that **no header be present** and ordered as first_name,last_name,email_address)
  * urn of pre-existing class to add users to (will add them as restricted)
  * base of random username (defaults to `lausd-` if 3rd argument is not found)
 
#### Returns
Created accounts with personal info are returned to STDOUT. Feel free to pipe this to an actual csv file if you wish!

#### Example
```bash
# first set environment variables based on the server you want to use:
export OHMAGE_SERVER_URL = 'https://test.mobilizingcs.org/'
export OHMAGE_USER = 'testuser'
export OHMAGE_PASSWORD = 'testpass'
ruby user_from_csv.rb /path/to/file.csv urn:class:public ucla-
```
will create accounts like `ucla-58679` in class urn:class:public (which usually exists as a default on ohmage servers) for each line listed in /path/to/file.csv

## acct_create.rb
Generates a bunch of users with supplied base. Useful for one-off studies where coordinators will train users. 
#### Arguments
None. Script will prompt for inputs
 
#### Returns
Created accounts are returned to STDOUT in a 'csv' format.

#### Example
```bash
# first set environment variables based on the server you want to use:
export OHMAGE_SERVER_URL = 'https://test.mobilizingcs.org/'
export OHMAGE_USER = 'testuser'
export OHMAGE_PASSWORD = 'testpass'
ruby acct_create.rb
```
will help you create some accounts!

## acct_create.sh (deprecated)
Generates a bunch of users with supplied base. Useful for one-off studies where coordinators will train users. Please note this was written for bsd bash and curl, and thusly has some fantasicly weird hacks. If you have any access to ruby, it is far preferred that you use the above ruby scripts.
#### Arguments
None. Script will prompt for inputs
 
#### Returns
Created accounts are dropped in a file `ohmage_created` in csv format to the current directory.

#### Example
```bash
./acct_create.sh
```
will help you create some accounts!
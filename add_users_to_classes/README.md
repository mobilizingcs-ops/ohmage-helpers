# Add list of users to classes
note: requires ohmage gem version `0.0.9` (requires class/search api support.)

## add_list_to_classes.rb
Appends a group of users to a class list matching regex on line 5.
#### Arguments
  * [edit script directly] array of users on line 4
  * [edit script directly] regular expression to match class urns.

#### Returns
exits with nil if no changes were made. Returns string like "Added users to classes: [comma-separated class urn list]" (check comments to enable sending to syslog)

#### Why??/How??
This script is useful for mobilize since there is a set of non-admin users who always need to have access to deployment data. The example would add 3 users (with usernames user1, user2 and user3) to any class that contained the regex (an example would be urn:class:mobilize:2015:spring or urn:class:mobilize:2014:fall).
To execute, make sure you've filled out an **admin's** account in the ohmage config block and run via cron!

# Ohmage/RStudio Helpers
A set of scripts used to facilitate the (dreadfully awkward) integration of ohmage and rstudio needed for the [IDS](https://wiki.mobilizingcs.org/ids) curriculum. note: requires [ohmage gem](github.com/ohmage/gem) and ruby. Install using `gem install ohmage`. 

## per_class_history_databases.rb
Searches an ohmage server for a list of classes (with optional ignore list) and creates a mapping in the file system which copies student history database files into a per-class directory. This script is really intended for a specific purpose, so please do edit to your needs (if you could possibly need to do this). The source is thoroughly annotated!

#### Arguments (edit script directly)
  * `search_param` ohmage class/search call has return limited by this param
  * `exclude_list` an array of class urns to exclude from the return
  * `acct_matcher` a string to limit the matched accounts
  * `replace_in_class` some crazy regexp to facilitate anonymizing teacher name in class urn
  * `base_dir` location to store the directories of history databases.

#### Returns
A set of directories (one per matched class) named according to the above arguments containing text files matching each found user's rstudio history_database!

#### Why??/How??
These history databases can be used for analysis of student actions throughout the IDS curriculum, but knowing the class/teacher/student relationship is quite a bit more powerful than just having a single directory of all the files!

## account_sync.rb
Queries an ohmage database for distinct username/password hashes, checks for changes (new users, hashes that don't match the current hash) against a small [Daybreak](https://github.com/propublica/daybreak) database and push those changes to local linux accounts on a remote box.

#### Arguments (edit script directly)
  * `mysql_(host,user,password,db)` credentials for mysql server
  * `mysql_user_query` returns a distinct list of username, password hash combos you need to sync. Note that you should avoid usernames that don't conform to linux local account standards (eg. no period(.) in username)
  * `daybreak_db_file` location of the db file for persistence
  * `ssh_(host,user,password,port)` ssh box to send user/pass updates to.

#### Returns
A log of how many new and changed users were operated on. Stick this in a crontab and go!

#### Why??/How??
As of this implementation, ohmage does not support external authentication and RStudio server pro version is required for nice external auth features. To reduce the friction of students logging in to RStudio, we've opted to periodically replicate the users found in ohmage to the linux local accounts on the rstudio vm. Please don't ever use this, it is a pretty awful stop-gap! :)

#### Deps
Just in case you do use this (above, I explicitly told you not to) you'll need to resolve some dependencies.  Make sure the remote system has `newusers` and `chpasswd` utils installed. Additionally, the remote system needs to have `libpam-unix2` installed to support the use of the blowfish hashes used in ohmage. Furthermore, don't use libpam-unix2 2.6 as it's broken. The project is now dead but you can grab the .deb file from [here](https://packages.debian.org/wheezy/admin/libpam-unix2).

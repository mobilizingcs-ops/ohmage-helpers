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

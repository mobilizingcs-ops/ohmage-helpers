# add_campaign_to_classes.rb

This script will create a version of a campaign for each class matched. Given:
  * an campaign xml file on disk
  * regex to match ohmage class urns found on this particular server
  * A campaign name to use for this campaign.  Please keep this short, memorable and without special characters.

You can also adjust the regex of the name/urn matchers to fit a pattern unlike the one we happen to be using (check out the file for an example of our name/urns and how the file gets matched.)

If you happen to request the use of an xml file that has a `<campaignName>` or `<campaignUrn>` tag, the script will die and ask you to remove them.

# add_campaign_to_class.sh

** A legacy shell script to awkwardly and buggily do this **

This script will take two arguments on the command line to add the second argument (a campaign xml file) to a set of classes (a file with one class urn per line).

Please note:
  * Argument 1 should have no content save for the urns, one per line (with a final newline). 
  * Classes must already exist on the server in question as well as have the format `urn:class:org:2014:fall:teachername:subject:p0` or the script must be modified accordingly.
  * Argument 2 should be named as you wish the generated campaign names to be, eg. for a campaign name to be "DiningOut" please name the file `DiningOut.xml` (no spaces allowed as this value is also used in the campaign urn).
  * The campaign xml file should not contain the keys `<campaignUrn>` or `<campaignName>` as these will be derived from the class list.
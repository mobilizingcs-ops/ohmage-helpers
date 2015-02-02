# Add single campaign to many classes
This script will take two arguments on the command line to add the second argument (a campaign xml file) to a set of classes (a file with one class urn per line).

Please note:
  * Argument 1 should have no content save for the urns, one per line (with a final newline). 
  * Classes must already exist on the server in question as well as have the format `urn:class:org:2014:fall:teachername:subject:p0` or the script must be modified accordingly.
  * Argument 2 should be named as you wish the generated campaign names to be, eg. for a campaign name to be "DiningOut" please name the file `DiningOut.xml` (no spaces allowed as this value is also used in the campaign urn).
  * The campaign xml file should not contain the keys `<campaignUrn>` or `<campaignName>` as these will be derived from the class list.
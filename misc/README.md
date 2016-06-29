# Misc scripts
A set of scripts or script-stems that have no real other group.  Some to generate some data, some to override portions of the ohmage gem to speed up generation etc etc.

## fast_campaign_creation.rb
After a successful campaign create using the `oh.campaign_create` method, a subsequent request is made to `oh.campaign_read` with the campaign parameters to ensure that the method return is a `Ohmage::Campaign` object. This shows how to hook in to `Ohmage::Request` manually to make the requests when a formal object return isn't needed.  Note that this can be used as a reference for creation of lots of different ohmage objects similarly: campaigns, classes, users, documents.

## create_campaign_upload_data.rb
A quick way to generate a super simple campaign and upload a piece of data to it.  This is great for testing server functionality as it handles campaign creation, class modification, survey upload (and because the survey includes a photo, it ensures that ohmage can save a file to disk). Line #51 needs to be adjusted to be a valid path to an image.

## batch_add_campaigns.rb
Assuming you have the https://github.com/mobilizingcs/teacher source checked out (and modify line #12 accordingly) this allows you to quickly add Mobilize pre-created campaigns in a batch to a class.
#!/usr/bin/env ruby

require 'ohmage'
require 'oga'

#  * The location of the campaign you wish to add to many classes.
#  * The regex used to match classes you'll add the campaign to
#  * The regex used to capture part of the class name to use as the campaign name
#  * The regex used to capture part of the class urn to use as the campaign urn
#
# Modify as needed. This script will generate a new campaign matching
# the name/urn of the class to make the campaign have a unique, memorable
# name.
#
campaign = '/Users/steve/scratch/FreeTime.xml'
campaign_name = 'FreeTime'
class_match_regex = Regexp.new(/lausd:2015:fall:.*?:.*?:math/)
match_class_name = Regexp.new(/.*? (.*)/) # Math P1 TeacherName 2015 Fall
match_class_urn = Regexp.new(/urn:class:(.*)/) # urn:class:lausd:2015:fall:school:teachername:math:p1

# First, ensure the campaign doesn't have <campaignName or <campaignUrn> tags
# This is needed since we will pass them and ohmage doesn't like when you do both.
file_handler = File.open(campaign)
campaign_xml = Oga.parse_xml(file_handler)
unless campaign_xml.xpath('campaign/campaignName').empty? && campaign_xml.xpath('campaign/campaignUrn').empty?
  p 'Your xml has <campaignName> or <campaignUrn> tags. Please remove them and retry'
  abort
end

# Grab all the classes, and then filter out the ones that don't match our regex.
all_classes = oh.class_search()
match_classes = []
all_classes.each do |c|
  match_classes << c if class_match_regex.match(c.urn)
  next
end

match_classes.each do |c|
  match_name = match_class_name.match(c.name)
  match_urn = match_class_urn.match(c.urn)
  urn = "urn:campaign:" + match_urn[1] + ":" + campaign_name.delete(' ').downcase
  name = campaign_name + " " + match_name[1]

  oh.campaign_create(running_state: "running", 
                     privacy_state: "shared", 
                     class_urn_list: c.urn, 
                     xml: campaign_file,
                     campaign_urn: urn,
                     campaign_name: name)

  p "made class with urn: #{campaign_urn} and name: #{campaign_name} attached to #{c.urn}"
end





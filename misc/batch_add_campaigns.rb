require 'ohmage'

# set up the ohmage gem to use your server creds
oh = Ohmage.client do |conf|
  conf.server_url = ENV['OHMAGE_SERVER_URL']
  conf.user = ENV['OHMAGE_USER']
  conf.user = ENV['OHMAGE_PASSWORD']
end

# loops around all of the campaign names you want to add.
['Trash', 'TimePerception', 'PersonalityColor', 'FoodHabits', 'StressChill', 'TimeUse'].each do |x|
  @file = "/Users/steve/git/frontends/teacher/xml/#{x}.xml" #path to the teacher tool source https://github.com/mobilizingcs/teacher
  @urn = "urn:campaign:idspd2016:#{x}"  
  oh.campaign_create(running_state: "running", privacy_state: "shared", class_urn_list: "urn:class:idspd2016", xml: @file, campaign_urn: @urn, campaign_name: x) 
end
require 'ohmage'

# create ohmage client to use for account creation. feel free to change this however you please.
# doing this so I can check it in to source code.
oh = Ohmage.client do |conf|
  conf.server_url = ENV['OHMAGE_SERVER']
  conf.user = ENV['OHMAGE_USER']
  conf.user = ENV['OHMAGE_PASSWORD']
end

##### fast campaign creation when return is not needed

# valid ohmage campaign xml
campaign_file = '/path/to/campaign.xml'

500.times do |i|
  params = {xml: HTTP::FormData::File.new(campaign_file), running_state: 'running', privacy_state: 'private', class_urn_list: 'urn:class:test:500campaigns', campaign_urn:   "urn:campaign:test:500campaigns:#{i}", campaign_name: "500 campaigns #{i}"}
  request = Ohmage::Request.new(oh, :post, 'campaign/create', params)
  request.perform
  p i
end

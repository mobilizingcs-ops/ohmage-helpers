require 'ohmage'
begin
  require 'oga'
rescue LoadError
  p "gem 'oga' is required for this script to run. Please execute `gem install oga` and re-run"
  abort
end
abort unless Ohmage::Version.to_s >= '0.0.26' # xml parsing feature added in this version.

oh = Ohmage::Client.new() # assumes your env is chock full of ohmage admin creds!
campaigns = oh.campaign_search()
p "Checking #{campaigns.count} campaigns on #{oh.server_url} for malformed single_choice and multi_choice prompts..."

malformed_campaigns = []
campaigns.each do |campaign|
  @error = 0
  campaign.xml.xpath('campaign/surveys/survey/contentList/prompt').each do |prompt|
    if prompt.at_xpath('promptType').text == 'single_choice' || prompt.at_xpath('promptType').text == 'multi_choice'
      if prompt.xpath('properties/property').count < 1
        @error += 1
      end
    end
  end
  malformed_campaigns << campaign.urn if @error > 0
end

if malformed_campaigns.count > 0
  p "Malformed Campaigns found: "
  malformed_campaigns.each {|c| p c }
else
  p "No errors found!"
end

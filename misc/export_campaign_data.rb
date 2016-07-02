require 'ohmage'
require 'ruby-progressbar'

# create ohmage client to use for account creation. feel free to change this however you please.
# doing this so I can check it in to source code.
oh = Ohmage.client do |conf|
  conf.server_url = ENV['OHMAGE_SERVER']
  conf.user = ENV['OHMAGE_USER']
  conf.user = ENV['OHMAGE_PASSWORD']
end

p "Grabbing all the campaigns (this may take a moment)"
campaigns = oh.campaign_search()

base_dir = '/path/to/export/location/'
progress = ProgressBar.create(:title => "Downloading campaign data", :starting_at => 0, :total => c.count)
c.each do |x|
  @urn = x.urn.gsub(":","_")
  @csv = base_dir + @urn + '.csv'
  @photo_zip = base_dir + @urn + '_photos.zip'
  File.open(@csv, 'w') do |f|
    f << oh.survey_response_read(campaign_urn: x.urn, output_format: 'csv')
  end
  File.open(@photo_zip, 'w') do |f|
    request = Ohmage::Request.new(oh, :get, 'image/batch/zip/read', {campaign_urn: x.urn, user_list: 'urn:ohmage:special:all', survey_id_list: "urn:ohmage:special:all"})
    f << request.perform
  end
  progress.increment
end

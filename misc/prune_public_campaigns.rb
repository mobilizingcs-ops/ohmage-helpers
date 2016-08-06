#!/bin/env ruby
# a script to prune unused campaigns from the public class

require 'ohmage'
require 'oga' # assumes xml parser is available
require 'zip'
require 'mailgun'

# just to make the month calculations a little less cumbersome.
DAYS_IN_MONTH = 30
DAYS_IN_WEEK = 7
TO_DELETE = (3 * DAYS_IN_MONTH)
TO_WARN = (2 * DAYS_IN_MONTH) + (3 * DAYS_IN_WEEK)
NINE_MONTHS = (9 * DAYS_IN_MONTH)

today = DateTime.now
nine_months_ago = today.to_date - NINE_MONTHS
age_to_warn = today.to_date - TO_WARN
age_to_delete = today.to_date - TO_DELETE

# mailgun api
mg_client = Mailgun::Client.new ENV['MAILGUN_API']
mg_domain = ENV["MAILGUN_DOMAIN"]


# set up the ohmage gem to use your server creds
oh = Ohmage.client do |conf|
  conf.server_url = ENV['OHMAGE_SERVER_URL']
  conf.user = ENV['OHMAGE_USER']
  conf.user = ENV['OHMAGE_PASSWORD']
end

default_campaigns = [
                      "urn:campaign:mobilize:sample:snack",
                      "urn:campaign:mobilize:sample:media",
                      "urn:campaign:mobilize:sample:trash",
                      "urn:campaign:mobilize:sample:height",
                      "urn:campaign:mobilize:sample:nutrition_v2"
                    ]

# retrieves email address of arbitrary user.
def return_user_email(username, client)
  user_list = client.user_search(username: username)
  user_list.first.email_address || nil
end

# first, we grab campaign objects for all campaigns attached to the public class
public_campaigns = oh.campaign_read(class_urn_list: oh.server_config[:public_class_id], output_format: 'long')

# reject default campaigns
public_campaigns.delete_if {|campaign| default_campaigns.include? campaign.urn}

# reject all campaigns with responses newer than 9 months old
public_campaigns.delete_if do |c|
  # get counts by state, map values to array, sum.
  @response_count = c.instance_variable_get("@survey_response_count").values.inject(0, :+)
  # if count is greater than 0, check if any are newish.
  @newish_response_count = 0
  @newish_response_count = oh.survey_response_read(campaign_urn: c.urn, start_date: nine_months_ago.strftime("%F %T")).count if @response_count > 0
  @newish_response_count > 0
end

# reject campaigns created less than 2m,3 weeks ago
public_campaigns.delete_if do |c|
  @creation_date = DateTime.parse(c.creation_timestamp)
  @creation_date > age_to_warn
end

public_campaigns.each do |c|
  #@author_email = oh.user
  @creation_date = DateTime.parse(c.creation_timestamp)
  if @creation_date < age_to_delete
    p "#{c.urn} will be deleted"
    @response_count = c.instance_variable_get("@survey_response_count").values.inject(0, :+)
    if @response_count > 0 
      # EXPORT RESPONSES AS CSV
      csv = Tempfile.open("ohmage") do |f|
        f << oh.survey_response_read(campaign_urn: c.urn, output_format: 'csv')
      end
      # read through each prompt to see if there are any media prompts
      @media_prompt = false
      c.xml.xpath('campaign/surveys/survey/contentList/prompt').each do |prompt|
        # TODO: add cases for other media types. will need to download these individually
        @media_prompt = true if prompt.at_xpath('promptType').text == 'photo'
      end
      # EXPORT PHOTO PROMPTS AS BATCH ZIP
      if @media_prompt
        photo_zip = Tempfile.open('ohmage') do |f|
          request = Ohmage::Request.new(oh, :get, 'image/batch/zip/read', {campaign_urn: c.urn, user_list: 'urn:ohmage:special:all', survey_id_list: "urn:ohmage:special:all"})
          f << request.perform
        end
      end       
    end
    # DUMP XML TO FILE
    xml = Tempfile.open("ohmage") do |f|
      f << c.xml.to_xml
    end

    # zip 'em all up!
    zipfile_name = "/tmp/#{c.urn.gsub(":","_")}.zip"
    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      zipfile.add("responses.csv", csv.path) if @response_count > 0 
      zipfile.add("campaign.xml", xml.path)
      zipfile.add("photos.zip", photo_zip.path) if @media_prompt
    end

    # upload to documents tab. don't share this to the user since it will have extra private responses.
    p "Uploading exported campaign to ohmage server"
    oh.document_create(document_name: "#{c.urn.gsub(":","_")}.zip", privacy_state: 'private', document_class_role_list: 'urn:class:admin;reader', document: zipfile_name)
    p "Sending deletion email for #{c.urn}"
    deletion_email = %Q(Thanks so much for using our sandbox to test out your participatory sensing campaign.  In order to keep the system simple for all to use, your created campaign \"#{c.name}\" has been deleted from our system due to inactivity for an extended period of time.

Attached you will find the XML used to generate the campaign, so that you may easily upload the campaign to this or another ohmage server to continue collecting data.

Thanks so much and as always, please feel free to contact us with questions!
Mobilize Support (help@mobilizingcs.org)
)

    del_obj = Mailgun::MessageBuilder.new
    del_obj.from("noreply@mobilizingcs.org", {"first"=>"Mobilize", "last" => "Support"})
    del_obj.add_recipient(:to, return_user_email(c.user_role_campaign[:author].first, oh))
    del_obj.subject("Your test campaign on sandbox.mobilizingcs.org has been deleted")
    del_obj.body_text(deletion_email)
    del_obj.add_attachment(xml.path, "#{c.urn.gsub(":","_")}.xml")
    mg_client.send_message(mg_domain, del_obj)

    # TODO: delete it
  else
    p "Sending warning email for #{c.urn}"
    warn_email  = %Q(Thanks so much for using our sandbox to test out your participatory sensing campaign.  In order to keep the system simple for all to use, your created campaign \"#{c.name}\" is scheduled for deletion in one week due to inactivity for an extended period of time.  

Please take this time to export any data you'd like to maintain by visiting the campaigns tab of the web frontend:
https://sandbox.mobilizingcs.org/#campaigns

Thanks so much and as always, please feel free to contact us with questions!
Mobilize Support (help@mobilizingcs.org)
)

    warn_obj = Mailgun::MessageBuilder.new
    warn_obj.from("noreply@mobilizingcs.org", {"first"=>"Mobilize", "last" => "Support"})
    warn_obj.add_recipient(:to, return_user_email(c.user_role_campaign[:author].first, oh))
    warn_obj.subject("Your test campaign on sandbox.mobilizingcs.org will be deleted soon")
    warn_obj.body_text(warn_email)
    mg_client.send_message(mg_domain, warn_obj)

  end
end
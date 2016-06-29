#gems we need
require 'ohmage'
require 'SecureRandom' unless defined?(SecureRandom)

# check if you have a version of the ohmage gem that will work with this
abort unless Ohmage::Version.to_s >= '0.0.19'

# first set up the client
oh = Ohmage::Client.new() # assumes env has necessary variables

# make sure ohmage.admin is in public class
oh.class_update(class_urn: 'urn:class:public', user_role_list_add: 'ohmage.admin;privileged')

# create a single prompt campaign. note 'photo1' is skippable.
urn = 'urn:campaign:photo:test2'
name = 'Photo Test'
xml = '<?xml version="1.0" encoding="UTF-8"?>
<campaign>
    <surveys>
        <survey>
            <id>photo</id>
            <title>photo</title>
            <description>photo description</description>
            <submitText>Thanks</submitText>
            <anytime>true</anytime>
            <contentList>
                <prompt>
                    <promptType>photo</promptType>
                    <id>photo1</id>
                    <displayLabel>photo1</displayLabel>
                    <promptText>take a photo</promptText>
                    <skippable>true</skippable>
                    <skipLabel>Skip</skipLabel>
                    <properties>
                        <property>
                            <key>maxDimension</key>
                            <label>800</label>
                        </property>
                    </properties>
                </prompt>
            </contentList>
        </survey>
    </surveys>
</campaign>'
photo_campaign = oh.campaign_create(running_state: 'running', privacy_state: 'shared', class_urn_list: 'urn:class:public', campaign_urn: urn, campaign_name: name, xml: xml)
photo_campaign = photo_campaign.first # oh.campaign_read always returns an array.

# upload a response to it
survey_uuid = SecureRandom.uuid()
image_uuid = SecureRandom.uuid()
image_location = '/path/to/image.jpg'
oh.survey_upload(campaign_creation_timestamp: photo_campaign.creation_timestamp,
                 campaign_urn: photo_campaign.urn,
                surveys: [{survey_key: survey_uuid,
                            location_status: 'unavailable',
                            time: 1434046871000,
                            timezone: 'America/Los_Angeles',
                            survey_id: 'photo',
                            survey_launch_context: {
                              launch_time: 1434046871000,
                              launch_timezone: 'America/Los_Angeles',
                              active_triggers: []
                            },
                            responses: [
                                        {prompt_id: 'photo1', value: image_uuid}
                                       ]
                          }
                         ].to_json,
                image_uuid => image_location
              )
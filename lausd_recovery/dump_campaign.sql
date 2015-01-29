## check lee's campaigns : server location: 131.179.144.232

##### store procedure to dump campaign data 
# mysql -e "SELECT * FROM database.tableName;" -u user -p database > filename.csv
# given a campaign_id, dump all survey responses related to the id 
DROP PROCEDURE IF EXISTS dump_campaign; 
DELIMITER $$
CREATE PROCEDURE dump_campaign(IN from_campaign_id INT)
BEGIN
  SET @campaign_file:=CONCAT("'/tmp/campaign_", from_campaign_id, ".txt'");
  SET @response_file:=CONCAT("'/tmp/survey_response_", from_campaign_id, ".txt'");
  SET @url_file:=CONCAT("'/tmp/url_based_resource_", from_campaign_id, ".txt'");
  SET @prompt_file:=CONCAT("'/tmp/prompt_response_", from_campaign_id, ".txt'"); 

  set @q0:=CONCAT("
  select *
  INTO OUTFILE ", @campaign_file, 
   " FIELDS TERMINATED BY '\\t' OPTIONALLY ENCLOSED BY '\\\'' ESCAPED BY '\\\\'
  LINES TERMINATED BY '\\n'
  FROM campaign
  WHERE id = ", from_campaign_id);

  select @q0;
  prepare s0 from @q0;
  execute s0;deallocate prepare s0;

  # survey_response
  set @q1:=CONCAT("
  select id, user_id, campaign_id, client, epoch_millis, phone_timezone, survey_id, survey, 
    launch_context, location_status, location, upload_timestamp, last_modified_timestamp, privacy_state_id, uuid
  INTO OUTFILE ", @response_file, 
   " FIELDS TERMINATED BY '\\t' OPTIONALLY ENCLOSED BY '\\\'' ESCAPED BY '\\\\'
  LINES TERMINATED BY '\\n'
  FROM survey_response
  WHERE campaign_id = ", from_campaign_id);

  select @q1;
  prepare s1 from @q1;
  execute s1;deallocate prepare s1;

  # prompt responses
  set @q2:=CONCAT("
  select p.id, p.survey_response_id, p.prompt_id, p.prompt_type, 
     p.repeatable_set_id, p.repeatable_set_iteration, p.response, 
     p.audit_timestamp
  INTO OUTFILE ", @prompt_file, 
   " FIELDS TERMINATED BY '\\t' OPTIONALLY ENCLOSED BY '\\\'' ESCAPED BY '\\\\'
  LINES TERMINATED BY '\\n'
  FROM survey_response join prompt_response p on (survey_response.id = p.survey_response_id)
  WHERE survey_response.campaign_id = ", from_campaign_id);

  select @q2; 
  prepare s2 from @q2;
  execute s2;deallocate prepare s2;

  # images
  set @q3:=CONCAT("
  select u.id, u.user_id, u.client, u.uuid, 
    u.url, u.audit_timestamp, u.processed
  INTO OUTFILE ", @url_file, 
   " FIELDS TERMINATED BY '\\t' OPTIONALLY ENCLOSED BY '\\\'' ESCAPED BY '\\\\'
  LINES TERMINATED BY '\\n'
  FROM survey_response join prompt_response on (survey_response.id = prompt_response.survey_response_id) 
    join url_based_resource u on (prompt_response.response = u.uuid)
  WHERE prompt_response.prompt_type = 'photo'
    and survey_response.campaign_id = ", from_campaign_id);

  select @q3;
  prepare s3 from @q3;
  execute s3;deallocate prepare s3;

END$$
DELIMITER ;

## -------------------------------------------------------------------------



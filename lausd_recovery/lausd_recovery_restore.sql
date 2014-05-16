# Restore the data from the exported tables. 
# Assuming the exported files are in /tmp/ dir. 
# Main concept: set new_id = old_id + offset. The offset is determined
# by the number of entries that were added to the db after the last_id.
# Since we know the new id, the script will make sure that all FK are 
# consistent..
#
# 1. set the appropriate last ids from exported table.
# 

SET @last_response_id = 30719; 
select @offset:= (max(id) - @last_response_id) from survey_response;

# Manually identify the last audit entry that was backed up. 
SET @last_audit_id = 3342474;
select @audit_offset:= (max(id) - @last_audit_id) from audit;

SET @last_stream_data_id = 34623139;
select @stream_offset:= (max(id) - @last_stream_data_id) from observer_stream_data;

#ignore foreign_key_checks
#SET foreign_key_checks = 0
# disable indexing
#ALTER TABLE survey_response DISABLE KEYS 
#ALTER TABLE survey_response ENABLE KEYS 

# 2. load the exported files into the DB
# -----------------------------
# survey responses
# -----------------------------

LOAD DATA INFILE '/tmp/survey_response.txt' 
INTO TABLE survey_response 
CHARACTER SET 'utf8'
FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
  (@old_id, user_id, campaign_id, client, epoch_millis, phone_timezone, survey_id, 
   survey, launch_context, location_status, location, upload_timestamp, 
   last_modified_timestamp, privacy_state_id, uuid)
SET id = @old_id + @offset; 

LOAD DATA INFILE '/tmp/url_based_resource.txt' 
INTO TABLE url_based_resource
CHARACTER SET 'utf8'
FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
  (@old_id, user_id, client, uuid, url, audit_timestamp, processed);


LOAD DATA INFILE '/tmp/prompt_response.txt' 
INTO TABLE prompt_response 
CHARACTER SET 'utf8'
FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
  (@old_id, @old_response_id, prompt_id, prompt_type, 
   repeatable_set_id, repeatable_set_iteration, 
   response, audit_timestamp)
SET survey_response_id = @old_response_id + @offset;

# ---------------------
# audit related tables
# ---------------------

LOAD DATA INFILE '/tmp/audit.txt' 
INTO TABLE audit
CHARACTER SET 'utf8'
FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
  (@old_id, request_type_id, uri, client, request_id, 
   device_id, response, received_millis, respond_millis, 
   db_timestamp);

LOAD DATA INFILE '/tmp/audit_parameter.txt' 
INTO TABLE audit_parameter
CHARACTER SET 'utf8'
FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
  (@old_id, @old_audit_id, param_key, param_value)
SET audit_id = @old_audit_id + @audit_offset;

LOAD DATA INFILE '/tmp/audit_extra.txt' 
INTO TABLE audit_extra
CHARACTER SET 'utf8'
FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
  (@old_id, @old_audit_id, extra_key, extra_value)
SET audit_id = @old_audit_id + @audit_offset;

# -----------------------
# observer table
# -----------------------

LOAD DATA INFILE '/tmp/observer_stream_data.txt' 
INTO TABLE observer_stream_data
CHARACTER SET 'utf8'
FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
  (@old_id, user_id, observer_stream_link_id, uid, 
   time, time_offset, time_adjusted, time_zone, 
   location_timestamp, location_latitude, location_longitude, 
   location_accuracy, location_provider, data, last_modified_timestamp)
SET id = @old_id + @stream_offset;









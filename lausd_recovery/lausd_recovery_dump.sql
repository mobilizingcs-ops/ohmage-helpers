# extract relevant data to be restored. This has to be done manually. 
# There are 4 steps involved: 
# 1. check dependency of tables to be exported. 
# 2. Identify last id of tables to be exported (e.g. the last_id that 
#    get backed up).
# 3. set the paramters for those last ids. 
# 4. export those tables.

# -- 1. check dependency on tables to export
use INFORMATION_SCHEMA;

select TABLE_NAME,COLUMN_NAME,CONSTRAINT_NAME,
  REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME 
from KEY_COLUMN_USAGE 
where
  REFERENCED_TABLE_NAME = 'survey_response' 

# survey_response: survey_response, prompt_response, url_based_resource 
# audit: audit, audit_parameter, audit_extra
# observer: observer_data_stream

# -- 2. identify last id of tables to be exported. 
# This process has to be done manually!!
#
# identify the last survey response 
# the last survey response is 30719 upload_timestamp = 2014-05-12 00:15:39
select id, client, upload_timestamp, last_modified_timestamp
from survey_response 
where upload_timestamp > "2014-05-12 01:00:01"
order by upload_timestamp desc 
limit 10;

# identify the last id of url_based_resource
# the last id is 15906
select *
from url_based_resource
where audit_timestamp  > "2014-05-12 01:00:01"
order by audit_timestamp 
limit 20;

# checking audit table related entries
# last audit id = 3342474 , 12305 items
select id, client, uri, db_timestamp, count(*)
from audit 
where db_timestamp > "2014-05-12 01:19:00";
#where id > 3342474

# 77100 audit_parameter items
select id, audit_id, count(*)
from audit_parameter 
where audit_id > 3342474;

# 133917 audit_extra items
select id, audit_id, count(*)
from audit_extra
where audit_id > 3342474;

select id, user_id, observer_stream_link_id, last_modified_timestamp
from observer_stream_data
where last_modified_timestamp > "2014-05-12 01:15:01"
limit 50;
#| 34623139 | 2309 | 11 | 110ea41d-5571-4729-a241-141186890e28 | 1399879012191 | 2014-05-12 01:16:57     |
#| 34623232 | 4824 | 13 | 4acee6e2-38b5-470c-89c3-4e9de253179d | 1399875889855 | 2014-05-12 01:20:52     |

# -- 3. set the paramters for those last ids
SET @last_response_id = 30719;
SET @last_url_based_resource_id = 15906;
SET @last_audit_id = 3342474;
SET @last_observer_stream_data_id = 34623139;

# -- 4. export tables 
# -------------------------------------
# grp1: survey responses related tables
# ------------------------------------
select *
INTO OUTFILE '/tmp/survey_response.txt'
  FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
from survey_response
where id > @last_response_id;  #30719

select *
INTO OUTFILE '/tmp/prompt_response.txt'
  FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
from prompt_response
where survey_response_id > @last_response_id;

select *
INTO OUTFILE '/tmp/url_based_resource.txt'
  FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
from url_based_resource
where id > @last_url_based_resource_id; #15906

# -----------------------------
# grp2: audit related tables
# -----------------------------
select *
INTO OUTFILE '/tmp/audit.txt'
  CHARACTER SET 'utf8'
  FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
from audit
where id > @last_audit_id; #3342474

select *
INTO OUTFILE '/tmp/audit_parameter.txt'
  CHARACTER SET 'utf8'
  FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
from audit_parameter
where audit_id > @last_audit_id; #3342474

select *
INTO OUTFILE '/tmp/audit_extra.txt'
  CHARACTER SET 'utf8'
  FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
from audit_extra
where audit_id > @last_audit_id; #3342474

# -------------------------------
# grp3: observer related tables
# -------------------------------
select * 
INTO OUTFILE '/tmp/observer_stream_data.txt'
  CHARACTER SET 'utf8'
  FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\'' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
from observer_stream_data
where id > @last_observer_stream_data_id; 


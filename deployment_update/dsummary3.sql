# ---------- dsummary_helper --------
# depending on the parameters, generate proper regular expression to check for inclusion and exclusion. 
# no longer need these excluding after classes were renamed!
#    SET @exclude_urns:='2014:.*shattuck:science.*|2014.*Morris.*P1|2014.*Torres.*P1|2014.*Torres.*P5|2014.*Torres.*P8|2014.*Dimonaco.*P3|2014.*Granados.*P1|2014.*Granados.*P3';
#    SET @exclude_urns:=concat(@exclude_urns,'|2013.*Schlipp_P3|2013.*Gomez_P[2-9]|2013.*Ho|2013.*Shepard');
#    SET @exclude_urns:=concat(@exclude_urns,'|Roosevelt.*ECS_P4.*');
DROP PROCEDURE IF EXISTS dsummary_helper;
DELIMITER $$
CREATE PROCEDURE dsummary_helper (
     IN semester VARCHAR(25), IN subject VARCHAR(25), IN list_all INT,
     OUT include_urns VARCHAR(256), OUT exclude_urns VARCHAR(256))
BEGIN
  DECLARE new_subject VARCHAR(25) DEFAULT subject;
  SET exclude_urns:=' ';

  IF (list_all = 0) THEN 
    SET exclude_urns:=concat(exclude_urns,'|Mobilize');
  END IF;

  IF (semester = 'all' OR semester = '') THEN       
      SET include_urns:=':lausd:.*';
  ELSE
      SET include_urns:=CONCAT(':lausd:.*', semester, '.*');
  END IF;

  SET new_subject:=REPLACE(lower(subject), "ecs", "ecs|seminar");
  IF (subject != 'all') THEN 
    SET include_urns:=CONCAT(include_urns, '(', new_subject, ').*');
  END IF; 

  IF (subject = "mobilize") THEN 
    SET include_urns:=CONCAT(':mobilize.*', semester, '.*');
    SET exclude_urns:=" ";
  END IF; 
     
END$$
DELIMITER ;

# ---------- dsummary --------
# show a deployment status summary of each class including 
# - total number of campaigns, # of active campaigns (i.e. campaigns with at least 1 response)
# - number of shared and all survey responses associated with campaigns assigned to the class 
#   These numbers include responses done by teachers and others. It should be consistent with 
#   what reported on the campaign monitoring page
# - last submission, data collection duration 
# - total number of students, and # of active students in the classes
# The table is sorted based on URN
# CALL dsummary('2013:spring', 'science', 1);
DROP PROCEDURE IF EXISTS dsummary;
DELIMITER $$
CREATE PROCEDURE dsummary (
       IN semester VARCHAR(25), IN subject VARCHAR(25), IN list_all INT)
BEGIN
  call dsummary_helper(semester, subject, list_all, @include_urns, @exclude_urns); 

SET @rank=0;
select @rank:=@rank+1 as 'Rank', 
  t.cname as 'Class', t.num_campaigns as 'TotCp', 
  IF(t5.active_campaigns IS NULL, 0, t5.active_campaigns) as 'ActCp',
  t.shared as 'Shared', t.total as 'Total', 
  IF(t.uts IS NULL, '-', DATE_FORMAT(t.uts,'%m-%d-%y %H:%i')) as 'LastResponse', 
  IF(t.duration IS NULL, '-', round(t.duration,1)) as 'Dur.days', 
#  round(t.upload_duration,1) as 'Upload Duration',  
  t5.nusers as 'ActStd', t5.total as 'TotStd', round(t5.nusers*100/t5.total,1) as '%Active'
from (
  # - total campaigns, survey response statistics of campaign data (all users)
  select 
    class.id as cid, class.urn as curn, class.name as cname, 
    IF(campaign_class.id IS NULL, 0, count(DISTINCT campaign_class.campaign_id)) as num_campaigns,
    sum(IF(survey_response.privacy_state_id = 1, 1,0)) as shared,
    count(survey_response.id) as total,     
    max(survey_response.upload_timestamp) as uts,  
    (max(epoch_millis) - min(epoch_millis))/1000/3600/24 as duration
#   TIMESTAMPDIFF(DAY, min(survey_response.upload_timestamp),max(survey_response.upload_timestamp)) as duration
#   (UNIX_TIMESTAMP(max(upload_timestamp))-UNIX_TIMESTAMP(min(upload_timestamp)))/3600/24 as upload_duration
  from class left join campaign_class on (class.id = campaign_class.class_id)
    left join survey_response on campaign_class.campaign_id = survey_response.campaign_id   
  where class.urn rlike @include_urns
    and class.urn not rlike @exclude_urns
  group by class.id
#  order by total desc, class.urn
  order by class.urn, total desc
  ) as t 
left join 
(
  # - get number of total students and actuve students for all class campaigns
  select t2.cid as cid, t2.curn, t2.total as total, 
    IF(t4.nusers IS NULL, 0, t4.nusers) as nusers, 
    IF(t4.active_campaigns IS NULL, 0, t4.active_campaigns) as active_campaigns 
  from
  (
    # - total students. Some students are in multiple classes
    select class.id as cid, class.urn as curn, count(*) as total
    from class join user_class on (class.id = user_class.class_id)
         join user on (user.id = user_class.user_id)
    where 
      class.urn rlike @include_urns
      and class.urn not rlike @exclude_urns
      and user.username rlike 'lausd.*|^[0-9].*'
      and user_class.user_class_role_id = 2
    group by class.id
    # -end total students
  ) as t2  
  left join 
  ( 
    # - unique students in specic classes that participate in class campaigns
    # - active_campaigns, shared and total are ignored since it only reports those that are done by students in the class 
    select class.id as cid, class.urn as curn, count(distinct user.id) as nusers,
      IF(campaign_class.id IS NULL, 0, count(DISTINCT campaign_class.campaign_id)) as active_campaigns, 
      sum(IF(survey_response.privacy_state_id = 1, 1,0)) as shared,
      count(survey_response.id) as total
    from class join campaign_class on (class.id = campaign_class.class_id) 
      join survey_response on (campaign_class.campaign_id = survey_response.campaign_id)
      join user on (survey_response.user_id = user.id)
      join user_class on (user_class.user_id = user.id and user_class.class_id = class.id)
    where 
      class.urn rlike @include_urns
      and class.urn not rlike @exclude_urns
      and user.username rlike 'lausd.*|^[0-9].*'
      and user_class.user_class_role_id = 2
    group by class.id 
  # -end number of active users
  ) as t4 on t2.cid = t4.cid
) as t5 on t.cid = t5.cid,
(SELECT @rank:=0) t6;

END$$
DELIMITER ;


# ----------- top15classes ----------------------
# Provide the same information as dsummary but the list is sorted based on total number of responses. 
# The output is sorted based on the # of survey responses

DROP PROCEDURE IF EXISTS top15classes;
DELIMITER $$
CREATE PROCEDURE top15classes (
       IN semester VARCHAR(25), IN subject VARCHAR(25), IN list_all INT)
BEGIN

  call dsummary_helper(semester, subject, list_all, @include_urns, @exclude_urns); 

SET @rank=0;
select @rank:=@rank+1 as 'Rank', 
  t.cname as 'Class', t.num_campaigns as 'TotCp', 
  IF(t5.active_campaigns IS NULL, 0, t5.active_campaigns) as 'ActCp',
  t.shared as 'Shared', t.total as 'Total', 
  IF(t.uts IS NULL, '-', DATE_FORMAT(t.uts,'%m-%d-%y %H:%i')) as 'LastResponse', 
  IF(t.duration IS NULL, '-', round(t.duration,1)) as 'Dur.days', 
#  round(t.upload_duration,1) as 'Upload Duration',  
  t5.nusers as 'ActStd', t5.total as 'TotStd', round(t5.nusers*100/t5.total,1) as '%Active'
from (
  # - total campaigns, survey response statistics of campaign data (all users)
  select 
    class.id as cid, class.urn as curn, class.name as cname, 
    IF(campaign_class.id IS NULL, 0, count(DISTINCT campaign_class.campaign_id)) as num_campaigns,
    sum(IF(survey_response.privacy_state_id = 1, 1,0)) as shared,
    count(survey_response.id) as total,     
    max(survey_response.upload_timestamp) as uts,  
    (max(epoch_millis) - min(epoch_millis))/1000/3600/24 as duration
#   TIMESTAMPDIFF(DAY, min(survey_response.upload_timestamp),max(survey_response.upload_timestamp)) as duration
#   (UNIX_TIMESTAMP(max(upload_timestamp))-UNIX_TIMESTAMP(min(upload_timestamp)))/3600/24 as upload_duration
  from class left join campaign_class on (class.id = campaign_class.class_id)
    left join survey_response on campaign_class.campaign_id = survey_response.campaign_id   
  where class.urn rlike @include_urns
    and class.urn not rlike @exclude_urns
  group by class.id
  order by total desc, class.urn limit 15
#  order by class.urn, total desc
  ) as t 
left join 
(
  # - get number of total students and actuve students for all class campaigns
  select t2.cid as cid, t2.curn, t2.total as total, 
    IF(t4.nusers IS NULL, 0, t4.nusers) as nusers, 
    IF(t4.active_campaigns IS NULL, 0, t4.active_campaigns) as active_campaigns 
  from
  (
    # - total students. Some students are in multiple classes
    select class.id as cid, class.urn as curn, count(*) as total
    from class join user_class on (class.id = user_class.class_id)
         join user on (user.id = user_class.user_id)
    where 
      class.urn rlike @include_urns
      and class.urn not rlike @exclude_urns
      and user.username rlike 'lausd.*|^[0-9].*'
      and user_class.user_class_role_id = 2
    group by class.id
    # -end total students
  ) as t2  
  left join 
  ( 
    # - unique students in specic classes that participate in class campaigns
    # - active_campaigns, shared and total are ignored since it only reports those that are done by students in the class 
    select class.id as cid, class.urn as curn, count(distinct user.id) as nusers,
      IF(campaign_class.id IS NULL, 0, count(DISTINCT campaign_class.campaign_id)) as active_campaigns, 
      sum(IF(survey_response.privacy_state_id = 1, 1,0)) as shared,
      count(survey_response.id) as total
    from class join campaign_class on (class.id = campaign_class.class_id) 
      join survey_response on (campaign_class.campaign_id = survey_response.campaign_id)
      join user on (survey_response.user_id = user.id)
      join user_class on (user_class.user_id = user.id and user_class.class_id = class.id)
    where 
      class.urn rlike @include_urns
      and class.urn not rlike @exclude_urns
      and user.username rlike 'lausd.*|^[0-9].*'
      and user_class.user_class_role_id = 2
    group by class.id 
  # -end number of active users
  ) as t4 on t2.cid = t4.cid
) as t5 on t.cid = t5.cid,
(SELECT @rank:=0) t6;
#  order by t.total desc, t.curn limit 15

END$$
DELIMITER ;


# ---------- dsummary_campaign --------
# show a deployment status summary of each class
# - campaign name
# - number of shared and all survey responses associated with campaigns assigned to the class 
#   These numbers include responses done by teachers and others. It should be consistent with 
#   what reported on the campaign monitoring page
# - last submission, data collection duration 
# - total number of students, and # of active students in the classes
# The table is sorted based on URN
DROP PROCEDURE IF EXISTS dsummary_campaign;
DELIMITER $$
CREATE PROCEDURE dsummary_campaign (
       IN semester VARCHAR(25), IN subject VARCHAR(25), IN list_all INT)
BEGIN

  call dsummary_helper(semester, subject, list_all, @include_urns, @exclude_urns); 

SET @rank=0;
select @rank:=@rank+1 as 'Item', 
  t.cname as 'Class', #t.num_campaigns as 'TotCp', 
  SUBSTRING_INDEX(t.cpname, ' ', 2) as 'Campaign',
  t.shared as 'Shared', 
  t.total as 'Total', 
  IF(t.uts IS NULL, '-', DATE_FORMAT(t.uts,'%m-%d-%y %H:%i')) as 'LastResponse', 
  IF(t.duration IS NULL, '-', round(t.duration,1)) as 'Dur.days', 
#  round(t.upload_duration,1) as 'Upload Duration',
  IF(t3.nusers IS NULL, 0, t3.nusers) as 'ActStd', 
  IF(t2.total IS NULL, 0, t2.total) as 'TotStd', 
  IF(t2.total IS NULL, '-', round(IF(t3.nusers IS NULL, 0, t3.nusers)*100/t2.total,1)) as '%Active'
from (
  # - total campaigns, survey response statistics of campaign data (all users)
  select 
    class.id as cid, class.urn as curn, class.name as cname, 
    campaign_class.campaign_id as cpid, campaign.name as cpname,
    sum(IF(survey_response.privacy_state_id = 1, 1,0)) as shared,
    count(survey_response.id) as total,     
    max(survey_response.upload_timestamp) as uts,  
    (max(epoch_millis) - min(epoch_millis))/1000/3600/24 as duration
#   TIMESTAMPDIFF(DAY, min(survey_response.upload_timestamp),max(survey_response.upload_timestamp)) as duration
#   (UNIX_TIMESTAMP(max(upload_timestamp))-UNIX_TIMESTAMP(min(upload_timestamp)))/3600/24 as upload_duration
  from class left join campaign_class on (class.id = campaign_class.class_id)
    left join campaign on (campaign.id = campaign_class.campaign_id)
    left join survey_response on campaign_class.campaign_id = survey_response.campaign_id   
  where class.urn rlike @include_urns
    and class.urn not rlike @exclude_urns
  group by campaign_class.campaign_id
  order by class.urn, campaign.name #, total desc
  ) as t 
left join 
(
    # - total students. Some students are in multiple classes
  select class.id as cid, class.urn as curn, count(*) as total
    from class join user_class on (class.id = user_class.class_id)
         join user on (user.id = user_class.user_id)
    where 
      class.urn rlike @include_urns
      and class.urn not rlike @exclude_urns
      and user.username rlike 'lausd.*|^[0-9].*'
      and user_class.user_class_role_id = 2
    group by class.id
    # -end total students
) as t2 on (t.cid = t2.cid)
left join 
( 
    # - unique students that participates in specific class campaigns
    # - active_campaigns, shared and total are ignored since it only reports those that are done by students in the class 
    select class.id as cid, class.urn as curn, 
      count(distinct user.id) as nusers,
      IF(campaign_class.id IS NULL, NULL, campaign_class.campaign_id) as cpid,
      sum(IF(survey_response.privacy_state_id = 1, 1,0)) as shared,
      count(survey_response.id) as total
    from class join campaign_class on (class.id = campaign_class.class_id) 
      join survey_response on (campaign_class.campaign_id = survey_response.campaign_id)
      join user on (survey_response.user_id = user.id)
      join user_class on (user_class.user_id = user.id and user_class.class_id = class.id)
    where 
      class.urn rlike @include_urns
      and class.urn not rlike @exclude_urns
      and user.username rlike 'lausd.*|^[0-9].*'
      and user_class.user_class_role_id = 2
    group by campaign_class.campaign_id 
  # -end number of active users
) as t3 on (t3.cid = t.cid and t3.cpid = t.cpid),
(SELECT @rank:=0) t4;

END$$
DELIMITER ;



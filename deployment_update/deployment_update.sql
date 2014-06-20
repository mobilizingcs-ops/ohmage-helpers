# the scripts for deployment update

# --------------------- Previous Script --------------- 
# class response summary without user info
SET @rank=0;
select @rank:=@rank+1 as "Order", t.cn as "Campaign", t.shared as "Shared", t.total as "Total", t.time as "Last Response", floor(t.duration) as "Collection Period (days)"
from (
  select campaign.name as cn, campaign.urn as curn, 
    sum(case when survey_response.privacy_state_id = 1 then 1 else 0 end) as shared,
    count(survey_response.id) as total,     
    max(survey_response.upload_timestamp) as time,  
    (max(epoch_millis) - min(epoch_millis))/1000/3600/24 as duration
  from campaign left join survey_response on campaign.id = survey_response.campaign_id          
  where campaign.urn like "%lausd:2014:spring:%:science:%" 
    and campaign.urn not like "%:shattuck:science:%"
  group by campaign.name   
  order by total desc, curn) as t, 
(SELECT @rank:=0) t2;

#----------------------------- campaign centric ------------------------
# class responses + user info
# This script is campaign centric. If a class has multiple campaign, it will not work. 
SET @rank=0;
SET @include_urns="%lausd:2014:spring:%:ecs:%";
SET @exclude_urns="%Landa%";
select @rank:=@rank+1 as "Rank", t.cn as "Campaign", t.shared as "Shared", t.total as "Total", 
  t.time as "Last Response", floor(t.duration) as "Duration (days)", 
  t5.nusers as "Active Users", t5.total as "Total Users" 
from (
  select campaign.id as cid, campaign.name as cn, campaign.urn as curn, 
    sum(case when survey_response.privacy_state_id = 1 then 1 else 0 end) as shared,
    count(survey_response.id) as total,     
    max(survey_response.upload_timestamp) as time,  
    (max(epoch_millis) - min(epoch_millis))/1000/3600/24 as duration
  from campaign left join survey_response on campaign.id = survey_response.campaign_id   
  where campaign.urn like @include_urns
    and campaign.urn not like @exclude_urns
  group by campaign.name   
#  order by total desc, curn
  order by curn
  ) as t 
left join (
  # get number of total users and current users for each campaign
  select t2.cid as cid, t2.total as total, case when t4.nusers IS NULL then 0 else t4.nusers end as nusers
  from
  (
    # total users
    select campaign.id as cid, class.id, class.urn, count(*) as total
    from campaign_class join class on campaign_class.class_id = class.id
      join campaign on campaign_class.campaign_id = campaign.id
      join user_class on class.id = user_class.class_id
      join user on user_class.user_id = user.id
    where 
      campaign.urn like @include_urns
      and campaign.urn not like @exclude_urns
      and user.username rlike "lausd.*|^[0-9].*"
    group by campaign.id
  ) as t2  
  left join 
  ( # number current active users
    select t3.cid as cid, count(*) as nusers
    from (
      select campaign.id as cid, survey_response.user_id as user_id, count(*) as count
        from 
          campaign join survey_response on campaign.id = survey_response.campaign_id 
          join user on user.id = survey_response.user_id
        where campaign.urn like @include_urns
        and campaign.urn not like @exclude_urns
        and user.username rlike "lausd.*|^[0-9].*"
      group by survey_response.user_id
    ) as t3
    group by t3.cid
  ) as t4 on t2.cid = t4.cid
) as t5 on t.cid = t5.cid,
(SELECT @rank:=0) t6;

# ---------------------Y4:Science deployment updates --------------- 
# class responses + user info + number of campaigns 
# class-based instead of campaign-based as above 
# Note: duration is calculated based on upload_timestamp instead of response ts (due to inaccurate clocks on the phones)
# TODO: Need to change the current script in lausd)

# ECS
#SET @include_urns:="%lausd:2014:spring:%:ecs:%";
#SET @exclude_urns:="";
# Science
SET @include_urns:="%lausd:2014:spring:%:science:%";
SET @exclude_urns:="%:shattuck:science:%";
SET @rank=0;
select @rank:=@rank+1 as "Rank", 
  t.cname as "Class", t.num_campaigns as "#Campaigns", 
  t.shared as "Shared", t.total as "Total", 
  t.uts as "Last Response", 
  round(t.duration,1) as "Duration (days)", 
#  round(t.upload_duration,1) as "Upload Duration",  
  t5.nusers as "Active Users", t5.total as "Total Users" 
from (
  select 
    class.id as cid, class.name as cname, 
    IF(campaign_class.id IS NULL, 0, count(DISTINCT campaign_class.campaign_id)) as num_campaigns,
    sum(IF(survey_response.privacy_state_id = 1, 1,0)) as shared,
    count(survey_response.id) as total,     
    max(survey_response.upload_timestamp) as uts,  
    (max(epoch_millis) - min(epoch_millis))/1000/3600/24 as duration
#   TIMESTAMPDIFF(DAY, min(survey_response.upload_timestamp),max(survey_response.upload_timestamp)) as duration
#   (UNIX_TIMESTAMP(max(upload_timestamp))-UNIX_TIMESTAMP(min(upload_timestamp)))/3600/24 as upload_duration
  from class left join campaign_class on (class.id = campaign_class.class_id)
    left join survey_response on campaign_class.campaign_id = survey_response.campaign_id   
  where class.urn like @include_urns
    and class.urn not like @exclude_urns
  group by class.id
  order by total desc, class.urn
  ) as t 
left join 
(
  # get number of total users and current users for each campaign
  select t2.cid as cid, t2.curn, t2.total as total, 
    IF(t4.nusers IS NULL, 0, t4.nusers) as nusers
  from
  (
    # -total users. some students are in multiple classes
    select class.id as cid, class.urn as curn, count(*) as total
    from class join user_class on (class.id = user_class.class_id)
         join user on (user.id = user_class.user_id)
    where 
      class.urn like @include_urns
      and class.urn not like @exclude_urns
      and user.username rlike "lausd.*|^[0-9].*"
#      and user_class.user_class_role_id = 2
    group by class.id
    # -end total users
  ) as t2  
  left join 
  ( 
  # -number of active users in specic classes
  select t3.cid as cid, t3.curn as curn, count(*) as nusers
  from (
    # unique users in specic classes that participate in class campaigns
    select class.id as cid, class.urn as curn, user.id
    from class join campaign_class on (class.id = campaign_class.class_id) 
      join survey_response on (campaign_class.campaign_id = survey_response.campaign_id)
      join user on (survey_response.user_id = user.id)
    where 
      class.urn like @include_urns
      and class.urn not like @exclude_urns
      and user.username rlike "lausd.*|^[0-9].*"
    group by class.id, user.id
    ) as t3
  group by t3.cid
  # -end number of active users
  ) as t4 on t2.cid = t4.cid
) as t5 on t.cid = t5.cid,
(SELECT @rank:=0) t6;


# number of science classes
select count(*) 
from class 
where class.urn like "%lausd:2014:spring:%:science:%" 
    and class.urn not like "%:shattuck:science:%"

# number of shared and private responses
select 
  sum(case when privacy_state_id = 1 then 1 else 0 end) as "Shared",
  sum(case when privacy_state_id = 2 then 1 else 0 end) as "Private",
  count(*) as total
from survey_response



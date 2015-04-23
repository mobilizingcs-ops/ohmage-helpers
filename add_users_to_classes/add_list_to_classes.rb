#!/usr/bin/env ruby
require 'ohmage'

users = %w(user1 user2 user3)
class_match = Regexp.new(/:mobilize:(2014|2015|2016):(fall|spring)/)

oh = Ohmage::Client.new do |conf|
  conf.user = 'admin-here'
  conf.password = 'password-here'
  conf.server_url = 'https://servername-here/'
end

# grab a full class list
all_classes = oh.class_search()

# find classes that match regex from above
matching_classes = []
all_classes.each do |c|
  matching_classes << c if class_match.match(c.urn)
  next
end

# from matching class subset, grab only classes that are missing a user from the list
users = users.sort # ensure our users are in order.
update_classes = []
matching_classes.each {|x| update_classes << x.urn unless x.usernames.sort & users == users}

# add user list to classes matched above
unless update_classes.empty?
  user_role_list_add = users.join(';privileged,') + ';privileged' #haha.
  update_classes.each do |uc|
    oh.class_update(class_urn: uc, user_role_list_add: user_role_list_add)
  end 
  puts "Added users to classes: #{update_classes.join(', ')}"
end

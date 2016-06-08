#!/usr/bin/env ruby
require 'ohmage'
require 'http'
require 'csv'
require 'ruby-progressbar'

# assume no headers for now
csv = CSV.read(ARGV[0])
urn = ARGV[1]
base = ARGV[2] || 'lausd-'

# csv order
csv_id = 0
csv_first = 1
csv_last = 2
csv_email = 3
csv_org = 4

def gen_password
  resp = HTTP.public_send(:get, 'http://makeagoodpassword.com/password/simple')
  resp.body.to_s
end

# create ohmage client to use for account creation. feel free to change this however you please.
# doing this so I can check it in to source code.
oh = Ohmage.client do |conf|
  conf.server_url = ENV['OHMAGE_SERVER_URL']
  conf.user = ENV['OHMAGE_USER']
  conf.user = ENV['OHMAGE_PASSWORD']
end

# grab list of users that match this base on the system, keep only usernames
users = oh.user_read(username_search: base)
users = users.collect { |u| u.username }

created_users = []
# read the arrays from the csv:
#  generate a username,password for each user, then add personal info to acct.
# a fancy progress bar since this process can take a bit of time.
progress = ProgressBar.create(:title => "Creating Accounts", :starting_at => 0, :total => csv.count)
csv.each do |u|
  # find a non-existent username for this user
  begin
    @username = base + rand(00000..99999).to_s.rjust(5, '0')
    raise "Username is not unique" if users.include? @username
  rescue
    retry # if generated user already exists, re-run that last block.
  end
  @password = gen_password
  oh.user_create(username: @username, password: @password, admin: false, enabled: true, new_account: true)
  oh.user_update(username: @username, first_name: u[csv_first], last_name: u[csv_last], email_address: u[csv_email], personal_id: u[csv_id], organization: u[csv_org], class_creation_privilege: true, user_setup_privilege: true)
  created_users << {username: @username, password: @password, first_name: u[csv_first], last_name: u[csv_last], email: u[csv_email]}
  progress.increment
end

# add them all to a class in a bulk call.
users_to_class = created_users.collect { |u| u[:username] }
user_role_list_add = users_to_class.join(';restricted,') + ';restricted'
oh.class_update(class_urn: urn, user_role_list_add: user_role_list_add)

# csv to stdout so it can be copied (or piped to a file)
puts 'first_name,last_name,email,username,password'
created_users.each do |u|
  puts "#{u[:first_name]},#{u[:last_name]},#{u[:email]},#{u[:username]},#{u[:password]}"
end

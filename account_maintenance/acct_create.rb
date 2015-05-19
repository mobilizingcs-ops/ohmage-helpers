require 'ohmage'
require 'http'

def prompt(*args)
    print(*args)
    gets
end

def gen_password
  resp = HTTP.public_send(:get, 'http://makeagoodpassword.com/password/simple')
  resp.body.to_s
end


# create ohmage client to use for account creation. feel free to change this however you please.
# doing this so I can check it in to source code.
oh = Ohmage.client do |conf|
  conf.server_url = ENV['OHMAGE_SERVER']
  conf.user = ENV['OHMAGE_USER']
  conf.user = ENV['OHMAGE_PASSWORD']
end

# prompt for some inputs. 
base = prompt "Base user ID (for lausd-xxxxx, enter lausd-): "
count = prompt "Number of users to create: "
urn = prompt "Class URN to add users to (urn:class:public if empty): "

urn = 'urn:class:public' if urn.empty?
digits = count.to_s.size
created_users = []

count.times do |i|
  @username = base + i.to_s.rjust(digits, '0')
  @password = gen_password
  created_users << {username: @username, password: @password}
  oh.user_create(username: @username, password: @password, enabled: true, new_account: true, admin: false)
end

# add users to class all at once
users_to_class = created_users.collect { |u| u[:username] }
user_role_list_add = users_to_class.join(';restricted,') + ';restricted'
oh.class_update(class_urn: urn, user_role_list_add: user_role_list_add)

# csv to stdout so it can be copied (or piped to a file)
puts 'username,password'
created_users.each do |u|
  puts "#{u[:username]},#{u[:password]}"
end
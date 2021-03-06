require 'ohmage'
require 'http'
require 'ruby-progressbar'

def prompt(*args)
    print(*args)
    gets.chomp
end

def gen_password
  resp = HTTP.public_send(:get, 'http://makeagoodpassword.com/password/simple')
  resp.body.to_s.delete(' ')
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
starting_number = prompt "Number to start with (0 if left blank): "

urn = 'urn:class:public' if urn.empty?
starting_number = 0 if starting_number.empty?
count = count.to_i
digits = count.to_s.size
starting_number = starting_number.to_i

created_users = []

progress = ProgressBar.create(:title => "Creating Accounts", :starting_at => 0, :total => count)
count.times do |i|
  @num = i + starting_number
  @username = base + @num.to_s.rjust(digits, '0')
  @password = gen_password
  created_users << {username: @username, password: @password}
  oh.user_create(username: @username, password: @password, enabled: true, new_account: true, admin: false)
  progress.increment
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
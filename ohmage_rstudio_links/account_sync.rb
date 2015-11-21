#!/bin/ruby

require 'mysql2'
require 'daybreak'
require 'net/ssh'
require 'syslog'


# ohmage mysql location, user/pass source
mysql_host = '192.168.99.100'
mysql_user = 'root'
mysql_password = 'badpassword'
mysql_db = 'ohmage'
# all users from this query will be created. remove usernames that don't conform to unix standards.
mysql_user_query = 'select distinct user.username,user.password from user where username not like "%.%"'
# a sample crazy one!
# mysql_user_query = 'select distinct user.username,user.password from user join user_class on user.id=user_class.user_id where enabled=1 AND username not like "%.%" AND (user_class.class_id in (select id from class where urn like "%account_policy%" or urn like "%IDS%" or urn like "%ids%")) or (username like "%mobilize-%") or (username like "%guest-%");'

# flat file db to hold sync password state
daybreak_db_file = "account_sync.db"

# remote server to sync user/pass to. 
ssh_host = '192.168.99.100'
ssh_user = 'root'
ssh_password = 'docker'
ssh_port = 2222

# open db connections
db = Daybreak::DB.new daybreak_db_file
mysql = Mysql2::Client.new(:host => mysql_host, :username => mysql_user, :password => mysql_password, :database => mysql_db)

new_users = [] # array of new users to sync
changed_users = [] # array of users with changed passwords to sync
begin
  mysql.query(mysql_user_query).each do |x|
    @username = x['username']
    @password = x['password']
    if !db.keys.include? @username # if user is not in db, assume they are new.
      db[@username] = x 
      new_users.push(x)
    else
      if db[@username]['password'] != @password # if password hashes don't match, set new password to be synced.
        changed_users.push(x)
        db[@username] = x
      end
    end
  end
  db.close # no more daybreak db needed
  
  if new_users.any? or changed_users.any? # only ssh if there are users to update
    Net::SSH.start(ssh_host, ssh_user, password: ssh_password, port: ssh_port) do |ssh|
      new_users.each do |u| # exec! ensures synchronous commands.
        ssh.exec!("echo #{u['username']}:dummy::::/home/#{u['username']}:/bin/nologin | newusers")
        ssh.exec!("echo '#{u['username']}:#{u['password']}' | chpasswd -e") # newusers wont allow hash to be provided.
      end
      changed_users.each do |u|
        ssh.exec!("echo '#{u['username']}:#{u['password']}' | chpasswd -e")
      end
    end
  end
rescue Exception => e # nice error handling, man.
  Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS) { |s| s.warning "#{Time.now.asctime()}: Sync Error, password sync potentially failed: #{e}" }
end

Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS) { |s| s.info "#{Time.now.asctime()}: Sync Finished. New Users(#{new_users.count}), Updated Passwords(#{changed_users.count})" }


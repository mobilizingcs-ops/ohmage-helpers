#!/usr/bin/env ruby
require 'fileutils'

# accepts username as first arg
user = ARGV[0]

# if username is not passed as arg, prompt for it.
unless user
  print("Enter full username to reset rstudio state: ")
  user = gets.chomp
end

dot_rstudio_dir = "/home/#{user}/.rstudio"
user_history_db = "#{dot_rstudio_dir}/history_database"

# load the contents of the user's history file into mem
history_contents = File.read(user_history_db)

# make sure the user's current session is suspended
if system("rstudio-server active-sessions | grep #{user}")
  pid = `rstudio-server active-sessions | grep #{user} | cut -d' ' -f1`.chomp
  system("rstudio-server force-suspend-session #{pid}")
end

# remove their .rstudio dir, recreate
FileUtils.rm_r dot_rstudio_dir
FileUtils.mkdir dot_rstudio_dir

# write out history contents to .history_database file
File.open(user_history_db, 'w') do |file|
  file.write history_contents
end

# ensure proper ownership of created directory.
FileUtils.chown_R user, user, dot_rstudio_dir
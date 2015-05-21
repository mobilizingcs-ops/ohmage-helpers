require 'ohmage'
require 'fileutils'

oh = Ohmage.client do |conf|
  conf.server_url = ENV['OHMAGE_SERVER']
  conf.user = ENV['OHMAGE_USER']
  conf.user = ENV['OHMAGE_PASSWORD']
end

search_param = 'ids' # gets passed to class/search
exclude_list = %w(urn:class:mobilize:IDS_PD:2014) # removes urns in this array from our class list
acct_matcher = 'lausd-' # only matches users if this string is in the index
replace_in_class = Regexp.new(/(urn:class:lausd:\d.*:(?:fall|spring):).*?:.*?(:.*)/) # captured group replaced with teacher acct name.
base_dir = '/root/IDS_history_databases' # where should I put all these files?

class_urns = oh.class_search(class_urn: search_param).collect(&:urn) # class urn array matching search param
class_urns.reject! { |c|  exclude_list.each.include? c } # reject from exclude_list
class_lists = oh.class_read(class_urn_list: class_urns.join(',')) # detailed ohmage api call for include list

class_lists.each do |c| # enumerate over class list to copy files.
  @students = []
  c.users.each do |user, privilege| # enumerate over users to find teacher and student list
    @teacher = user.to_s if privilege == 'privileged' && user.to_s.index(acct_matcher) # matches teacher!
    @students.push(user.to_s) if user.to_s.index(acct_matcher) # includes the teacher acct too..
  end
  c.urn.match(replace_in_class) # match prefix and suffix for class urn
  @urn = c.urn.gsub(replace_in_class, "#{$1}#{@teacher}#{$2}") # replace middle part with teacher's acct. 
  @urn.gsub!(':', '.') # i hate colons in FS file names.
  @class_dir = File.join(base_dir, @urn) # File.join for laziness. 
  FileUtils.mkdir_p(@class_dir) # make a directory per class to store files
  @students.each do |student|
    @student_db = File.join('/home/', student, '/.rstudio/history_database') # assumes rstudio history_databases are in /home/[user]/.rstudio/history_database
    @dest_file = File.join(@class_dir, "#{student}.txt") # destination looks like: base_dir/class_dir/student_acct_name.txt
    FileUtils.cp(@student_db, @dest_file) unless !File.exist?(@student_db) # actually copy the file, but only if it exists.
  end
end

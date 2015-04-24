#!/usr/bin/env ruby
# generates a dokuwiki page for the internal mobilize wiki with detailed information about the current deployment
require 'net/scp'

@math_class = `mysql -uohmage -pPASSHERE ohmage -H -e 'call dsummary("2014:fall", "math", 0);'`
@ids_class=`mysql -uohmage -pPASSHERE ohmage -H -e 'call dsummary("2014", "ids", 0);'`
@science_class=`mysql -uohmage -pPASSHERE ohmage -H -e 'call dsummary("2014:fall|2015:spring", "science", 0);'`
@math_campaign=`mysql -uohmage -pPASSHERE ohmage -H -e 'call dsummary_campaign("2014:fall", "math", 0);'`
@ids_campaign=`mysql -uohmage -pPASSHERE ohmage -H -e 'call dsummary_campaign("2014", "ids", 0);'`
@science_campaign=`mysql -uohmage -pPASSHERE ohmage -H -e 'call dsummary_campaign("2014:fall|2015:spring", "science", 0);'`

t = Time.now

page = ''
page += t.strftime("====== 2014-2015 Deployment Data (updated: %m/%d/%Y %H:%M) ======\n\n")

%w(ids math science).each do |s|
  page += "===== #{s.upcase} =====\n"
  %w(class campaign).each do |o|
    page += "==== by #{o} ====\n"
    page += "<html>" + instance_variable_get('@' + s + '_' + o) + "</html>\n"
  end
  page += "\n\n"
end

Net::SCP.start("web.ohmage.org", "someuser") do |scp|
  scp.upload StringIO.new(page), "/path/to/dokuwiki/pages/files/2014-2015.txt"
end

if t.monday?
  message = "<p>Hi Mobilizer!</p>
    <p>It's monday, and you know what that means... it's time to check out how the 2014-2015 deployment is coming along!<p>
    <p>Please visit the <a href='https://wiki.mobilizingcs.org/internal/deployment_data/2014-2015'>Detailed Deployment Page</a> on the wiki
    (and login) to take a look!</p>
    <br><br>
    <p>If you have any questions or comments regarding this email, please feel free contact Steve/Hongsuda!</p>"

  require 'mail'
  Mail.deliver do
    from 'Mobilize Support <support@mobilizingcs.org>'
    to 'somegrouplist'
    subject 'Mobilize Deployment Update'
    html_part do
      content_type 'text/html; charset=UTF-8'
      body message
    end
  end
end
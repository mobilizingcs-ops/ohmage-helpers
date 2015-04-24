#!/usr/bin/env ruby
#generates an email with the "Top 15" content. Mobilize uses this as a reminder/helper for implementing teachers.
require 'erb'
require 'mail'

class Top15
  attr_accessor :subject, :deployment_glob, :table

  @@template = "<html>
    <body>
      <p>Out top 15 data collectors this week are as follows, sorted by class:</p>
      <p>We'd like new data from you. Please share the challenges you may have that prevents 100% data collection in your classes by sending email to support@mobilizingcs.org.</p>
      <p><%= @table %></p>
      <small>
        <p>A handy list of the column headers:</p>
        <ul>
          <li>TotCp = Total Campaigns attached to Class</li>
          <li>ActCp = Active Campaigns attached to Class</li>
          <li>Shared = Shared Responses</li>
          <li>Total = Total Responses (includes Private and Shared)</li>
          <li>ActStd = Active (one or more responses submitted) Students in class</li>
          <li>TotStd = Total Students in class</li>
        </ul>
      </small>
    </body>
  </html>"

  def initialize(subject, deployment_glob)
    @subject = subject
    @deployment_glob = deployment_glob
    @table = `mysql -uohmage -p'passwordhere' ohmage -H -e "call top15classes('#{deployment_glob}', '#{subject}', 0);"`.gsub(/<\/TR>/, "</TR>\n")
    @message = ERB.new(@@template)
  end

  def send(email)
    body = @message.result(binding)
    Mail.deliver do
      from 'Mobilize Support <support@mobilizingcs.org>'
      to email
      subject 'Mobilize Deployment Top 15'
      html_part do
        content_type 'text/html; charset=UTF-8'
        body body
      end
    end
  end
end

math = Top15.new('math', '2014:fall')
math.send('some_list@email.com')
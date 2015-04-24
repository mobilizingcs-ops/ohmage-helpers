# Helpers for keeping tabs on deployments

## teacher_update.rb
Generates emails for given subject/deployment time.

#### Arguments
Edit script directly, adding instance calls as needed! Example (which is in the script):
```ruby
math = Top15.new('math', '2014:fall')
math.send('some_list@email.com')
```

#### Returns
exits with nil. sends emails via `localhost:25`.

#### Why??/How??
Mobilize uses this (in addition to a few list serves for our teachers) to send weekly reminders of data collection during a deployment. 
You may want to note the use of the `top15classes` mysql store procedure also included in this directory.
To execute, make sure you've edit the script to match your needs (as well as include a db password on line 31) and run via cron!

## deploy_to_wiki.rb
Generates a dokuwiki-formatted markdown page and sends it via scp to a web server with dokuwiki.

#### Arguments
Edit script directly, modifying your content/sql calls and intended recipients of the "monday" email.

#### Returns
exits with nil. uses scp to send the latest content to a web server running dokuwiki. default script also generates an email on mondays (note `if t.monday?`) providing a link to the content.

#### Why??/How??
Mobilize uses this (in addition to an internal mailing list) to provide a detailed deployment summary to our internal members. they can view the data by campaign or by class, and it is separated by deployment subject. Once weekly an email is sent to remind members that this content exists.
To execute, modify the sql queries at the top (note the use of the `dsummary` mysql store procedure available in this directory) and location you'd like to scp the contents too. then run via cron!

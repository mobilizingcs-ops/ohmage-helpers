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

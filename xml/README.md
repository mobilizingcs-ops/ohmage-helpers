# Helpers for doing some campaign XML inspecting/manipulation

## check_for_malformed_campaigns_2.17.1.rb
In ohmage 2.17.1 there were some bug fixes applied to campaign validation that could result in some `General Server Errors` being thrown by the server when attempting to serve campaign API calls that contain malformed campaigns. This script assumes you've not yet upgraded to 2.17.1 (or have rolled back to < 2.17.1) and can use the `/campaign/search` admin api to return all campaigns. It then checks the campaigns for `multi_choice` and `single_choice` prompts with no `<property>` tags (eg. no selectable options). 

#### Arguments
have your ohmage admin creds in `ENV` variables, or set them as you wish in the script.

#### Returns
Prints to console results of the scan.
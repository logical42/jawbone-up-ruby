Jawbone UP API
==============

This gem can access the (unofficial) Jawbone UP API. Currently login and a few
other methods are implemented, and you can always make raw API requests as well. 


Installation
------------

    gem install jawbone-up


Basic Usage
-----------

    require 'jawbone-up'
    
    up = JawboneUP::Session.new
    up.signin "you@example.com", "passw0rd"
    
    sleep_info = up.get_sleep_summary
    sleep_info['items'].each do |item|
      date = Time.at item['time_created']
      puts date.to_s + " " + item['title']
    end

You can also create a session from a stored token:

    require 'jawbone-up'
    
    up = JawboneUP::Session.new :auth => {
                                  :xid => 'xid-from-previous-session', 
                                  :token => 'token-from-previous-session'
                                }

More Info
---------

I will eventually be implementing more API methods as session functions. In the mean
time you can make raw API requests with the "get" and "post" methods.

See http://eric-blue.com/projects/up-api/ for full API documentation

require 'date'
require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-aggregates'
require 'dm-mysql-adapter'
require 'dm-pager'
require 'geoloqi'
require './lib/jawbone-up.rb'

DataMapper.finalize
DataMapper.setup :default, "mysql://root@127.0.0.1/aaron"

class User
  include DataMapper::Resource
  property :id, Serial
  property :username, String
  property :geoloqi_access_token, String, :length => 255
  property :email, String, :length => 100
  property :password, String, :length => 100
  property :jawbone_xid, String, :length => 255
  property :jawbone_token, String, :length => 512
end

class Sleep
  include DataMapper::Resource
  property :id, Serial

  belongs_to :user
  property :date, DateTime
  property :title, String, :length => 100
  property :time_started, Integer
  property :local_time_started, Time
  property :time_finished, Integer
  property :local_time_finished, Time
  property :timezone, String, :length => 50
  property :quality, Integer
  property :latitude, Float
  property :longitude, Float
  property :location, String, :length => 100
  property :raw, Text

  property :created_at, DateTime
  property :updated_at, DateTime

  def href
    "http://#{self.domain}/"
  end
end

user = User.first :id => 1
geoloqi = Geoloqi::Session.new :access_token => user.geoloqi_access_token


class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end
end


# The first time, log in with your email and password, then store the tokens it gets back in the database
# up = JawboneUP::Session.new
# result = up.signin user.email, user.password

# Log in via the session tokens previously created
up = JawboneUP::Session.new :auth => {
                              :xid => user.jawbone_xid, 
                              :token => user.jawbone_token
                            },
                            :config => {
                              # :logger => STDOUT,
                              :use_hashie_mash => true
                            }
puts

# If a 'sleep.json' file exists, it will pick up downloading where it previously left off
data_file = "./sleep.json"
if(FileTest.exist? data_file)
  sleep_history = JSON.parse(File.open(data_file, 'r') { |f| f.read })
  last_date = sleep_history[-1]["time_created"]
else
  sleep_history = []
  last_date = DateTime.parse("2011-11-15 23:48:47 -0800").strftime('%s')
end

puts "Downloading data since #{Time.at last_date.to_i}"

while (sleeps = up.get_sleep_summary 60, last_date).items.count > 0 do
  sleeps.items.each do |item|
    date = Time.at item.time_created
    puts date.to_s + " " + item.title
    puts "\t"
    puts item.to_json
    puts "\n"

    # Retrieve Geoloqi location history and city name
    location = geoloqi.get 'location/history', {:before => item.time_completed, :count => 1}
    if location[:points].count == 1
      latitude = location[:points][0][:location][:position][:latitude]
      longitude = location[:points][0][:location][:position][:longitude]
      context = geoloqi.get 'location/context', {:latitude => latitude, :longitude => longitude}
      location = context[:full_name] || ''
    else
      latitude = nil
      longitude = nil
      location = ''
    end

    # Adjust time for local timezone offset
    if (/GMT([-+]\d{4})/.match item.details.tz)
      puts $1
      offset = Rational($1.to_f/100.0, 24)
      puts offset.to_f
    elsif (/^(-?[0-9]+)$/.match item.details.tz)
      puts $1
      offset = Rational($1.to_f/60.0/60.0, 24)
      puts offset.to_f
    else
      offset = nil
    end

    if offset
      puts "Found timezone offset: #{offset}"
      adjusted_date_started = (Time.at(item.time_created).to_datetime).new_offset(offset)
      adjusted_date_finished = (Time.at(item.time_completed).to_datetime).new_offset(offset)
    else
      adjusted_date_started = nil
      adjusted_date_finished = nil
    end

    Sleep.create({ :user => user, 
      :title => item.title,
      :date => adjusted_date_finished,
      :local_time_started => adjusted_date_started,
      :time_started => Time.at(item.time_created),
      :local_time_finished => adjusted_date_finished,
      :time_finished => Time.at(item.time_completed),
      :timezone => item.details.tz,
      :quality => item.details.quality,
      :latitude => latitude,
      :longitude => longitude,
      :location => location,
      :raw => item.to_json
    })
    last_date = Time.at(item.time_completed + 1).to_i
  end
end

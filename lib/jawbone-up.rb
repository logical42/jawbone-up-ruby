libdir = File.dirname(__FILE__)
require 'json'
require 'faraday'
require './lib/jawbone-up/error.rb'
require './lib/jawbone-up/config.rb'
require './lib/jawbone-up/response.rb'
require './lib/jawbone-up/session.rb'

module JawboneUP
  @@adapter = :net_http
  
  class << self
    def api_url
      'https://jawbone.com'
    end
  end
end

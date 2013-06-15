require 'json'
require 'faraday'
require 'jawbone-up/error.rb'
require 'jawbone-up/config.rb'
require 'jawbone-up/response.rb'
require 'jawbone-up/session.rb'
# libdir = File.dirname(__FILE__)
# require "#{libdir}/jawbone-up/error.rb"
# require "#{libdir}/jawbone-up/config.rb"
# require "#{libdir}/jawbone-up/response.rb"
# require "#{libdir}/jawbone-up/session.rb"

module JawboneUP
  @@adapter = :net_http
  
  class << self
    def api_url
      'https://jawbone.com'
    end
  end
end

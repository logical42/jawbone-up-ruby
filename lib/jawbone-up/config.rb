module JawboneUP
  class Config
    attr_accessor :adapter, :logger, :use_hashie_mash, :throw_exceptions
    def initialize(opts={})
      self.use_hashie_mash ||= false
      self.throw_exceptions ||= true
      opts.each {|k,v| send("#{k}=", v)}
      begin
        require 'hashie' if self.use_hashie_mash && !defined?(Hashie::Mash)
      rescue LoadError
        raise Error, "You've requested Hashie::Mash, but the gem is not available. Don't set use_hashie_mash in your config, or install the hashie gem"
      end
    end
  end
end
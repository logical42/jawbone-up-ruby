require 'rest-client'

module JawboneUP
  class Session
    attr_reader :auth
    attr_accessor :config
    
    def initialize(opts={})
      opts[:config] = JawboneUP::Config.new opts[:config] if opts[:config].is_a? Hash
      @config = opts[:config] || JawboneUP::Config.new
      self.auth = opts[:auth] || {}
      self.auth[:token] = opts[:token] if opts[:token]
      self.auth[:xid] = opts[:xid] if opts[:xid]
    end

    def auth=(hash)
      @auth = hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

    def token
      @auth[:token]
    end

    def token?
      !token.nil?
    end

    def xid
      @auth[:xid]
    end

    def require_token
      raise ApiError.new(400, "no_token", "You have not logged in yet") if token.nil?
    end

    #
    # API methods
    # See http://eric-blue.com/projects/up-api/ for more information
    #
    
    def signin(email, password)
      result = self.post "/user/signin/login", {
        :email => email,
        :pwd => password,
        :service => "nudge"
      }
      if !result['error'].nil? && !result['error']['msg'].nil?
        msg = result['error']['msg']
      else
        msg = "Error logging in"
      end
      raise ApiError.new(400, "error", msg) if result['token'].nil?
      @auth[:token] = result['token']
      @auth[:xid] = result['user']['xid']
      @auth[:user] = result['user']
      return_response result
    end
    
    def get_sleep_summary(limit=nil, start_time=nil, end_time=nil)
      require_token
      params = {}
      params[:limit] = limit unless limit.nil?
      params[:start_time] = start_time unless start_time.nil?
      result = self.get "/nudge/api/users/"+xid+"/sleeps", params
      return_response result['data']
    end

    # Return the the metadata for the last 7 days' sleep activity (note: not _actual_ sleep details)
    def get_sleep_details
      result = self.get "/nudge/api/users/@me/sleeps/"
      return_response result['data']
    end

    # Return an array of arrays; each element includes the epoch and sleep state at that time
    # sleep_xid is required and can be obtained via the data structure returned from #get_sleep_details
    def get_sleep_snapshot( sleep_xid )
      result = self.get "/nudge/api/sleeps/#{sleep_xid}/snapshot"
      return_response result['data']
    end

    # Return either a Hashie::Mash object or the raw hash depending on config variable
    def return_response(hash)
      @config.use_hashie_mash ? Hashie::Mash.new(hash) : hash
    end

    #
    # Raw HTTP methods
    #

    def get(path, query=nil, headers={})
      response = execute :get, path, query, headers
      hash = JSON.parse response.body
    end

    def post(path, query=nil, headers={})
      response = execute :post, path, query, headers
      hash = JSON.parse response.body
    end
    
    def execute(meth, path, query=nil, headers={})
      query = CGI::parse(query) if query.is_a?(String)
      headers = default_headers.merge! headers

      if @config.logger
        @config.logger.print "## PATH: #{path}\n\n"
        @config.logger.print query.map{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join("&")
        @config.logger.print "\n\n"
        @config.logger.print headers.map{|k,v| "-H \"#{k}: #{v}\""}.join(" ")
        @config.logger.print "\n\n"
      end

      if meth == :get
        response = RestClient.get "#{JawboneUP.api_url}/#{path.gsub(/^\//, '')}", headers.merge({:params => query})
      else
        response = RestClient.post "#{JawboneUP.api_url}/#{path.gsub(/^\//, '')}", query, headers
      end

      if response.code != 200
        begin
          error = JSON.parse response.to_str
          raise JSON::ParserError.new if error['meta'].nil? || error['meta']['error_type'].nil?
          raise ApiError.new(response.code, error['meta']['error_type'], error['meta']['error_detail'])
        rescue JSON::ParserError => e
          raise ApiError.new(response.code, "error", "Unknown API error") if response.code != 200
        end
      end

      if @config.logger
        @config.logger.print "### JawboneUp::Session - #{meth.to_s.upcase} #{path}"
        @config.logger.print query.map{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join("&")
        @config.logger.print "\n### Request Headers: #{headers.inspect}"
        @config.logger.print "### Status: #{response.code}\n### Headers: #{response.headers.inspect}\n###"
      end
      
      Response.new response.code, response.headers, response.to_str
    end  

    def default_headers
      headers = {
        'User-Agent' => "Nudge/2.5.6 CFNetwork/609.1.4 Darwin/13.0.0", 
        # 'Content-Type' => 'application/json', 
        'Accept' => 'application/json',
        'x-nudge-platform' => 'iPhone 5,2; 6.1.3',
        'Accept-Encoding' => 'plain'
      }
      headers['x-nudge-token'] = token if token
      headers
    end    
  end
end

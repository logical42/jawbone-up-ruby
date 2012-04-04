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

      @connection = Faraday.new(:url => JawboneUP.api_url) do |builder|
        builder.adapter :net_http
      end
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
      query = Rack::Utils.parse_query query if query.is_a?(String)
      headers = default_headers.merge! headers

      raw = @connection.send(meth) do |req|
        req.url "/#{path.gsub(/^\//, '')}"
        req.headers = headers
        if query
          meth == :get ? req.params = query : req.body = URI.encode_www_form(query)
        end
      end

      if raw.status != 200
        begin
          error = JSON.parse raw.body
          raise JSON::ParserError.new if error['meta'].nil? || error['meta']['error_type'].nil?
          raise ApiError.new(raw.status, error['meta']['error_type'], error['meta']['error_detail'])
        rescue JSON::ParserError => e
          raise ApiError.new(raw.status, "error", "Unknown API error") if raw.status != 200
        end
      end

      if @config.logger
        @config.logger.print "### JawboneUp::Session - #{meth.to_s.upcase} #{path}"
        @config.logger.print "?#{Rack::Utils.build_query query}" unless query.nil?
        @config.logger.print "\n### Request Headers: #{headers.inspect}"
        @config.logger.print "### Status: #{raw.status}\n### Headers: #{raw.headers.inspect}\n###"
        # @config.logger.puts "Body: #{raw.body}"
      end
      
      Response.new raw.status, raw.headers, raw.body
    end  

    def default_headers
      headers = {
        'User-Agent' => "Nudge/1.3.1 CFNetwork/548.0.4 Darwin/11.0.0", 
        # 'Content-Type' => 'application/json', 
        'Accept' => 'application/json',
        'x-nudge-platform' => 'iPhone 4; 5.0.1'
      }
      headers['x-nudge-token'] = token if token
      headers
    end    
  end
end
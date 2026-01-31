# app/services/pdp/http_client.rb
require "net/http"
require "uri"
require "json"

module Pdp
  class HttpClient
    class HttpError < StandardError
      attr_reader :status, :body

      def initialize(message, status: nil, body: nil)
        super(message)
        @status = status
        @body = body
      end
    end

    def initialize(base_url:, api_key: nil, timeout: 15)
      @base_url = base_url.to_s.chomp("/")
      @api_key  = api_key
      @timeout  = timeout.to_i
    end

    def post(path, json:, headers: {})
      request(:post, path, json: json, headers: headers)
    end

    def get(path, headers: {})
      request(:get, path, json: nil, headers: headers)
    end

    private

    def request(method, path, json:, headers:)
      uri = URI.parse(@base_url + path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      req =
        case method
        when :post then Net::HTTP::Post.new(uri.request_uri)
        when :get  then Net::HTTP::Get.new(uri.request_uri)
        else
          raise ArgumentError, "Unsupported method: #{method.inspect}"
        end

      req["Accept"] = "application/json"
      req["Content-Type"] = "application/json"
      req["User-Agent"] = "mes2vis/1.0 (Rails)"
      req["Authorization"] = "Bearer #{@api_key}" if @api_key.present?

      headers.to_h.each { |k, v| req[k.to_s] = v.to_s }

      req.body = JSON.generate(json) if json

      res = http.request(req)
      status = res.code.to_i
      body = res.body.to_s

      parsed =
        begin
          body.present? ? JSON.parse(body) : {}
        rescue JSON::ParserError
          { "_raw" => body }
        end

      if status >= 200 && status < 300
        return { status: status, body: parsed, raw: body }
      end

      raise HttpError.new("HTTP #{status} on #{method.upcase} #{path}", status: status, body: parsed)
    end
  end
end

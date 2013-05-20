require "uri"
require "restful_geof/model"

module RestfulGeof
  module Routes

    def self.route(request)

      if request.request_method == "GET" && request.path_info.match(%r{
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        (?<conditions_string>(/[^/]+/(is|matches|contains)/[^/]+)*)
        (/limit/(?<limit>\d+)$)?
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s
        limit = URI.unescape $~[:limit].to_s
        conditions = $~[:conditions_string].to_s.scan(%r{
          /(?<field>[^/]+)
          /(?<operator>is|matches|contains)
          /(?<value>[^/]+)
        }x)

        options = { :is => {}, :matches => {}, :contains => {} }
        options[:limit] = limit.to_i unless limit.empty?
        conditions.each do |condition|
          field, operator, value = condition.map { |str| URI.unescape str }
          options[operator.to_sym][field] = value
        end

        return Model.new(database, table).find(options)
      end

      400 # Bad Request
    end

  end
end


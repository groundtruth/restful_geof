require "uri"

require "patches/ruby/object"

module RestfulGeof
  class Routes

    def initialize(request)
      @request_method = request.request_method
      @path_info = request.path_info
      @body = request.body.read
    end

    def params
      query_request_params || crud_request_params || { :action => :unknown } 
    end

    private

    def query_request_params
      condition_matcher = '(
        /[^/]+/(in|is|matches|contains)/[^/]+ |
        /closest/[^/]+/[^/]+ |
        /[^/]+/maround/[^/]+/[^/]+
      )'
      if @request_method == "GET" && @path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        (?<conditions_string>#{condition_matcher}*)
        (/limit/(?<limit>\d+))?
        $
      }x)
        main_match = $~
        condition_options = { :is => {}, :in => {}, :matches => {}, :contains => {}, :closest => {}, :maround => {} }

        condition_options[:limit] = URI.unescape(main_match[:limit].to_s).to_i unless URI.unescape(main_match[:limit].to_s).empty?

        main_match[:conditions_string].to_s.scan(%r{#{condition_matcher}}x).each do |condition_raw|
          escaped_parts = condition_raw.first[1..-1].split('/')
          part1, part2, part3, part4 = escaped_parts.map { |str| URI.unescape str }
          if part2.is_in?(%w{is matches contains})
            condition_options[part2.to_sym][part1] = part3
          elsif part2 == "in"
            condition_options[:in][part1] = escaped_parts.last.split(",").map { |str| URI.unescape str }
          elsif part1 == "closest"
            condition_options[:closest][:lon] = part2
            condition_options[:closest][:lat] = part3
          elsif part2 == "maround"
            condition_options[:maround][:radius] = part1.to_f
            condition_options[:maround][:lon] = part3.to_f
            condition_options[:maround][:lat] = part4.to_f
          else
            return { :action => :unknown }
          end
        end

        {
          :action => :query,
          :database => URI.unescape(main_match[:database].to_s),
          :table => URI.unescape(main_match[:table].to_s),
          :conditions => condition_options
        }
      end
    end

    def crud_request_params
      if crud_action && @path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        (/(?<id>[^/]+))?
        $
      }x)
        params_if_valid(
          without_empties({
            :action => crud_action,
            :database => URI.unescape($~[:database].to_s),
            :table => URI.unescape($~[:table].to_s),
            :id => URI.unescape($~[:id].to_s),
            :body_json => @body
          })
        )
      end
    end

    def crud_action
      {
        "GET" => :read,
        "POST" => :create,
        "DELETE" => :delete,
        "PUT" => :update
      }[@request_method]
    end

    def without_empties(params)
      Hash[params.map { |k,v| [k, v] unless v.empty? }.compact]
    end

    def params_if_valid(params)
      keys_required_by_action = {
        :read =>   [:action, :database, :table, :id],
        :create => [:action, :database, :table, :body_json],
        :delete => [:action, :database, :table, :id],
        :update => [:action, :database, :table, :id, :body_json]
      }
      params if params.keys == keys_required_by_action[crud_action]
    end

  end
end


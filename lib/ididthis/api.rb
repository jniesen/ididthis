require "rest-client"

module Ididthis
  module API
    class Client
      def validate_token(token)
        RestClient.get(ENDPOINTS[:noop], header_map(token)) do |response|
          case response.code
          when 200
            return true
          else
            return false
          end
        end
      end

      def get_teams(token)
        RestClient.get(ENDPOINTS[:team], header_map(token)
        ) do |response, request, result, &block|
          case response.code
          when 200
            resp = JSON.parse(response.body, :symbolize_names => true)
            # FIXME: This is not right, need to throw an error when no teams are found
            resp[:ok] ? resp[:results] : []
          else
            response.return!(request, result, &block)
          end
        end
      end

      def get_team(token)
        RestClient.get(Ididthis::Config[:team], header_map(token)
        ) do |response, request, result, &block|
          case response.code
          when 200
            resp = JSON.parse(response.body, :symbolize_names => true)
            resp[:ok] ? resp[:result] : {}
          else
            response.return!(request, result, &block)
          end
        end
      end

      def post_done(token, done, team, options)
        payload = { raw_text: done, team: team }
        payload[:done_date] = options[:date] if options[:date]
        payload[:meta_data] = options[:metadata] if options[:metadata]

        RestClient.post(
          ENDPOINTS[:dones], payload.to_json, header_map(token)) do |response|
          case response.code
          when 201
            puts "Posted your done!"
          else
            puts "Something went wrong, HTTP status code was #{response.code}."
          end
        end
      end

      def get_dones(token, options)
        RestClient.get(
          ENDPOINTS[:dones],
          header_map(token).merge(:params => options)
        ) do |response, request, result, &block|
          case response.code
          when 200
            resp = JSON.parse(response, :symbolize_names => true)
            resp[:ok] ? resp[:results] : {}
          else
            response.return!(request, result, &block)
          end
        end
      end

private

      def header_map(token)
        {
          :content_type => :json,
          :accept => :json,
          :Authorization => tokenize(token),
        }
      end

      def tokenize(token)
        "Token #{token}"
      end
    end
  end
end

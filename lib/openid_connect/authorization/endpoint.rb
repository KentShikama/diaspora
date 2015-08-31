module OpenidConnect
  module Authorization
    class Endpoint
      attr_accessor :app, :user, :client, :redirect_uri, :response_type, :scopes, :_request_, :request_uri, :request_object
      delegate :call, to: :app

      def initialize(current_user)
        @user = current_user
        @app = Rack::OAuth2::Server::Authorize.new do |req, res|
          buildAttributes(req, res)
          if OAuthApplication.available_response_types.include? Array(req.response_type).collect(&:to_s).join(' ')
            handleResponseType(req, res)
          else
            req.unsupported_response_type!
          end
        end
      end
      def buildAttributes(req, res)
        buildClient(req)
        buildRedirectURI(req, res)
      end

      def handleResponseType(req, res)
        # Implemented by subclass
      end

    private

      def buildClient(req)
        @client = OAuthApplication.find_by_client_id(req.client_id) || req.bad_request!
      end
      def buildRedirectURI(req, res)
        res.redirect_uri = @redirect_uri = req.verify_redirect_uri!(@client.redirect_uris)
      end
    end
  end
end

module OpenidConnect
  class TokenEndpoint
    attr_accessor :app
    delegate :call, to: :app

    def initialize
      @app = Rack::OAuth2::Server::Token.new do |req, res|
        o_auth_app = retrieve_client(req)
        if app_valid?(o_auth_app, req)
          handle_flows(req, res)
        else
          req.invalid_client!
        end
      end
    end

    def handle_flows(req, res)
      case req.grant_type
      when :password
        handle_password_flow(req, res)
      when :refresh_token
        handle_refresh_flow(req, res)
      else
        req.unsupported_grant_type!
      end
    end

    def handle_password_flow(req, res)
      user = User.find_for_database_authentication(username: req.username)
      if user
        if user.valid_password?(req.password)
          auth = OpenidConnect::Authorization.find_or_create(req.client_id, user)
          res.access_token = auth.create_access_token
        else
          req.invalid_grant!
        end
      else
        req.invalid_grant! # TODO: Change to user login: Perhaps redirect_to login_path?
      end
    end

    def handle_refresh_flow(req, res)
      auth = OpenidConnect::Authorization.where(client_id: req.client_id).where(refresh_token: req.refresh_token).first
      if auth
        res.access_token = auth.create_access_token
      else
        req.invalid_grant!
      end
    end

    def retrieve_client(req)
      OpenidConnect::OAuthApplication.find_by client_id: req.client_id
    end

    def app_valid?(o_auth_app, req)
      o_auth_app.client_secret == req.client_secret
    end

  end
end

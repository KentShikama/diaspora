require "spec_helper"

describe Api::V0::UsersController do
  # TODO: Replace with factory
  let!(:client) do
    Api::OpenidConnect::OAuthApplication.create!(
      client_name: "Diaspora Test Client", redirect_uris: ["http://localhost:3000/"])
  end
  let(:auth_with_read) do
    auth = Api::OpenidConnect::Authorization.create!(o_auth_application: client, user: alice)
    auth.scopes << [Api::OpenidConnect::Scope.find_or_create_by(name: "openid"),
                    Api::OpenidConnect::Scope.find_or_create_by(name: "read")]
    auth
  end
  let!(:access_token_with_read) { auth_with_read.create_access_token.to_s }

  describe "#show" do
    before do
      get api_openid_connect_user_info_path, access_token: access_token_with_read
    end

    it "shows the info" do
      json_body = JSON.parse(response.body)
      expect(json_body["nickname"]).to eq(alice.name)
      expect(json_body["profile"]).to eq(File.join(AppConfig.environment.url, "people", alice.guid).to_s)
    end
  end
end

require 'rails_helper'

RSpec.describe "GET /", type: :request do
  it "redirects to /accounts" do
    get "/"
    expect(response).to redirect_to("/accounts")
  end
end

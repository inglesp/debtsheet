require 'rails_helper'

RSpec.describe AccountsController, type: :controller do
  before do
    set_up_test_accounts
    create_test_payment
    create_test_purchase
  end

  describe "GET index" do
    before do
      get :index
    end

    it "is successful" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET show" do
    before do
      get :show, :id => @alice.id
    end

    it "is successful" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET new" do
    before do
      get :new
    end

    it "is successful" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST create" do
    context "with valid params" do
      before do
        post :create, {:account=> {:name => "Glenda"}}
      end

      it "creates a new account" do
        expect(Account.find_by_name("Glenda")).to_not be_nil
      end

      it "redirects to accounts path" do
        expect(response).to redirect_to("/accounts")
      end
    end

    context "with invalid params" do
      before do
        post :create, {:account=> {:name => ""}}
      end

      it "renders new template" do
        expect(response).to render_template(:new)
      end
    end
  end
end

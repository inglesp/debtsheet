require 'rails_helper'

RSpec.describe EventsController, type: :controller do
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

  describe "GET new_payment" do
    before do
      get :new_payment
    end

    it "is successful" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST create_payment" do
    context "with valid params" do
      before do
        post :create_payment, {
          :payer_id => @carol.id,
          :payee_id => @david.id,
          :amount => "10.00",
          :date => "2016-01-03",
        }
      end

      it "creates a new event" do
        event = Event.last
        expect(event.payer).to eq(@carol)
        expect(event.payee).to eq(@david)
        expect(event.amount_cents).to eq(1000)
        expect(event.date).to eq(Date.parse("2016-01-03"))
      end

      it "redirects to events path" do
        expect(response).to redirect_to("/events")
      end
    end

    context "with invalid params" do
      before do
        post :create_payment, {
          :payer_id => @carol.id,
          :payee_id => @carol.id,
          :amount => "10.00",
          :date => "2016-01-03",
        }
      end

      it "renders new_payment template" do
        expect(response).to render_template(:new_payment)
      end

      it "sets @error_message" do
        expect(assigns(:error_message)).to eq("Payer and payee must be different")
      end
    end
  end

  describe "GET new_purchase" do
    before do
      get :new_purchase
    end

    it "is successful" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST create_purchase" do
    context "with valid params" do
      before do
        post :create_purchase, {
          :purchaser_id => @carol.id,
          :amount => "10.00",
          :date => "2016-01-03",
          :details => "Spotify subscription"
        }
      end

      it "creates a new event" do
        event = Event.last
        expect(event.purchaser).to eq(@carol)
        expect(event.amount_cents).to eq(1000)
        expect(event.date).to eq(Date.parse("2016-01-03"))
        expect(event.details).to eq("Spotify subscription")
      end

      it "redirects to events path" do
        expect(response).to redirect_to("/events")
      end
    end

    context "with invalid params" do
      before do
        post :create_purchase, {
          :purchaser_id => @carol.id,
          :amount => "0.00",
          :date => "2016-01-03",
          :details => "Spotify subscription"
        }
      end

      it "renders new_purchase template" do
        expect(response).to render_template(:new_purchase)
      end

      it "sets @error_message" do
        expect(assigns(:error_message)).to eq("Amount must be positive")
      end
    end
  end
end

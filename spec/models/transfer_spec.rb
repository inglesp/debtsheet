require 'rails_helper'

RSpec.describe Transfer, type: :model do
  before do
    set_up_test_accounts
  end

  describe "#date" do
    it "returns date of event" do
      event = Event.create_payment(
        :payer_id => @alice.id,
        :payee_id => @bob.id,
        :amount => "20.16",
        :date => "2016-01-01",
      )
      transfer = event.transfers[0]
      expect(transfer.date).to eq(Date.parse("2016-01-01"))
    end
  end

  describe "#description" do
    context "for payment" do
      before do
        @event = Event.create_payment(
          :payer_id => @alice.id,
          :payee_id => @bob.id,
          :amount => "20.16",
          :date => "2016-01-01",
        )
      end

      context "from payer's perspective" do
        it "describes payment to payee" do
          transfer = @alice.transfers[0]
          expect(transfer.description).to eq("Payment to Bob")
        end
      end

      context "from payee's perspective" do
        it "describes payment from payer" do
          transfer = @bob.transfers[0]
          expect(transfer.description).to eq("Payment from Alice")
        end
      end
    end

    context "for purchase" do
      before do
        @event = Event.create_purchase(
          :purchaser_id => @alice.id,
          :amount => "20.16",
          :date => "2016-01-02",
          :details => "gas bill",
        )
      end

      context "from purchaser's perspective" do
        it "describes payment for, and share of, something" do
          transfers = @alice.transfers
          expect(transfers.map(&:description)).to match_array(["Payment for gas bill", "Share of gas bill"])
        end
      end

      context "from non-purchaser's perspective" do
        it "describes share of something" do
          transfer = @bob.transfers[0]
          expect(transfer.description).to eq("Share of gas bill")
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Event, type: :model do
  before do
    set_up_test_accounts
  end

  describe ".create_payment" do
    context "when called with valid input" do
      before do
        @event = create_test_payment
      end

      it "creates new event with event_type 'payment'" do
        expect(@event.event_type).to eq("payment")
      end

      it "sets the date on the new event" do
        expect(@event.date).to eq(Date.parse("2016-01-01"))
      end

      it "creates one transfer with a positive amount" do
        transfers = @event.transfers.select {|t| t.amount_cents > 0}
        expect(transfers.size).to eq(1)
      end

      describe "transfer with positive amount" do
        before do
          @transfer = @event.transfers.detect {|t| t.amount_cents > 0}
        end

        it "belongs to payer's account" do
          expect(@transfer.account).to eq(@alice)
        end

        it "has correct amount_cents" do
          expect(@transfer.amount_cents).to eq(2016)
        end
      end

      it "creates one transfer with a negative amount" do
        transfers = @event.transfers.select {|t| t.amount_cents < 0}
        expect(transfers.size).to eq(1)
      end

      describe "transfer with negative amount" do
        before do
          @transfer = @event.transfers.detect {|t| t.amount_cents < 0}
        end

        it "belongs to payee's account" do
          expect(@transfer.account).to eq(@bob)
        end

        it "has correct amount_cents" do
          expect(@transfer.amount_cents).to eq(-2016)
        end
      end

      it "creates one transfer for payer" do
        expect(@alice.transfers.size).to eq(1)
      end

      it "creates one transfer for payee" do
        expect(@bob.transfers.size).to eq(1)
      end
    end

    context "when called with invalid input" do
      context "when payer_id does not exist" do
        it "raises InvalidInput" do
          @edna.destroy
          expect{create_test_payment(:payer_id => @edna.id)}.to raise_error(
            Event::InvalidInput, "Could not find account with id #{@edna.id}"
          )
        end
      end

      context "when payee_id does not exist" do
        it "raises InvalidInput" do
          @edna.destroy
          expect{create_test_payment(:payee_id => @edna.id)}.to raise_error(
            Event::InvalidInput, "Could not find account with id #{@edna.id}"
          )
        end
      end

      context "when payer_id equals payee_id" do
        it "raises InvalidInput" do
          expect{create_test_payment(:payee_id => @alice.id)}.to raise_error(
            Event::InvalidInput, "Payer and payee must be different"
          )
        end
      end

      context "when amount cannot be parsed" do
        it "raises InvalidInput" do
          expect{create_test_payment(:amount => "12.34.56")}.to raise_error(
            Event::InvalidInput, "Could not parse amount"
          )
        end
      end

      context "when amount is not positive" do
        it "raises InvalidInput" do
          expect{create_test_payment(:amount => "0.00")}.to raise_error(
            Event::InvalidInput, "Amount must be positive"
          )
        end
      end

      context "when date cannot be parsed" do
        it "raises InvalidInput" do
          expect{create_test_payment(:date => "12/34/56")}.to raise_error(
            Event::InvalidInput, "Could not parse date"
          )
        end
      end
    end
  end

  describe ".create_purchase" do
    context "when called with valid input" do
      before do
        @event = create_test_purchase
      end

      it "creates new event with event_type 'purchase'" do
        expect(@event.event_type).to eq("purchase")
      end

      it "sets the date on the new event" do
        expect(@event.date).to eq(Date.parse("2016-01-02"))
      end

      it "creates one transfer with a positive amount" do
        transfers = @event.transfers.select {|t| t.amount_cents > 0}
        expect(transfers.size).to eq(1)
      end

      describe "transfer with positive amount" do
        before do
          @transfer = @event.transfers.detect {|t| t.amount_cents > 0}
        end

        it "belongs to purchaser's account" do
          expect(@transfer.account).to eq(@alice)
        end

        it "has correct amount_cents" do
          expect(@transfer.amount_cents).to eq(2016)
        end
      end

      it "creates one transfer with a negative amount for each account" do
        transfers = @event.transfers.select {|t| t.amount_cents < 0}
        expect(transfers.size).to eq(@everyone.size)
      end

      describe "transfers with negative amount" do
        before do
          @transfers = @event.transfers.select {|t| t.amount_cents < 0}
        end

        it "belong to each account" do
          expect(@transfers.map(&:account)).to match_array(@everyone)
        end

        it "have correct amount_cents" do
          expect(@transfers.map(&:amount_cents)).to match_array([-336] * 6)
        end
      end

      it "creates two transfers for purchaser" do
        expect(@alice.transfers.size).to eq(2)
      end

      it "creates one transfer for other accounts" do
        # NOTE: Once you've got this spec passing, you should enable creation
        # of sample data in db/seeds.db.
        @everyone.each do |account|
          next if account == @alice
          expect(account.transfers.size).to eq(1)
        end
      end
    end

    context "when called with invalid input" do
      context "when purchaser_id does not exist" do
        it "raises InvalidInput" do
          @edna.destroy
          expect{create_test_purchase(:purchaser_id => @edna.id)}.to raise_error(
            Event::InvalidInput, "Could not find account with id #{@edna.id}"
          )
        end
      end

      context "when amount cannot be parsed" do
        it "raises InvalidInput" do
          expect{create_test_purchase(:amount => "12.34.56")}.to raise_error(
            Event::InvalidInput, "Could not parse amount"
          )
        end
      end

      context "when amount is not positive" do
        it "raises InvalidInput" do
          expect{create_test_purchase(:amount => "0.00")}.to raise_error(
            Event::InvalidInput, "Amount must be positive"
          )
        end
      end

      context "when date cannot be parsed" do
        it "raises InvalidInput" do
          expect{create_test_purchase(:date => "12/34/56")}.to raise_error(
            Event::InvalidInput, "Could not parse date"
          )
        end
      end

      context "when details are missing" do
        it "raises InvalidInput" do
          expect{create_test_purchase(:details => "")}.to raise_error(
            Event::InvalidInput, "Details were missing"
          )
        end
      end
    end
  end

  describe "#payee" do
    it "returns payee account" do
      event = Event.create_payment(
        :payer_id => @alice.id,
        :payee_id => @bob.id,
        :amount => "20.16",
        :date => "2016-01-01",
      )
      expect(event.payee).to eq(@bob)
    end

    context "when event is not payment" do
      it "raises exception" do
        event = create_test_purchase
        expect{event.payee}.to raise_error(TypeError)
      end
    end
  end

  describe "#payer" do
    it "returns payer account" do
      event = Event.create_payment(
        :payer_id => @alice.id,
        :payee_id => @bob.id,
        :amount => "20.16",
        :date => "2016-01-01",
      )
      expect(event.payer).to eq(@alice)
    end

    context "when event is not payment" do
      it "raises exception" do
        event = create_test_purchase
        expect{event.payer}.to raise_error(TypeError)
      end
    end
  end

  describe "#purchaser" do
    it "returns purchaser account" do
      event = create_test_purchase
      expect(event.purchaser).to eq(@alice)
    end

    context "when event is not purchase" do
      it "raises exception" do
        event = create_test_payment
        expect{event.purchaser}.to raise_error(TypeError)
      end
    end
  end

  describe "#description" do
    context "when event is payment" do
      it "describes payment" do
        event = create_test_payment
        expect(event.description).to eq("Alice paid £20.16 to Bob")
      end
    end

    context "when event is purchase" do
      it "describes purchase" do
        event = create_test_purchase
        expect(event.description).to eq("Alice paid £20.16 for gas bill")
      end
    end
  end
end

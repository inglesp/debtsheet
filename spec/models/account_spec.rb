require 'rails_helper'

RSpec.describe Account, type: :model do
  before do
    set_up_test_accounts

    Event.create_payment(
      :payer_id => @alice.id,
      :payee_id => @bob.id,
      :amount => "10.00",
      :date => "2016-01-01",
    )
    Event.create_payment(
      :payer_id => @bob.id,
      :payee_id => @alice.id,
      :amount => "5.00",
      :date => "2016-01-02",
    )
  end

  describe "validation" do
    it "requires that name is present" do
      expect{Account.create!}.to raise_error(ActiveRecord::RecordInvalid, /Name can't be blank/)
    end

    it "requires that name is unique" do
      expect{Account.create!(:name => "Alice")}.to raise_error(ActiveRecord::RecordInvalid, /Name has already been taken/)
    end
  end

  describe "#balance_cents" do
    it "returns the sum of the amounts for each transfer" do
      expect(@alice.balance_cents).to eq(500)
      expect(@bob.balance_cents).to eq(-500)
    end
  end

  describe "#summary" do
    context "when account is owed money" do
      it "returns how much they are owed" do
        expect(@alice.summary).to eq("is owed £5.00")
      end
    end

    context "when account owes money" do
      it "returns how much they owe" do
        expect(@bob.summary).to eq("owes £5.00")
      end
    end

    context "when account owes no money" do
      it "returns 'is in balance'" do
        expect(@carol.summary).to eq("is in balance")
      end
    end
  end
end

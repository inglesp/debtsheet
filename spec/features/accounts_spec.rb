require 'rails_helper'

RSpec.feature "Accounts", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
  end

  scenario "User visits list of accounts" do
    visit "/accounts"

    table = find("table#accounts")
    @everyone.each do |account|
      expect(table).to have_text(account.name)
    end

    expect(table.find("tr#account-#{@alice.id}")).to have_text("is owed £36.96")
    expect(table.find("tr#account-#{@bob.id}")).to have_text("owes £23.52")
  end

  scenario "User visits Alice's account" do
    visit "/accounts"
    click_on("Alice")

    account_summary = find("#account_summary")
    expect(account_summary).to have_content("Alice is owed £36.96")

    table = find("table#transfers")

    payment_transfer = @payment.transfers.detect {|t| t.account == @alice}
    row = table.find("tr#transfer-#{payment_transfer.id}")
    expect(row).to have_text("2016-01-01")
    expect(row).to have_text("Payment to Bob")
    expect(row).to have_text("£20.16")

    purchase_transfer_1 = @purchase.transfers.detect {|t| t.account == @alice && t.amount_cents > 0}
    row = table.find("tr#transfer-#{purchase_transfer_1.id}")
    expect(row).to have_text("2016-01-02")
    expect(row).to have_text("Payment for gas bill")
    expect(row).to have_text("£20.16")

    purchase_transfer_2 = @purchase.transfers.detect {|t| t.account == @alice && t.amount_cents < 0}
    row = table.find("tr#transfer-#{purchase_transfer_2.id}")
    expect(row).to have_text("2016-01-02")
    expect(row).to have_text("Share of gas bill")
    expect(row).to have_text("-£3.36")
  end

  scenario "User creates new account" do
    visit "/accounts"
    click_on("New account")
    fill_in("Name", :with => "Glenda")
    click_button("Submit")

    table = find("table#accounts")
    glenda = Account.find_by_name("Glenda")

    row = table.find("tr#account-#{glenda.id}")
    expect(row).to have_text("Glenda")
    expect(row).to have_text("is in balance")
  end

  scenario "User creates new account with invalid params" do
    visit "/accounts"
    click_on("New account")
    click_button("Submit")

    alert = find(".alert-danger")
    expect(alert).to have_content("Name can't be blank")
  end
end

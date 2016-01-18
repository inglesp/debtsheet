require 'rails_helper'

RSpec.feature "Events", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
  end

  scenario "User visits list of events" do
    visit "/events"
    table = find("table#events")

    payment_row = table.find("tr#event-#{@payment.id}")
    expect(payment_row).to have_content("Alice paid £20.16 to Bob")
    expect(payment_row).to have_content("2016-01-01")

    purchase_row = table.find("tr#event-#{@purchase.id}")
    expect(purchase_row).to have_content("Alice paid £20.16 for gas bill")
    expect(purchase_row).to have_content("2016-01-02")
  end

  scenario "User creates new payment" do
    visit "/events"
    click_on("New payment")
    select("Carol", :from => "Payer")
    select("Alice", :from => "Payee")
    fill_in("Amount", :with => "3.66")
    fill_in("Date", :with => "2016-01-03")
    click_button("Submit")

    table = find("table#events")
    event = Event.last

    row = table.find("tr#event-#{event.id}")
    expect(row).to have_content("Carol paid £3.66 to Alice")
    expect(row).to have_content("2016-01-03")
  end

  scenario "User tries to create new payment with invalid input" do
    visit "/events"
    click_on("New payment")
    select("Carol", :from => "Payer")
    select("Carol", :from => "Payee")
    fill_in("Amount", :with => "3.66")
    fill_in("Date", :with => "2016-01-03")
    click_button("Submit")

    alert = find(".alert-danger")
    expect(alert).to have_content("Payer and payee must be different")
  end

  scenario "User creates new purchase" do
    visit "/events"
    click_on("New purchase")
    select("Carol", :from => "Purchaser")
    fill_in("Amount", :with => "10.00")
    fill_in("Details", :with => "Spotify subscription")
    fill_in("Date", :with => "2016-01-03")
    click_button("Submit")

    table = find("table#events")
    event = Event.last

    row = table.find("tr#event-#{event.id}")
    expect(row).to have_content("Carol paid £10.00 for Spotify subscription")
    expect(row).to have_content("2016-01-03")
  end

  scenario "User tries to create new purchase with invalid input" do
    visit "/events"
    click_on("New purchase")
    select("Carol", :from => "Purchaser")
    fill_in("Amount", :with => "0.00")
    fill_in("Details", :with => "Spotify subscription")
    fill_in("Date", :with => "2016-01-03")
    click_button("Submit")

    alert = find(".alert-danger")
    expect(alert).to have_content("Amount must be positive")
  end
end

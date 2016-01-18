require 'rails_helper'

RSpec.describe Utils do
  describe ".parse_amount" do
    it "can parse amount with two decimal places" do
      expect(Utils.parse_amount("20.16")).to eq(2016)
    end

    it "can parse amount with no decimal places" do
      expect(Utils.parse_amount("20")).to eq(2000)
    end

    it "can parse amount with dot followed by two decimal places" do
      expect(Utils.parse_amount(".16")).to eq(16)
    end

    it "raises AmountParsingError on invalid input" do
      inputs = ["20.1", "20.", "20.161", "20.", "20.1.5", "20.a", "a.16"]
      inputs.each do |input|
        expect{Utils.parse_amount(input)}.to raise_error(Utils::AmountParsingError)
      end
    end
  end
end

RSpec.describe Event, type: :model do
  describe ".create_payment" do
    context "when called with valid input" do
      before do
        set_up_test_accounts
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
  end
end

RSpec.describe Utils do
  describe ".split_amount_cents" do
    it "can split an amount evenly between buckets" do
      expect(Utils.split_amount_cents(1000, 5)).to eq([200] * 5)
    end

    it "can split an amount unevenly between buckets" do
      expect(Utils.split_amount_cents(1002, 5)).to match_array([201] * 2 + [200] * 3)
    end

    it "splits unevenly at random" do
      # There's a 1 10^29 chance this test will fail erroneously.
      # http://www.wolframalpha.com/input/?i=100+choose+50
      expect(Utils.split_amount_cents(1050, 100)).not_to eq(Utils.split_amount_cents(1050, 100))
    end
  end
end

RSpec.describe Event, type: :model do
  before do
    set_up_test_accounts
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
end

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
end

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
end

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

RSpec.describe AccountsController, type: :controller do
  before do
    set_up_test_accounts
    create_test_payment
    create_test_purchase
  end

  describe "GET show" do
    before do
      get :show, :id => @alice.id
    end

    it "is successful" do
      expect(response).to have_http_status(:ok)
    end
  end
end

RSpec.feature "Accounts", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
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
end

RSpec.describe Event, type: :model do
  before do
    set_up_test_accounts
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
end

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
end

RSpec.describe EventsController, type: :controller do
  before do
    set_up_test_accounts
    create_test_payment
    create_test_purchase
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
  end
end

RSpec.feature "Events", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
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
end

RSpec.describe EventsController, type: :controller do
  before do
    set_up_test_accounts
    create_test_payment
    create_test_purchase
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
  end
end

RSpec.feature "Events", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
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
end

RSpec.describe AccountsController, type: :controller do
  before do
    set_up_test_accounts
    create_test_payment
    create_test_purchase
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
  end
end

RSpec.feature "Accounts", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
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
end

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
end

RSpec.describe AccountsController, type: :controller do
  before do
    set_up_test_accounts
    create_test_payment
    create_test_purchase
  end

  describe "POST create" do
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

RSpec.feature "Accounts", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
  end

  scenario "User creates new account with invalid params" do
    visit "/accounts"
    click_on("New account")
    click_button("Submit")

    alert = find(".alert-danger")
    expect(alert).to have_content("Name can't be blank")
  end
end

RSpec.describe Event, type: :model do
  before do
    set_up_test_accounts
  end

  describe ".create_payment" do
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
end

RSpec.describe EventsController, type: :controller do
  before do
    set_up_test_accounts
    create_test_payment
    create_test_purchase
  end

  describe "POST create_payment" do
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
end

RSpec.feature "Events", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
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
end

RSpec.describe Event, type: :model do
  before do
    set_up_test_accounts
  end

  describe ".create_purchase" do
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
end

RSpec.describe EventsController, type: :controller do
  before do
    set_up_test_accounts
    create_test_payment
    create_test_purchase
  end

  describe "POST create_purchase" do
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

RSpec.feature "Events", type: :feature do
  before do
    set_up_test_accounts
    @payment = create_test_payment
    @purchase = create_test_purchase
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

RSpec.describe "GET /", type: :request do
  it "redirects to /accounts" do
    get "/"
    expect(response).to redirect_to("/accounts")
  end
end

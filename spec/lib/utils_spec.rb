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

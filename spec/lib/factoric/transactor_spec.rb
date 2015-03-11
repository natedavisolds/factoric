describe Factoric::Transactor do

  class TestTransactor
    include Factoric::Transactor

    set_entity "Test"

    translate "foo", "bar"
  end

  it "#for_portfolio_id looks up the portfolio" do
    portfolio_class = double
    portfolio = double base_id: 7
    expect(portfolio_class).to receive(:find).with(8).once.and_return(portfolio)

    transactor = TestTransactor.for_portfolio_id 8, portfolio_class

    committed_fact = transactor.remember(model: "Civic").first

    expect(committed_fact.fact_key).to eq "model"
    expect(committed_fact.value).to eq "Civic"
    expect(committed_fact.happened_at).to be_a Time
    expect(committed_fact.base_id).to eq 7
    expect(committed_fact.entity).to eq "Test"
    expect(committed_fact.entity_id).to eq committed_fact.id
  end

  it "instantiates a transactor with a portfolio" do
    portfolio = double :portfolio, base_id: 1
    transactor = TestTransactor.for_portfolio portfolio

    committed_fact = transactor.remember(model: "Civic").first

    expect(committed_fact.fact_key).to eq "model"
    expect(committed_fact.value).to eq "Civic"
    expect(committed_fact.happened_at).to be_a Time
    expect(committed_fact.base_id).to eq 1
    expect(committed_fact.entity).to eq "Test"
    expect(committed_fact.entity_id).to eq committed_fact.id
  end

  it "saves a historical details record when passed a hash of information" do
    transactor = TestTransactor.for_base_id 1

    committed_fact = transactor.remember(model: "Civic").first

    expect(committed_fact.fact_key).to eq "model"
    expect(committed_fact.value).to eq "Civic"
    expect(committed_fact.happened_at).to be_a Time
    expect(committed_fact.base_id).to eq 1
    expect(committed_fact.entity).to eq "Test"
    expect(committed_fact.entity_id).to eq committed_fact.id
  end

  it "creates only one historical detail when passing a date" do
    transactor = TestTransactor.for_base_id 1

    committed_facts = transactor.remember(model: Time.now)

    expect(committed_facts.length).to eq 1
  end

  it "starts a household when a base_id isn't given" do
    transactor = TestTransactor.new nil

    transactor.remember foo: "bar"

    expect(transactor.base_id).to_not be_nil
  end

  it "uses the id of the first historical detail as the entity_id when no id is given" do
    transactor = TestTransactor.for_base_id 1

    committed_facts = transactor.remember(model: "Civic", make: "Honda")

    generated_id = committed_facts.first.entity_id

    expect(generated_id).to_not be_nil

    expect(committed_facts.first.fact_key).to eq "model"
    expect(committed_facts.first.value).to eq "Civic"
    expect(committed_facts.first.happened_at).to be_a Time
    expect(committed_facts.first.base_id).to eq 1
    expect(committed_facts.first.entity).to eq "Test"
    expect(committed_facts.first.entity_id).to eq generated_id

    expect(committed_facts.last.fact_key).to eq "make"
    expect(committed_facts.last.value).to eq "Honda"
    expect(committed_facts.last.happened_at).to be_a Time
    expect(committed_facts.last.base_id).to eq 1
    expect(committed_facts.last.entity).to eq "Test"
    expect(committed_facts.last.entity_id).to eq generated_id
  end

  it "sets the id" do
    transactor = TestTransactor.for_base_id 1
    transactor.remember(id: 3453453, model: "Civic", make: "Honda")

    expect(transactor.entity_id).to eq 3453453
  end

  it "remembers multiple facts about vehicles to historical details record when passed a hash of information" do
    transactor = TestTransactor.for_base_id 1

    expect {
      transactor.remember(model: "Civic", make: "Honda", estimated_value: 45.00)
    }.to change {
      Factoric::FactStore.count
    }.by 3

    expect(transactor.entity_id).to_not be_nil
  end

  it "ignores question marks in keys" do
    transactor = TestTransactor.for_base_id 1
    facts = transactor.remember(model?: "Civic")

    expect(facts.first.fact_key).to eq "model"
  end

  context "when forgetting" do
    it "adds a historical_detail for the id" do
      transactor = TestTransactor.for_base_id 1
      fact = transactor.remember( model: "Civic", make: "Honda", estimated_value: 45.00).first

      expect {
        transactor.forget fact.entity_id
      }.to change {
        Factoric::FactStore.count
      }.by 1
    end

    it "adds a forget for the id" do
      transactor = TestTransactor.for_base_id 1
      fact = transactor.remember(model: "Civic").first

      committed_fact = transactor.forget(fact.entity_id).first

      expect(committed_fact).to be_forgotten
      expect(committed_fact.fact_key).to eq ""
      expect(committed_fact.value).to eq ""
      expect(committed_fact.happened_at).to be_a Time
      expect(committed_fact.base_id).to eq 1
      expect(committed_fact.entity).to eq "Test"
      expect(committed_fact.entity_id).to eq fact.entity_id
    end

    it "adds a forget for the id and fact_key" do
      transactor = TestTransactor.for_base_id 1
      fact = transactor.remember(model: "Civic").first

      committed_fact = transactor.forget(fact.entity_id, "model").first

      expect(committed_fact).to be_forgotten
      expect(committed_fact.fact_key).to eq "model"
      expect(committed_fact.value).to eq ""
      expect(committed_fact.happened_at).to be_a Time
      expect(committed_fact.base_id).to eq 1
      expect(committed_fact.entity).to eq "Test"
      expect(committed_fact.entity_id).to eq fact.entity_id
    end

    it "translates the key" do
      transactor = TestTransactor.for_base_id 1

      expect(transactor.send(:translate_keys, { "foo" => "baz"})).to eq "bar" => "baz"
    end

    it "adds a forget for the id, fact_key, and value" do
      transactor = TestTransactor.for_base_id 1
      fact = transactor.remember(model: "Civic").first

      committed_fact = transactor.forget(fact.entity_id, "model", "Civic").first

      expect(committed_fact).to be_forgotten
      expect(committed_fact.fact_key).to eq "model"
      expect(committed_fact.value).to eq "Civic"
      expect(committed_fact.happened_at).to be_a Time
      expect(committed_fact.base_id).to eq 1
      expect(committed_fact.entity).to eq "Test"
      expect(committed_fact.entity_id).to eq fact.entity_id
    end
  end
end

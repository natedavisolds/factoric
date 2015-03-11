describe Factoric::Transactor do

  class TestTransactor
    include Factoric::Transactor

    set_entity "Test"

    translate "foo", "bar"
  end

  it "#for_portfolio_id looks up the portfolio" do
    portfolio_class = double
    portfolio = double base_id: 7
    portfolio_class.should_receive(:find).with(8).once.and_return(portfolio)

    transactor = TestTransactor.for_portfolio_id 8, portfolio_class

    committed_fact = transactor.remember(model: "Civic").first

    committed_fact.fact_key.should == "model"
    committed_fact.value.should == "Civic"
    committed_fact.happened_at.should be_a Time
    committed_fact.base_id.should == 7
    committed_fact.entity.should == "Test"
    committed_fact.entity_id.should == committed_fact.id
  end

  it "instantiates a transactor with a portfolio" do
    portfolio = double :portfolio, base_id: 1
    transactor = TestTransactor.for_portfolio portfolio

    committed_fact = transactor.remember(model: "Civic").first

    committed_fact.fact_key.should == "model"
    committed_fact.value.should == "Civic"
    committed_fact.happened_at.should be_a Time
    committed_fact.base_id.should == 1
    committed_fact.entity.should == "Test"
    committed_fact.entity_id.should == committed_fact.id
  end

  it "saves a historical details record when passed a hash of information" do
    transactor = TestTransactor.for_base_id 1

    committed_fact = transactor.remember(model: "Civic").first

    committed_fact.fact_key.should == "model"
    committed_fact.value.should == "Civic"
    committed_fact.happened_at.should be_a Time
    committed_fact.base_id.should == 1
    committed_fact.entity.should == "Test"
    committed_fact.entity_id.should == committed_fact.id
  end

  it "creates only one historical detail when passing a date" do
    transactor = TestTransactor.for_base_id 1

    committed_facts = transactor.remember(model: Time.now)

    committed_facts.length.should == 1
  end

  it "starts a household when a base_id isn't given" do
    transactor = TestTransactor.new nil

    transactor.remember foo: "bar"

    transactor.base_id.should_not be_nil
  end

  it "uses the id of the first historical detail as the entity_id when no id is given" do
    transactor = TestTransactor.for_base_id 1

    committed_facts = transactor.remember(model: "Civic", make: "Honda")

    generated_id = committed_facts.first.entity_id

    generated_id.should_not be_nil

    committed_facts.first.fact_key.should == "model"
    committed_facts.first.value.should == "Civic"
    committed_facts.first.happened_at.should be_a Time
    committed_facts.first.base_id.should == 1
    committed_facts.first.entity.should == "Test"
    committed_facts.first.entity_id.should == generated_id

    committed_facts.last.fact_key.should == "make"
    committed_facts.last.value.should == "Honda"
    committed_facts.last.happened_at.should be_a Time
    committed_facts.last.base_id.should == 1
    committed_facts.last.entity.should == "Test"
    committed_facts.last.entity_id.should == generated_id
  end

  it "sets the id" do
    transactor = TestTransactor.for_base_id 1
    transactor.remember(id: 3453453, model: "Civic", make: "Honda")

    transactor.entity_id.should == 3453453
  end

  it "remembers multiple facts about vehicles to historical details record when passed a hash of information" do
    transactor = TestTransactor.for_base_id 1

    expect {
      transactor.remember(model: "Civic", make: "Honda", estimated_value: 45.00)
    }.to change {
      Factoric::FactStore.count
    }.by 3

    transactor.entity_id.should_not be_nil
  end

  it "ignores question marks in keys" do
    transactor = TestTransactor.for_base_id 1
    facts = transactor.remember(model?: "Civic")

    facts.first.fact_key.should == "model"
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

      committed_fact.should be_forgotten
      committed_fact.fact_key.should == ""
      committed_fact.value.should == ""
      committed_fact.happened_at.should be_a Time
      committed_fact.base_id.should == 1
      committed_fact.entity.should == "Test"
      committed_fact.entity_id.should == fact.entity_id
    end

    it "adds a forget for the id and fact_key" do
      transactor = TestTransactor.for_base_id 1
      fact = transactor.remember(model: "Civic").first

      committed_fact = transactor.forget(fact.entity_id, "model").first

      committed_fact.should be_forgotten
      committed_fact.fact_key.should == "model"
      committed_fact.value.should == ""
      committed_fact.happened_at.should be_a Time
      committed_fact.base_id.should == 1
      committed_fact.entity.should == "Test"
      committed_fact.entity_id.should == fact.entity_id
    end

    it "translates the key" do
      transactor = TestTransactor.for_base_id 1

      transactor.send(:translate_keys, { "foo" => "baz"}).should == { "bar" => "baz"}
    end

    it "adds a forget for the id, fact_key, and value" do
      transactor = TestTransactor.for_base_id 1
      fact = transactor.remember(model: "Civic").first

      committed_fact = transactor.forget(fact.entity_id, "model", "Civic").first

      committed_fact.should be_forgotten
      committed_fact.fact_key.should == "model"
      committed_fact.value.should == "Civic"
      committed_fact.happened_at.should be_a Time
      committed_fact.base_id.should == 1
      committed_fact.entity.should == "Test"
      committed_fact.entity_id.should == fact.entity_id
    end
  end
end

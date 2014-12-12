describe Factoric::Base do
  def create_facts definitions={}
    entity = definitions.delete(:entity) || "Household"
    entity_id = definitions.delete(:entity_id)
    facts = []

    definitions.each do |key, value|
      facts << double('historical_detail', fact_key: key.to_s, value: value.to_s, forgotten?: false, forgotten_all?: false, forgotten_key?: false, entity: entity, entity_id: entity_id, happened_at: DateTime.now)
    end

    facts
  end    

  class EntityExample
    include ::Factoric::Entity

    fact "amount", convert_to: 'amount'
  end

  class BaseExample
    include ::Factoric::Base

    has_many_entities :entity_examples
  end

  it "has no entity_examples when no facts are given" do
    base_example = BaseExample.new 4, {}

    expect(base_example.entity_examples).to be_empty
  end

  it "builds a historical_entity_example when facts are given" do
    facts = create_facts(entity: "EntityExample", entity_id: 6, amount: "56.35")

    base_example = BaseExample.new 4, facts

    entity_examples = base_example.entity_examples

    expect(entity_examples).to_not be_empty
    expect(entity_examples.first.amount).to eq 56.35
  end

  it "doesn't retrieve a entity_example when it doesn't exist" do
    facts = create_facts(entity: "EntityExample", entity_id: 6, amount: "56.35")

    subject = BaseExample.new 4, facts

    entity_example = subject.entity_example(7)

    expect(entity_example).to be_nil
  end

  it "return a entity_example that match id" do
    facts = create_facts(entity: "EntityExample", entity_id: 6, amount: "56.35")

    subject = BaseExample.new 4, facts

    entity_example = subject.entity_example(6)

    expect(entity_example).to_not be_nil
    expect(entity_example.amount).to eq 56.35
  end
end
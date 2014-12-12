describe Factoric::Entity do
  class ValueTest
    include Factoric::Entity

    set_factoric_base_name_as :household

    fact "make", convert_to: "string"
    fact "model"
    fact "amount_value", convert_to: "amount"
    fact "integer_value", convert_to: "integer"
    fact "boolean_value", convert_to: "boolean"
    fact "date_value", convert_to: "datetime"
    fact "defaulted_value", convert_to: "amount", default: 0.0
    attr_collection "array_values", convert_to: "integer"
    attr_collection "ignore_value_array", convert_to: "integer", ignore_value: ''
    fact "custom_value", convert_to: "custom" do |v|
      "Something fancy with #{v}."
    end
    fact "use_default_value", convert_to: "integer", default: nil, use_default_for: ''
  end

  let(:one_day) { 86400 }
  let(:recent_date) { Time.now - one_day }
  let(:later_date) { Time.now - (7 * one_day) }

  it "retains the id" do
    vehicle = ValueTest.build 4, []
    expect(vehicle.id).to eq 4
  end

  it "allows for a household to be passed in" do
    household = double
    vehicle = ValueTest.build 4, [], household
    expect(vehicle.household).to eq household
  end

  class ClassFactKeyTestEntity
    include Factoric::Entity

    set_factoric_base_name_as :household

    fact "some_test"
  end

  it "has a list of all the fact keys" do
    expect(ClassFactKeyTestEntity.historical_detail_fact_keys).to include "some_test"
  end

  it "adds values from details" do
    detail = double entity_id: 4, fact_key: "make", value: "Curiosity", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false

    vehicle = ValueTest.build 4, [detail]

    expect(vehicle.make).to eq "Curiosity"
  end

  it "default to a specified value if no fact exists" do
    detail = double entity_id: 4, fact_key: "make", value: "Curiosity", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false

    vehicle = ValueTest.build 4, [detail]

    expect(vehicle.defaulted_value).to eq 0.0
  end

  it "adds different values from details" do
    detail1 = double entity_id: 4, fact_key: "make", value: "Curiosity", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    detail2 = double entity_id: 4, fact_key: "model", value: "NASA", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false

    vehicle = ValueTest.build 4, [detail1, detail2]

    expect(vehicle.make).to eq "Curiosity"
    expect(vehicle.model).to eq "NASA"
  end

  it "only adds the most recent value" do
    detail1 = double entity_id: 4, fact_key: "make", value: "Curiosity", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    detail2 = double entity_id: 4, fact_key: "make", value: "Columbia", happened_at: later_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false

    vehicle = ValueTest.build 4, [detail1, detail2]

    expect(vehicle.make).to eq "Curiosity"
  end

  it "only adds the most recent value even if last" do
    detail1 = double entity_id: 4, fact_key: "make", value: "Curiosity", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    detail2 = double entity_id: 4, fact_key: "make", value: "Columbia", happened_at: later_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false

    vehicle = ValueTest.build 4, [detail2, detail1]

    expect(vehicle.make).to eq "Curiosity"
  end

  context 'when forgetting' do
    it "only forgets when matching string facts return blank" do
      detail1 = double entity_id: 4, fact_key: "make", value: "Curiosity", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
      detail2 = double entity_id: 4, fact_key: "make", value: "forgettable", happened_at: later_date, forgotten?: true, forgotten_all?: false, forgotten_key?: false

      vehicle = ValueTest.build 4, [detail2, detail1]

      expect(vehicle.make).to eq "Curiosity"
    end

    it "string facts return blank" do
      detail1 = double entity_id: 4, fact_key: "make", value: "Curiosity", started_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
      detail2 = double entity_id: 4, fact_key: "", value: "", started_at: later_date, forgotten?: true, forgotten_all?: true, forgotten_key?: false

      vehicle = ValueTest.build 4, [detail2, detail1]

      expect(vehicle).to be_nil
    end
  end

  it "converts to a BigDecimal" do
    detail1 = double entity_id: 4, fact_key: "amount_value", value: "45.96", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle = ValueTest.build 4, [detail1]

    expect(vehicle.amount_value).to eq 45.96
  end

  it "converts to an Integer" do
    detail1 = double entity_id: 4, fact_key: "integer_value", value: "46", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle = ValueTest.build 4, [detail1]

    expect(vehicle.integer_value).to eq 46
  end

  it "converts to an Boolean true" do
    detail1 = double entity_id: 4, fact_key: "boolean_value", value: "true", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle = ValueTest.build 4, [detail1]

    expect(vehicle.boolean_value).to eq true
  end

  it "converts to an Boolean true" do
    detail1 = double entity_id: 4, fact_key: "boolean_value", value: "1", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle = ValueTest.build 4, [detail1]

    expect(vehicle.boolean_value).to eq true
  end

  it "converts to an Boolean false" do
    detail1 = double entity_id: 4, fact_key: "boolean_value", value: "false", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle = ValueTest.build 4, [detail1]

    expect(vehicle.boolean_value).to eq false
  end

  it "converts to an Boolean false" do
    detail1 = double entity_id: 4, fact_key: "boolean_value", value: "0", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle = ValueTest.build 4, [detail1]

    expect(vehicle.boolean_value).to eq false
  end

  context "DateTime conversion" do
    it "converts to a DateTime when the date is valid" do
      detail1 = double entity_id: 4, fact_key: "date_value", value: "2013-04-03 0:0", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
      vehicle = ValueTest.build 4, [detail1]

      expect(vehicle.date_value).to eq DateTime.new(2013, 04, 03)
    end

    it "returns nil if the value is not a valid date" do
      [nil, "", "2013"].each do |val|
        detail1 = double entity_id: 4, fact_key: "date_value", value: val, happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
        vehicle = ValueTest.build 4, [detail1]

        expect(vehicle.date_value).to be_nil
      end
    end
  end

  it "converts to an Array" do
    detail1 = double entity_id: 4, fact_key: "array_values", value: "1", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    detail2 = double entity_id: 4, fact_key: "array_values", value: "2", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    detail3 = double entity_id: 4, fact_key: "array_values", value: "3", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false

    vehicle = ValueTest.build 4, [detail1, detail2, detail3]

    expect(vehicle.array_values).to eq [1,2,3]
  end

  it "does not add the fact to a collection when the value matches the ignored value" do
    detail = double entity_id: 4, fact_key: "ignore_value_array", value: '', happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false

    vehicle = ValueTest.build 4, [detail]
    expect(vehicle.ignore_value_array).to be_empty
  end

  it "converts to a CustomValue" do
    detail1 = double entity_id: 4, fact_key: "custom_value", value: "the passed value", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle = ValueTest.build 4, [detail1]

    expect(vehicle.custom_value).to eq "Something fancy with the passed value."
  end

  it "establishes equality when id values match" do
    detail = double entity_id: 1, fact_key: "test", value: "1", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle1 = ValueTest.build 1, [detail]
    vehicle2 = ValueTest.build 1, [detail]
    expect(vehicle1).to eq vehicle2
    expect(vehicle1).to be_eql vehicle2
  end

  it "establishes inequality when id values differ" do
    detail = double entity_id: 1, fact_key: "test", value: "1", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle1 = ValueTest.build 1, [detail]
    vehicle2 = ValueTest.build 2, [detail]
    expect(vehicle1).to_not eq vehicle2
  end

  it "creates a hash from id" do
    detail = double entity_id: 1, fact_key: "test", value: "1", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle = ValueTest.build 1, [detail]
    expect(vehicle.hash).to eq vehicle.id.hash
  end

  it "allows Array#uniq to return unique objects based on id" do
    detail = double entity_id: 1, fact_key: "test", value: "1", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    vehicle1 = ValueTest.build 1, [detail]
    vehicle2 = ValueTest.build 1, [detail]
    expect([vehicle1, vehicle2].uniq).to eq [vehicle1]
  end

  it "returns the default value when the specified value is encountered" do
    detail = double entity_id: 1, fact_key: "use_default_value", value: "", happened_at: recent_date, forgotten?: false, forgotten_all?: false, forgotten_key?: false
    obj = ValueTest.build 1, [detail]
    expect(obj.use_default_value).to be_nil
  end
end

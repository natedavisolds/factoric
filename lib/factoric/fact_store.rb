module Factoric
  class Fact
    def initialize attributes={}
      @raw = attributes
    end

    def id
      raw[:id]
    end

    def entity_id
      raw[:entity_id]
    end

    def fact_key
      raw[:fact_key]
    end

    def value
      raw[:value]
    end

    def happened_at
      raw[:happened_at]
    end

    def entity
      raw[:entity]
    end

    def base_id
      raw[:base_id]
    end

    def forgotten?
      raw[:forget] == true
    end

    def update_attributes attributes={}
      @raw.merge! attributes
    end

    private

    attr_reader :raw
  end

  class FactStore

    def self.attribs
      @attribs ||= []
    end

    def self.count
      attribs.length
    end

    def self.create attributes
      attributes[:id] ||= count + 1

      fact = Fact.new(attributes)
      attribs.push fact
      fact
    end
  end
end
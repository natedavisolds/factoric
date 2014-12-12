require 'active_support/inflector'
require 'inflections'

module Factoric
  module Base
    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods
      def find id, options={}
        fact_class = options.fetch(:fact_class) { HistoricalDetail }
        timestamp = options.fetch(:at) { DateTime.now }

        facts = fact_class.find_before id, timestamp

        build id, facts
      end

      def build_from_details details=[]
        facts = [*details]

        if facts.length > 0
          id = facts.first.entity_id
          build id, facts
        end
      end

      def build id, facts
        new id, facts
      end

      def has_many_entities entity, options={}
        singular = entity.to_s.singularize
        entity_class = options.fetch(:entity_class, singular.classify.constantize)
        plural = singular.pluralize
        instance_var = "@#{plural}"

        define_method singular do |id|
          send(plural).detect { |v| v.id == id.to_i }
        end

        define_method plural do
          if instance_variable_defined?(instance_var)
            instance_variable_get(instance_var)
          else
            entities = build_entities entity_class
            instance_variable_set(instance_var, entities)
            entities
          end
        end
      end
    end

    attr_reader :id, :specifics, :entity_facts

    def initialize id, facts
      @id = id
      @entity_facts = {}

      facts.group_by(&:entity).each do |entity, related_facts|
        entity_name = entity == "" ? "household" : entity.downcase

        @entity_facts[entity_name] = [] unless @entity_facts.has_key? entity_name
        @entity_facts[entity_name] += related_facts
      end

      @specifics = facts_by_fact_key entity_facts.fetch("household", {})
    end

    def build_entities historic_entity
      entities = []

      facts = entity_facts.fetch(historic_entity.param_key, [])

      facts.group_by(&:entity_id).each do |entity_id, details|
        entity = historic_entity.build(entity_id, details, self)
        entities << entity unless entity.nil?
      end

      entities.sort { |a,b| a.id <=> b.id }
    end

    def facts_by_fact_key facts=[]
      results = {}

      facts.group_by(&:fact_key).each do |fact_key, grouped_facts|
        results[fact_key] = grouped_facts.sort { |a,b| b.happened_at <=> a.happened_at }
      end

      results
    end
  end
end

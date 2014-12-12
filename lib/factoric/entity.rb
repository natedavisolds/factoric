require 'bigdecimal'
require 'date'

module Factoric
  module Entity
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      CONVERTERS = {
        "string" => Proc.new { |v| v || "" },
        "symbol" => Proc.new { |v| v.blank? ? nil : v.to_sym },
        "integer" => Proc.new { |v| v.to_i },
        "amount" => Proc.new { |v|
          v = 0 if v.nil?
          BigDecimal.new(v).round(2)
        },
        "boolean" => Proc.new { |v| v == "true" || v == "1"},
        "datetime" => Proc.new { |v| DateTime.parse(v) rescue nil },
        "custom" => Proc.new { |v, &block| block.call(v) }
      }

      def model_name
        self
      end

      def param_key
        model_name.to_s.downcase
      end

      def build_from_details details=[], base=nil
        facts = [*details]

        if facts.length > 0
          id = facts.first.entity_id
          build id, facts, base
        end
      end

      def build id, details, base=nil
        return nil if details.any? &:forgotten_all?

        facts = {}

        details.group_by(&:fact_key).each do |fact_key, grouped_facts|
          facts[fact_key] = grouped_facts.sort { |a,b| b.happened_at <=> a.happened_at }
        end

        new id, facts, base
      end

      def attr_collection name, options={}
        converter_key = options.fetch(:convert_to, "string")
        converter = CONVERTERS.fetch(converter_key) { converters["string"] }
        ignored_value = options.fetch(:ignore_value, nil)
        self.historical_detail_collection_keys << name

        define_method name do
          collection = []

          relevant_specifics(name.to_s).group_by(&:value).each do |value, facts|
            recent_fact = facts.first
            collection << converter.call(recent_fact.value) unless recent_fact.forgotten? || recent_fact.value == ignored_value
          end

          collection.compact.uniq.sort{|a, b| a <=> b}
        end
      end

      def set_factoric_base_name_as name
        define_method name do
          base
        end
      end

      def historical_detail_fact_keys
        @historical_detail_fact_keys ||= []
      end

      def historical_detail_collection_keys
        @historical_detail_collection_keys ||= []
      end

      def fact name, options={}, &block
        default_value = options.fetch(:default, nil)
        converter_key = options.fetch(:convert_to, "string")
        use_default_for_value = options.fetch(:use_default_for, nil)
        converter = CONVERTERS.fetch(converter_key) { converters["string"] }
        instance_var = "@#{name}"
        self.historical_detail_fact_keys << name

        define_method name do
          if instance_variable_defined?(instance_var)
            instance_variable_get(instance_var)
          else
            facts = [*specifics[name.to_s]]
            return default_value if facts.empty?

            first_fact = facts.first
            value = if first_fact.forgotten? || first_fact.value == use_default_for_value
              default_value
            else
              converter.call(first_fact.value, &block)
            end

            instance_variable_set(instance_var, value)
          end
        end
      end

      def redefine_fact key, alias_key="fact_#{key}".to_sym, &block
        alias_method alias_key, key
        define_method key, &block
      end
    end

    def initialize id, specifics={}, base=nil
      @id = id
      @specifics = {}
      @base = base

      specifics.each { |k, v| @specifics[k.to_s] = v }
    end

    def relevant_specifics fact_key
      [*specifics[fact_key]].take_while do |detail|
        !detail.forgotten_key?
      end
    end

    def inspect
      vars = [:@id].map {|v| "#{v}=#{instance_variable_get(v)}" }
      vars += self.class.historical_detail_fact_keys.collect do |v|
        value = send(v)

        if value.present?
          "#{v}=#{value}"
        end
      end.compact

      "<#{self.class}: #{vars.join(", ") }>"
    end

    def id
      @id
    end
    alias :to_param :id

    def to_key
      [*id]
    end

    def specifics
      @specifics
    end

    def base
      @base
    end

    def == candidate
      return false if candidate.nil?
      candidate_id = candidate.respond_to?(:id) ? candidate.id : candidate
      id == candidate_id
    end
    alias :eql? :==

    def != candidate
      !(self.== candidate)
    end

    def hash
      id.hash
    end
  end
end
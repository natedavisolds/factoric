require 'active_support/core_ext'

module Factoric
  module Transactor
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def for_portfolio_id portfolio_id, portfolio_class=Portfolio
        for_portfolio portfolio_class.find(portfolio_id)
      end

      def for_portfolio portfolio
        for_base_id portfolio.base_id
      end

      def for_base_id id
        new id
      end

      def set_entity entity
        define_method :entity do
          "#{entity}"
        end
      end

      def translate from, to
        translations[from] = to
      end

      def translations
        @translations ||= {}
      end
    end

    attr_reader :entity_id
    attr_reader :base_id

    def initialize base_id
      @base_id = base_id
    end

    def remember params={}
      attributes = translate_keys(params).stringify_keys

      @entity_id = attributes.delete("id") || generate_new_id
      happened_at = attributes.delete("happened_at") || Time.now

      committed_facts = []

      attributes.each do |key, values|
        if values.is_a? Array
          forget entity_id, key if entity_id.present?
        else
          values = [values]
        end

        values.each do |value|
          fact = FactStore.create({
            fact_key: key.to_s,
            value: value.to_s,
            happened_at: happened_at,
            base_id: base_id,
            entity: entity,
            entity_id: entity_id,
            delta: true
          })

          if base_id.nil?
            fact.update_attributes base_id: fact.id
            @base_id = fact.id
          end

          if @entity_id.nil?
            @entity_id = fact.id
            fact.update_attributes entity_id: @entity_id
          end
          
          committed_facts << fact
        end
      end

      syncronize_search if changing_searchable_fields? params.keys

      committed_facts
    end

    def forget id, key="", values=""
      details = [*values].collect do |value|
        FactStore.create({
          fact_key: key,
          value: value,
          happened_at: Time.now,
          base_id: base_id,
          entity: entity,
          entity_id: id,
          forget: true,
          delta: true
        })
      end

      syncronize_search if changing_searchable_fields? key

      details
    end

    private

    def changing_searchable_fields? keys
      ([*keys].map(&:to_s) & searchable_fields).present?
    end

    def syncronize_search
      Delayed::Job.enqueue(SearchSyncronizerJob.new(base_id))
    end

    def translations
      self.class.translations
    end

    def translate_keys hash={}
      params = {}

      hash.each do |key, value|
        use_key = if translations.has_key? key.to_s
          translations[key.to_s]
        else
          key.to_s.gsub(/\?/,'')
        end

        params[use_key] = value if acceptable_param? use_key
      end

      params
    end

    def searchable_fields
      [
        "first_name",
        "last_name",
        "ssn",
        "phone_number",
        "address_1",
        "address_2",
        "city",
        "state",
        "zip_code",
        "mailing_address_1",
        "mailing_address_2",
        "mailing_city",
        "mailing_state",
        "mailing_zip_code"
      ]
    end

    def acceptable_param? candidate
      true
    end

    def generate_new_id
      nil
    end
  end
end

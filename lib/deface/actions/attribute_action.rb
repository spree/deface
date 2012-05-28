module Deface
  module Actions
    class AttributeAction < Action
      attr_reader :attributes

      def initialize(options = {})
        super options
        @attributes = options[:attributes]
        raise(DefaceError, "No attributes option specified") unless @attributes
      end

      def execute(target_element)
        target_element = target_element.first
        attributes.each do |name, value|
          execute_for_attribute(target_element, normalize_attribute_name(name), value)
        end
      end

      protected

      def normalize_attribute_name(name)
        name = name.to_s.gsub(/"|'/, '')

        if /\Adata-erb-/ =~ name
          name.gsub!(/\Adata-erb-/, '')
        end

        name
      end

    end
  end
end
module Deface
  module DSL
    class Context
      def initialize(name)
        @name = name
        @options = {}
      end

      def create_override
        options = {
          :name => @name, 
          :virtual_path => @virtual_path,
        }.merge(@action || {}).merge(@source || {}).merge(@options)

        Deface::Override.new(options)
      end

      def virtual_path(name)
        @virtual_path = name
      end

      Deface::Override.actions.each do |action_name|
        define_method(action_name) do |selector|
          if @action.present?
            Rails.logger.error "\e[1;32mDeface: [WARNING]\e[0m Multiple action methods have been called. The last one will be used."
          end

          @action = { action_name => selector }
        end
      end

      Deface::Override.sources.each do |source_name|
        define_method(source_name) do |value|
          if @source.present?
            Rails.logger.error "\e[1;32mDeface: [WARNING]\e[0m Multiple source methods have been called. The last one will be used."
          end

          @source = { source_name => value }
        end
      end

      def original(markup)
        @options[:original] = markup
      end

      def closing_selector(selector)
        @options[:closing_selector] = selector
      end

      def sequence(value)
        @options[:sequence] = value
      end

      def attributes(values)
        @options[:attributes] = values
      end

      def enabled
        @options[:disabled] = false
      end

      def disabled
        @options[:disabled] = true
      end
    end
  end
end
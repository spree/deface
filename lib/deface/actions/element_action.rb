module Deface
  module Actions
    class ElementAction < Action
      attr_reader :source_element

      def initialize(options = {})
        super(options)
        @source_element = options[:source_element]
        raise(DefaceError, "No source_element option specified") unless @source_element
      end
    end
  end
end
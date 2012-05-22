module Deface
  module Actions
    class Replace < ElementAction
      def execute target_element
        execute_on_range([target_element])
      end

      def execute_on_range target_range
        target_range.first.before(source_element)
        target_range.map(&:remove)
      end

      def range_compatible?
        true
      end
    end
  end
end
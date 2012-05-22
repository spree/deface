module Deface
  module Actions
    class Replace < ElementAction
      def execute target_element
        target_element.replace source_element
      end

      def execute_on_range target_range
        target_range.first.before(source_element)
        target_range.map(&:remove)
      end
    end
  end
end
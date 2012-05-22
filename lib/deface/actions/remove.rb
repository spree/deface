module Deface
  module Actions
    class Remove < Action
      def execute target_element
        target_element.replace ""
      end

      def execute_on_range target_range
        target_range.map(&:remove)
      end
    end
  end
end
module Deface
  module Actions
    class Remove < Action
      def execute target_element
        target_element.replace ""
      end
    end
  end
end
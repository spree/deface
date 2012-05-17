module Deface
  module Actions
    class Surround < SurroundAction
      def execute target_element
        original_placeholder.replace target_element.clone(1)
        target_element.replace source_element
      end
    end
  end
end
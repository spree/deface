module Deface
  module Actions
    class SurroundContents < SurroundAction
      def execute target_element
        original_placeholder.replace target_element.children
        target_element.children.remove
        target_element.add_child source_element
      end
    end
  end
end
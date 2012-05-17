module Deface
  module Actions
    class ReplaceContents < ElementAction
      def execute target_element
        target_element.children.remove
        target_element.add_child source_element
      end
    end
  end
end
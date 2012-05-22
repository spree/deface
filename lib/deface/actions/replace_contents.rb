module Deface
  module Actions
    class ReplaceContents < ElementAction
      def execute target_element
        target_element.children.remove
        target_element.add_child source_element
      end

      def execute_on_range target_range
        target_range[1..-2].map(&:remove)
        target_range.first.after(source_element)
      end
    end
  end
end
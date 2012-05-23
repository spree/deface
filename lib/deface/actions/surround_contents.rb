module Deface
  module Actions
    class SurroundContents < SurroundAction
      def execute target_range
        if target_range.length == 1
          target_element = target_range.first
          original_placeholder.replace target_element.children
          target_element.children.remove
          target_element.add_child source_element
        else
          start = target_range[1].clone(1)
          original_placeholder.replace start

          target_range[2...-1].each do |element|
            element = element.clone(1)
            start.after element
            start = element
          end

          target_range.first.after(source_element)
          target_range[1...-1].map(&:remove)
        end
      end

      def range_compatible?
        true
      end
    end
  end
end
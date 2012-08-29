module Deface
  module Actions
    class SurroundContents < SurroundAction
      def execute(target_range)
        if target_range.length == 1
          target_element = target_range.first
          original_placeholders.each do |placeholder|
            placeholder.replace target_element.clone(1).children
          end
          target_element.children.remove
          target_element.add_child(source_element)
        else
          original_placeholders.each do |placeholder|
            start = target_range[1].clone(1)
            placeholder.replace start

            target_range[2...-1].each do |element|
              element = element.clone(1)
              start.after(element)
              start = element
            end
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
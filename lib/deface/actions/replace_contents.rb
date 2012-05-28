module Deface
  module Actions
    class ReplaceContents < ElementAction
      def execute(target_range)
        if target_range.length == 1
          target_range.first.children.remove
          target_range.first.add_child(source_element)
        else
          target_range[1..-2].map(&:remove)
          target_range.first.after(source_element)
        end
      end

      def range_compatible?
        true
      end
    end
  end
end
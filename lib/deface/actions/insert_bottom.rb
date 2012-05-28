module Deface
  module Actions
    class InsertBottom < ElementAction
      def execute(target_element)
        target_element = target_element.first
        if target_element.children.size == 0
          target_element.children = source_element
        else
          target_element.children.after(source_element)
        end
      end
    end
  end
end
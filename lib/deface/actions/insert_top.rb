module Deface
  module Actions
    class InsertTop < ElementAction
      def execute(target_element)
        target_element = target_element.first
        if target_element.children.size == 0
          target_element.children = source_element
        else
          target_element.children.before(source_element)
        end
      end
    end
  end
end
module Deface
  module Actions
    class InsertAfter < ElementAction
      def execute target_element
        target_element.after source_element
      end
    end
  end
end
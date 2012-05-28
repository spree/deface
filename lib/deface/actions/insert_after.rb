module Deface
  module Actions
    class InsertAfter < ElementAction
      def execute(target_element)
        target_element.first.after(source_element)
      end
    end
  end
end
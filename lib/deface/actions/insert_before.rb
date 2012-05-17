module Deface
  module Actions
    class InsertBefore < ElementAction
      def execute target_element
        target_element.before source_element
      end
    end
  end
end
module Deface
  module Actions
    class Replace < ElementAction
      def execute target_element
        target_element.replace source_element
      end
    end
  end
end
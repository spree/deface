module Deface
  module Actions
    class InsertBefore < ElementAction
      def execute(target_element)
        target_element.first.before(source_element)
      end
    end
  end
end
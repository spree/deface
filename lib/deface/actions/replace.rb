module Deface
  module Actions
    class Replace < ElementAction
      def execute(target_range)
        target_range.first.before(source_element)
        target_range.map(&:remove)
      end

      def range_compatible?
        true
      end
    end
  end
end
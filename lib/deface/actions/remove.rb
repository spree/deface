module Deface
  module Actions
    class Remove < Action
      def execute(target_range)
        target_range.map(&:remove)
      end

      def range_compatible?
        true
      end
    end
  end
end
module Deface
  module Actions
    class Surround < SurroundAction
      def execute(target_range)
        original_placeholders.each do |placeholder|
          start = target_range[0].clone(1)
          placeholder.replace start

          target_range[1..-1].each do |element|
            element = element.clone(1)
            start.after element
            start = element
          end
        end
        target_range.first.before(source_element)
        target_range.map(&:remove)
      end

      def range_compatible?
        true
      end
    end
  end
end

module Deface
  module Matchers
    class Range
      def initialize(name, selector, end_selector)
        @name = name
        @selector = selector
        @end_selector = end_selector
      end

      def matches(document, log=true)
        starting, ending = select_endpoints(document, @selector, @end_selector)

        if starting && ending
          if log
            Rails.logger.info("\e[1;32mDeface:\e[0m '#{@name}' matched starting with '#{@selector}' and ending with '#{@end_selector}'")
          end

          return [select_range(starting, ending)]
        else
          if starting.nil?
            Rails.logger.info("\e[1;32mDeface:\e[0m '#{@name}' failed to match with starting selector '#{@selector}'")
          else
            Rails.logger.info("\e[1;32mDeface:\e[0m '#{@name}' failed to match with end selector '#{@end_selector}'")
          end
          return []
        end
      end

      def select_endpoints(doc, start, finish)
        # targeting range of elements as end_selector is present
        #
        finish = "#{start} ~ #{finish}"
        starting    = doc.css(start).first

        ending = if starting && starting.parent
          starting.parent.css(finish).first
        else
          doc.css(finish).first
        end

        return starting, ending

      end

      # finds all elements upto closing sibling in nokgiri document
      #
      def select_range(first, last)
        first == last ? [first] : [first, *select_range(first.next, last)]
      end
    end
  end
end
module Deface
  module Matchers
    class Element
      def initialize(selector)
        @selector = selector
      end

      def matches(document, log=true)
        document.css(@selector).map { |match| [match] }
      end
    end
  end
end
module Deface
  module Actions
    class SurroundAction < ElementAction
      def source_element
        @cloned_source_element ||= super.clone(1)
      end

      def original_placeholder
        @original_placeholder ||= source_element.css("code:contains('render_original')").first
        raise(DefaceError, "The surround action couldn't find <%= render_original %> in your template") unless @original_placeholder
        @original_placeholder
      end
    end
  end
end
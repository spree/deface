module Deface
  module Actions
    class SurroundAction < ElementAction
      def source_element
        @cloned_source_element ||= super.clone(1)
      end

      def original_placeholders
        @original_placeholders ||= source_element.css("erb:contains('render_original')")
        raise(DefaceError, "The surround action couldn't find <%= render_original %> in your template") unless @original_placeholders.first
        @original_placeholders
      end
    end
  end
end

module Deface
  module TemplateHelper

    # used to find source for a partial or template using virutal_path
    def load_template_source(virtual_path, partial)
      parts = virtual_path.split("/")
      prefix = []
      if parts.size == 2
        prefix << ""
        name = virtual_path
      else
        prefix << parts.shift
        name = parts.join("/")
      end

      @lookup_context ||= ActionView::LookupContext.new(ActionController::Base.view_paths, {:formats => [:html]})

      @lookup_context.find(name, [prefix], partial).source
    end

    #gets source erb for an element
    def element_source(template_source, selector)
      doc = Deface::Parser.convert(template_source)

      doc.css(selector).inject([]) do |result, match|
        result << Deface::Parser.undo_erb_markup!(match.to_s.dup)
      end
    end
  end
end

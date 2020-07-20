ActionView::Template.class_eval do
  alias_method :initialize_without_deface, :initialize

  def initialize(source, identifier, handler, details)
    syntax = Deface::ActionViewExtensions.determine_syntax(handler)

    if syntax
      processed_source = Deface::Override.apply(source.to_param, details, true, syntax)

      # force change in handler before continuing to original Rails method
      # as we've just converted some other template language into ERB!
      #
      if [:slim, :haml].include?(syntax) && processed_source != source.to_param
        handler = ActionView::Template::Handlers::ERB
      end
    else
      processed_source = source.to_param
    end

    initialize_without_deface(processed_source, identifier, handler, details)
  end

  alias_method :render_without_deface, :render

  # refresh view to get source again if
  # view needs to be recompiled
  #
  def render(view, locals, buffer=nil, &block)
    template_class = Deface.before_rails_6? ? ActionView::CompiledTemplates : ActionDispatch::DebugView

    mod = view.is_a?(template_class) ? template_class : view.singleton_class

    if @compiled && !mod.instance_methods.include?(method_name.to_sym)
      @compiled = false
      @source = refresh(view).source
    end

    render_without_deface(view, locals, buffer, &block)
  end

  protected

    alias_method :method_name_without_deface, :method_name

    # inject deface hash into compiled view method name
    # used to determine if recompilation is needed
    #
    def method_name
      deface_hash = Deface::Override.digest(:virtual_path => @virtual_path)

      #we digest the whole method name as if it gets too long there's problems
      "_#{Deface::Digest.hexdigest("#{deface_hash}_#{method_name_without_deface}")}"
    end

end

# Rails 6 fix
# https://github.com/rails/rails/commit/ec5c946138f63dc975341d6521587adc74f6b441
# https://github.com/rails/rails/commit/ccfa01c36e79013881ffdb7ebe397cec733d15b2#diff-dfb6e0314ad9639bab460ea64871aa47R27
if defined?( ActionView::Template::Handlers::ERB::Erubi)
  ActionView::Template::Handlers::ERB::Erubi.class_eval do
    def initialize(input, properties = {})
      @newline_pending = 0

      # Dup properties so that we don't modify argument
      properties = Hash[properties]
      properties[:preamble]   = "@output_buffer = output_buffer || ActionView::OutputBuffer.new;"
      properties[:postamble]  = "@output_buffer.to_s"
      properties[:bufvar]     = "@output_buffer"
      properties[:escapefunc] = ""

      super
    end
  end
end

module Deface::ActionViewExtensions
  def self.determine_syntax(handler)
    return unless Rails.application.config.deface.enabled

    if handler.to_s == "Haml::Plugin"
      :haml
    elsif handler.class.to_s == "Slim::RailsTemplate"
      :slim
    elsif handler.to_s.demodulize == "ERB" || handler.class.to_s.demodulize == "ERB"
      :erb
    else
      nil
    end
  end
end

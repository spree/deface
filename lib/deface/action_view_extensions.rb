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

  module DefacedTemplate
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

      super(processed_source, identifier, handler, details)
    end

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

      super(view, locals, buffer, &block)
    end

    # inject deface hash into compiled view method name
    # used to determine if recompilation is needed
    #
    def method_name
      deface_hash = Deface::Override.digest(:virtual_path => @virtual_path)

      #we digest the whole method name as if it gets too long there's problems
      "_#{Deface::Digest.hexdigest("#{deface_hash}_#{super}")}"
    end

    ActionView::Template.prepend self
  end

  # Rails 6 fix.
  #
  # https://github.com/rails/rails/commit/ec5c946138f63dc975341d6521587adc74f6b441
  # https://github.com/rails/rails/commit/ccfa01c36e79013881ffdb7ebe397cec733d15b2#diff-dfb6e0314ad9639bab460ea64871aa47R27
  module ErubiHandlerFix
    def initialize(input, properties = {})
      properties[:preamble] = "@output_buffer = output_buffer || ActionView::OutputBuffer.new;"
      super
    end

    # We use include to place the module between the class' call to super and the
    # actual execution within Erubi::Engine.
    ActionView::Template::Handlers::ERB::Erubi.include self unless Deface.before_rails_6?
  end
end

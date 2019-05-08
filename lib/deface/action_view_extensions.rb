ActionView::Template.class_eval do
  alias_method :initialize_without_deface, :initialize

  def initialize(source, identifier, handler, details)
    syntax = determine_syntax(handler)

    if Rails.application.config.deface.enabled && should_be_defaced?(syntax)

      processed_source = Deface::Override.apply(source, details, true, syntax)

      # force change in handler before continuing to original Rails method
      # as we've just converted some other template language into ERB!
      #
      if [:slim, :haml].include?(syntax) && processed_source != source
        handler = ActionView::Template::Handlers::ERB
      end
    else
      processed_source = source
    end

    initialize_without_deface(processed_source, identifier, handler, details)
  end

  alias_method :render_without_deface, :render

  # refresh view to get source again if
  # view needs to be recompiled
  #
  def render(view, locals, buffer=nil, &block)

    if view.is_a?(ActionView::Base)
      mod = ActionView::Base
    else
      mod = view.singleton_class
    end

    if @compiled && !mod.instance_methods.map(&:to_s).include?(method_name)
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

  private

    def should_be_defaced?(syntax)
      syntax != :unknown
    end

    def determine_syntax(handler)
      if handler.to_s == "Haml::Plugin"
        :haml
      elsif handler.class.to_s == "Slim::RailsTemplate"
        :slim
      elsif handler.to_s.demodulize == "ERB" || handler.class.to_s.demodulize == "ERB"
        :erb
      else
        :unknown
      end
    end
end

#fix for Rails 3.1 not setting virutal_path anymore (BOO!)
if defined?(ActionView::Resolver::Path)
  ActionView::Resolver::Path.class_eval { alias_method :virtual, :to_s }
end

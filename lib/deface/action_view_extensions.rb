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
    def encode!
      return super unless Rails.application.config.deface.enabled

      # Before Rails 6 encode! returns nil
      source = Deface.before_rails_6? ? (super; @source) : super
      syntax = Deface::ActionViewExtensions.determine_syntax(@handler)
      overrides = Deface::Override.find(
        locals: @locals,
        format: @format,
        variant: @variant,
        virtual_path: @virtual_path,
      )

      if syntax && overrides.any?
        # Prevents any caching by rails in development mode.
        @updated_at = Time.now if Deface.before_rails_6?
        @handler = ActionView::Template::Handlers::ERB

        # Modify the existing string instead of returning a copy
        new_source = Deface::Override.apply_overrides(
          Deface::Override.convert_source(source, syntax: syntax),
          overrides: overrides
        )

        if Deface.before_rails_6?
          @source.replace new_source
        else
          source.replace new_source
        end
      end

      source
    end

    private

    def compile!(view)
      return super unless Rails.application.config.deface.enabled

      @compile_mutex.synchronize do
        current_deface_hash = Deface::Override.digest(virtual_path: @virtual_path)
        @deface_hash = current_deface_hash if @deface_hash.nil?

        if @deface_hash != current_deface_hash
          @compiled = nil
          @deface_hash = current_deface_hash
        end
      end

      super
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

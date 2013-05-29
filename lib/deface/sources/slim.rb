module Deface
  module Sources
    class Slim < Source
      def self.execute(override)
        if Rails.application.config.deface.slim_support
          ::Slim::ERBConverter.new.call(override.args[:slim])
        else
          raise Deface::NotSupportedError, "`#{override.name}` supplies :slim source, but slim_support is not detected."
        end
      end
    end
  end
end
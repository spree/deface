module Deface
  class Railtie < Rails::Railtie
    # include rake tasks.
    #
    rake_tasks do
      %w{utils precompile}.each { |r| load File.join([File.dirname(__FILE__) , "../../tasks/#{r}.rake"]) }
    end

    def self.activate
      if Rails.application.config.deface.enabled
        #load all overrides
        Rails.application.config.deface.overrides.load_all Rails.application
      end

    end

    config.to_prepare &method(:activate).to_proc

    # configures basic deface environment, which gets replaced
    # with real environment if deface is not disabled
    #
    initializer "deface.add_configuration", :before => :load_environment_config do |app|
      app.config.deface = ActiveSupport::OrderedOptions.new
      app.config.deface.enabled = true
    end

    # injects path for compiled views
    #
    initializer "deface.precompile.inject_views", :before => :add_view_paths do |app|
      app.paths["app/views"].unshift "app/compiled_views"
    end

    # remove app/overrides from eager_load_path for app and all railites
    # as we require them manually depending on configuration values
    #
    initializer "deface.tweak_eager_loading", :before => :set_load_path do |app|

      # application
      app.config.eager_load_paths.reject! {|path| path  =~ /app\/overrides\z/ }

      # railites / engines / extensions
      railties = if Rails.version >= "4.0"
        app.railties._all
      else
        app.railties.all
      end

      railties.each do |railtie|
        next unless railtie.respond_to?(:root) && railtie.config.respond_to?(:eager_load_paths)
        railtie.config.eager_load_paths.reject! {|path| path  =~ /app\/overrides\z/ }
      end
    end

    # sets up deface environment and requires / loads all
    # overrides if deface is enabled.
    #
    initializer "deface.environment", :after => :load_environment_config do |app|
      if app.config.deface.enabled
        # only decorate ActionView if deface is enabled
        require "deface/action_view_extensions"

        # setup real env object
        app.config.deface = Deface::Environment.new

        # checks if haml is loaded and enables support
        if defined?(Haml)
          app.config.deface.haml_support = true
          require 'deface/haml_converter'
        end

        if defined?(Slim)
          app.config.deface.slim_support = true
          require 'deface/slim_converter'
        end

        # catchs any overrides that we required manually
        app.config.deface.overrides.early_check

        if Dir.glob(app.root.join("app/compiled_views", "**/*.erb")).present?
          puts "[WARNING] Precompiled views present and Deface is enabled, this can result in overrides being applied twice."
        end
      else
        # deface is disabled so clear any overrides
        # that might have been manually required
        # won't get loaded but just in case
        Deface::Override._early.clear
      end
    end

  end
end

module Deface

  class Environment
    attr_accessor :overrides, :enabled, :haml_support
    def initialize
      @overrides    = Overrides.new
      @enabled      = true
      @haml_support = false
      @actions = [ Actions::Remove, Actions::Replace, Actions::ReplaceContents, Actions::Surround, 
        Actions::SurroundContents, Actions::InsertBefore, Actions::InsertAfter, Actions::InsertTop, 
        Actions::InsertBottom, Actions::SetAttributes, Actions::AddToAttributes, Actions::RemoveFromAttributes ]
    end

    def register_action action
      @actions << action
    end

    def actions
      @actions.dup
    end
  end

  class Environment::Overrides
    attr_accessor :all

    def initialize
      @all = {}
    end

    def find(*args)
      Deface::Override.find(*args)
    end

    def load_all(app)
      #clear overrides before reloading them
      app.config.deface.overrides.all.clear
      Deface::DSL::Loader.register

      # check all railties / engines / extensions for overrides
      app.railties.all.each do |railtie|
        next unless railtie.respond_to? :root

        override_paths = railtie.respond_to?(:paths) ? railtie.paths["app/overrides"] : nil
        enumerate_and_load(override_paths, railtie.root)
      end

      # check application for specified overrides paths
      override_paths = app.paths["app/overrides"]
      enumerate_and_load(override_paths, app.root)

    end

    def early_check
      Deface::Override._early.each do |args|
        Deface::Override.new(args)
      end

      Deface::Override._early.clear
    end

    private
      def enumerate_and_load(paths, root)
        paths ||= ["app/overrides"]

        paths.each do |path|
          if Rails.version[0..2] == "3.2"
            # add path to watchable_dir so Rails will call to_prepare on file changes
            # allowing overrides to be updated / reloaded in development mode.
            Rails.application.config.watchable_dirs[root.join(path).to_s] = [:rb, :deface]
          end

          Dir.glob(root.join path, "**/*.rb") do |c|
            Rails.application.config.cache_classes ? require(c) : load(c)
          end
          Dir.glob(root.join path, "**/*.deface") do |c|
            Rails.application.config.cache_classes ? require(c) : Deface::DSL::Loader.load(c)
          end
        end
      end
  end
end

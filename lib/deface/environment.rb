module Deface
  DEFAULT_ACTIONS = [ Actions::Remove, Actions::Replace, Actions::ReplaceContents, Actions::Surround,
        Actions::SurroundContents, Actions::InsertBefore, Actions::InsertAfter, Actions::InsertTop,
        Actions::InsertBottom, Actions::SetAttributes, Actions::AddToAttributes, Actions::RemoveFromAttributes ]

  DEFAULT_SOURCES = [ Sources::Text, Sources::Erb, Sources::Haml, Sources::Slim, Sources::Partial, Sources::Template, Sources::Cut, Sources::Copy]

  class Environment
    attr_accessor :overrides, :enabled, :haml_support, :namespaced, :slim_support
    def initialize
      @overrides    = Overrides.new
      @enabled      = true
      @haml_support = false
      @slim_support = false
      @actions      = []
      @sources      = []
      @namespaced   = false

      Deface::DEFAULT_ACTIONS.each { |action| register_action(action) }
      Deface::DEFAULT_SOURCES.each { |source| register_source(source) }
    end

    def register_action(action)
      @actions << action
      Deface::DSL::Context.define_action_method(action.to_sym)
    end

    def actions
      @actions.dup
    end

    def register_source(source)
      @sources << source
      Deface::DSL::Context.define_source_method(source.to_sym)
    end

    def sources
      @sources.dup
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
      # clear overrides before reloading them
      app.config.deface.overrides.all.clear
      Deface::DSL::Loader.register

      # check all railties / engines / extensions / application for overrides
      railties = if Rails.version >= "4.0"
        app.railties._all
      else
        app.railties.all
      end

      railties.dup.push(app).each do |railtie|
        next unless railtie.respond_to? :root
        load_overrides(railtie)
      end
    end

    def early_check
      Deface::Override._early.each do |args|
        Deface::Override.new(args)
      end

      Deface::Override._early.clear
    end

    private

      def load_overrides(railtie)
        Override.current_railtie = railtie.class.to_s
        paths = railtie.respond_to?(:paths) ? railtie.paths["app/overrides"] : nil
        enumerate_and_load(paths, railtie.root)
      end

      def enumerate_and_load(paths, root)
        paths ||= ["app/overrides"]

        paths.each do |path|
          if Rails.version[0..2] >= "3.2"
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

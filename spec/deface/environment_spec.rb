require 'spec_helper'

module Deface
  describe Environment do
    include_context "mock Rails"

    before(:each) do
      #declare this override (early) before Rails.application.deface is present
      silence_warnings do
        Deface::Override._early.clear
        Deface::Override.new(:virtual_path => "posts/edit", :name => "Posts#edit", :replace => "h1", :text => "<h1>Urgh!</h1>")
      end
    end

    include_context "mock Rails.application"

    before(:each) do
      Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
      Deface::Override.new(:virtual_path => "posts/new", :name => "Posts#new", :replace => "h1", :text => "<h1>argh!</h1>")
    end

    let(:railties_collection_accessor) { Rails.version >= "4.0" ? :_all : :all }

    describe ".overrides" do

      it "should return all overrides" do
        Rails.application.config.deface.overrides.all.size.should == 2
        Rails.application.config.deface.overrides.all.should == Deface::Override.all
      end

      it "should find overrides" do
        Rails.application.config.deface.overrides.find(:virtual_path => "posts/new").size.should == 1
      end

      describe "load_all" do

        before do
          Rails.application.stub :root => Pathname.new(File.join(File.dirname(__FILE__), '..', "assets"))
          Rails.application.stub :paths => {}
          Rails.application.stub_chain :railties, railties_collection_accessor => []

          Deface::DSL::Loader.should_receive(:register)
        end

        it "should enumerate_and_load nil when app has no app/overrides path set" do
          Rails.application.config.deface.overrides.should_receive(:enumerate_and_load).with(nil, Rails.application.root)
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should enumerate_and_load path when app has app/overrides path set" do
          Rails.application.stub :paths => {"app/overrides" => ["app/some_path"] }
          Rails.application.config.deface.overrides.should_receive(:enumerate_and_load).with(["app/some_path"] , Rails.application.root)
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should enumerate_and_load nil when railtie has no app/overrides path set" do
          Rails.application.stub_chain :railties, railties_collection_accessor => [double('railtie', :root => "/some/path")]

          Rails.application.config.deface.overrides.should_receive(:enumerate_and_load).with(nil, Rails.application.root)
          Rails.application.config.deface.overrides.should_receive(:enumerate_and_load).with(nil, "/some/path")
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should enumerate_and_load path when railtie has app/overrides path set" do
          Rails.application.stub_chain :railties, railties_collection_accessor => [ double('railtie', :root => "/some/path", :paths => {"app/overrides" => ["app/some_path"] } )]

          Rails.application.config.deface.overrides.should_receive(:enumerate_and_load).with(nil, Rails.application.root)
          Rails.application.config.deface.overrides.should_receive(:enumerate_and_load).with(["app/some_path"] , "/some/path")
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should enumerate_and_load railties first, followed by the application iteslf" do
          Rails.application.stub_chain :railties, railties_collection_accessor => [ double('railtie', :root => "/some/path", :paths => {"app/overrides" => ["app/some_path"] } )]

          Rails.application.config.deface.overrides.should_receive(:enumerate_and_load).with(["app/some_path"] , "/some/path").ordered
          Rails.application.config.deface.overrides.should_receive(:enumerate_and_load).with(nil, Rails.application.root).ordered
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should ignore railtie with no root" do
          railtie = double('railtie')
          Rails.application.stub_chain :railties, railties_collection_accessor => [railtie]

          railtie.should_receive(:respond_to?).with(:root)
          railtie.should_not_receive(:respond_to?).with(:paths)
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should clear any previously loaded overrides" do
          Rails.application.config.deface.overrides.all.should_receive(:clear)
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end


      end

      describe 'load_overrides' do
        let(:assets_path) { Pathname.new(File.join(File.dirname(__FILE__), '..', "assets")) }
        let(:engine) { double('railtie', :root => assets_path, :class => "DummyEngine", :paths => {"app/overrides" => ["dummy_engine"]}) }
        before { Rails.application.stub(:class => 'RailsAppl') }

        it "should keep a reference to which railtie/app defined the override" do
          Rails.application.stub :root => assets_path, :paths => {"app/overrides" => ["dummy_app"] }
          Rails.application.stub_chain :railties, railties_collection_accessor => [ engine ]

          Rails.application.config.deface.overrides.load_all(Rails.application)

          Deface::Override.all.values.map(&:values).flatten.map(&:railtie_class).should include('RailsAppl', 'DummyEngine')
        end
      end

      describe "enumerate_and_load" do
        let(:root) { Pathname.new("/some/path") }

        it "should be enumerate default path when none supplied" do
          Dir.should_receive(:glob).with(root.join "app/overrides", "**", "*.rb")
          Dir.should_receive(:glob).with(root.join "app/overrides", "**", "*.deface")
          Rails.application.config.deface.overrides.send(:enumerate_and_load, nil, root)
        end

        it "should enumerate supplied paths" do
          Dir.should_receive(:glob).with(root.join "app/junk", "**", "*.rb" )
          Dir.should_receive(:glob).with(root.join "app/junk", "**", "*.deface" )
          Dir.should_receive(:glob).with(root.join "app/gold", "**", "*.rb" )
          Dir.should_receive(:glob).with(root.join "app/gold", "**", "*.deface" )
          Rails.application.config.deface.overrides.send(:enumerate_and_load, ["app/junk", "app/gold"], root)
        end

        it "should add paths to watchable_dir when running Rails 3.2" do
          if Rails.version[0..2] == '3.2'
            Rails.application.config.deface.overrides.send(:enumerate_and_load, ["app/gold"], root)
            Rails.application.config.watchable_dirs.should == {"/some/path/app/gold" => [:rb, :deface] }
          end
        end

      end
    end

    describe "#_early" do
      it "should contain one override" do
        Deface::Override._early.size.should == 1
      end

      it "should initialize override and be emtpy after early_check" do
        before_count = Rails.application.config.deface.overrides.all.size
        Rails.application.config.deface.overrides.early_check

         Deface::Override._early.size.should == 0
         Rails.application.config.deface.overrides.all.size.should == (before_count + 1)
      end
    end

  end
end

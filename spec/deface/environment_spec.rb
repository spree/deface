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

    describe ".overrides" do

      it "should return all overrides" do
        expect(Rails.application.config.deface.overrides.all.size).to eq(2)
        expect(Rails.application.config.deface.overrides.all).to eq(Deface::Override.all)
      end

      it "should find overrides" do
        expect(Rails.application.config.deface.overrides.find(:virtual_path => "posts/new").size).to eq(1)
      end

      describe "load_all" do

        before do
          allow(Rails.application).to receive_messages :root => Pathname.new(File.join(File.dirname(__FILE__), '..', "assets"))
          allow(Rails.application).to receive_messages :paths => {}
          allow(Rails.application).to receive_message_chain :railties, :_all => []

          expect(Deface::DSL::Loader).to receive(:register)
        end

        it "should enumerate_and_load nil when app has no app/overrides path set" do
          expect(Rails.application.config.deface.overrides).to receive(:enumerate_and_load).with(nil, Rails.application.root)
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should enumerate_and_load path when app has app/overrides path set" do
          allow(Rails.application).to receive_messages :paths => {"app/overrides" => ["app/some_path"] }
          expect(Rails.application.config.deface.overrides).to receive(:enumerate_and_load).with(["app/some_path"] , Rails.application.root)
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should enumerate_and_load nil when railtie has no app/overrides path set" do
          allow(Rails.application).to receive_message_chain :railties, :_all => [double('railtie', :root => "/some/path")]

          expect(Rails.application.config.deface.overrides).to receive(:enumerate_and_load).with(nil, Rails.application.root)
          expect(Rails.application.config.deface.overrides).to receive(:enumerate_and_load).with(nil, "/some/path")
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should enumerate_and_load path when railtie has app/overrides path set" do
          allow(Rails.application).to receive_message_chain :railties, :_all => [ double('railtie', :root => "/some/path", :paths => {"app/overrides" => ["app/some_path"] } )]

          expect(Rails.application.config.deface.overrides).to receive(:enumerate_and_load).with(nil, Rails.application.root)
          expect(Rails.application.config.deface.overrides).to receive(:enumerate_and_load).with(["app/some_path"] , "/some/path")
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should enumerate_and_load railties first, followed by the application iteslf" do
          allow(Rails.application).to receive_message_chain :railties, :_all => [ double('railtie', :root => "/some/path", :paths => {"app/overrides" => ["app/some_path"] } )]

          expect(Rails.application.config.deface.overrides).to receive(:enumerate_and_load).with(["app/some_path"] , "/some/path").ordered
          expect(Rails.application.config.deface.overrides).to receive(:enumerate_and_load).with(nil, Rails.application.root).ordered
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should ignore railtie with no root" do
          railtie = double('railtie')
          allow(Rails.application).to receive_message_chain :railties, :_all => [railtie]

          expect(railtie).to receive(:respond_to?).with(:root)
          expect(railtie).not_to receive(:respond_to?).with(:paths)
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end

        it "should clear any previously loaded overrides" do
          expect(Rails.application.config.deface.overrides.all).to receive(:clear)
          Rails.application.config.deface.overrides.load_all(Rails.application)
        end


      end

      describe 'load_overrides' do
        let(:assets_path) { Pathname.new(File.join(File.dirname(__FILE__), '..', "assets")) }
        let(:engine) { double('railtie', :root => assets_path, :class => "DummyEngine", :paths => {"app/overrides" => ["dummy_engine"]}) }
        before { allow(Rails.application).to receive_messages(:class => 'RailsAppl') }

        it "should keep a reference to which railtie/app defined the override" do
          allow(Rails.application).to receive_messages :root => assets_path, :paths => {"app/overrides" => ["dummy_app"] }
          allow(Rails.application).to receive_message_chain :railties, :_all => [ engine ]

          Rails.application.config.deface.overrides.load_all(Rails.application)

          expect(Deface::Override.all.values.map(&:values).flatten.map(&:railtie_class)).to include('RailsAppl', 'DummyEngine')
        end
      end

      describe "enumerate_and_load" do
        let(:root) { Pathname.new("/some/path") }

        it "should be enumerate default path when none supplied" do
          expect(Dir).to receive(:glob).with(root.join "app/overrides", "**", "*.rb")
          expect(Dir).to receive(:glob).with(root.join "app/overrides", "**", "*.deface")
          Rails.application.config.deface.overrides.send(:enumerate_and_load, nil, root)
        end

        it "should enumerate supplied paths" do
          expect(Dir).to receive(:glob).with(root.join "app/junk", "**", "*.rb" )
          expect(Dir).to receive(:glob).with(root.join "app/junk", "**", "*.deface" )
          expect(Dir).to receive(:glob).with(root.join "app/gold", "**", "*.rb" )
          expect(Dir).to receive(:glob).with(root.join "app/gold", "**", "*.deface" )
          Rails.application.config.deface.overrides.send(:enumerate_and_load, ["app/junk", "app/gold"], root)
        end

        it "should add paths to watchable_dir when running Rails 3.2" do
          Rails.application.config.deface.overrides.send(:enumerate_and_load, ["app/gold"], root)
          expect(Rails.application.config.watchable_dirs).to eq({"/some/path/app/gold" => [:rb, :deface] })
        end

      end
    end

    describe "#_early" do
      it "should contain one override" do
        expect(Deface::Override._early.size).to eq(1)
      end

      it "should initialize override and be emtpy after early_check" do
        before_count = Rails.application.config.deface.overrides.all.size
        Rails.application.config.deface.overrides.early_check

         expect(Deface::Override._early.size).to eq(0)
         expect(Rails.application.config.deface.overrides.all.size).to eq(before_count + 1)
      end
    end

  end
end

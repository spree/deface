require 'spec_helper'

module Deface

  describe Precompiler do
    include_context "mock Rails.application"

    before do
      # start with a clean file system
      FileUtils.rm_rf('spec/dummy/app/compiled_views')
      environment = Deface::Environment.new
      overrides = Deface::Environment::Overrides.new
      overrides.stub(:all => {}) # need to do this before creating an override
      overrides.stub(:all => {"posts/precompileme".to_sym => {"precompileme".parameterize => Deface::Override.new(:virtual_path => "posts/precompileme", :name => "precompileme", :insert_bottom => 'li', :text => "Added to li!")}})
      environment.stub(:overrides => overrides)

      Rails.application.config.stub :deface => environment

      #stub view paths to be local spec/assets directory
      ActionController::Base.stub(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

      Precompiler.precompile()
    end

    after do
      # cleanup the file system
      FileUtils.rm_rf('spec/dummy/app/compiled_views')
    end

    it "writes precompiles the overrides" do

      filename = 'spec/dummy/app/compiled_views/posts/precompileme.html.erb'

      File.exists?(filename).should be_true

      file = File.open(filename, "rb")
      contents = file.read

      contents.should =~ /precompile/
    end
  end
end

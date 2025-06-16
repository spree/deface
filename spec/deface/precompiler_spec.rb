require 'spec_helper'

module Deface

  describe Precompiler do
    include_context "mock Rails.application"

    before do
      # start with a clean file system
      FileUtils.rm_rf('spec/dummy/app/compiled_views')
      environment = Deface::Environment.new
      overrides = Deface::Environment::Overrides.new
      allow(overrides).to receive_messages(:all => {}) # need to do this before creating an override
      allow(overrides).to receive_messages(:all => {"posts/precompileme".to_sym => {"precompileme".parameterize => Deface::Override.new(:virtual_path => "posts/precompileme", :name => "precompileme", :insert_bottom => 'li', :text => "Added to li!")}})
      allow(environment).to receive_messages(:overrides => overrides)

      allow(Rails.application.config).to receive_messages :deface => environment

      #stub view paths to be local spec/assets directory
      allow(ActionController::Base).to receive(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

      Precompiler.precompile()
    end

    after do
      # cleanup the file system
      FileUtils.rm_rf('spec/dummy/app/compiled_views')
    end

    it "writes precompiles the overrides" do

      filename = 'spec/dummy/app/compiled_views/posts/precompileme.html.erb'

      expect(File.exist?(filename)).to be_truthy

      file = File.open(filename, "rb")
      contents = file.read

      expect(contents).to match(/precompile/)
    end
  end
end

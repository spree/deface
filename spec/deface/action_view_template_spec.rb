require 'spec_helper'

describe ActionView::Template do
  include_context "mock Rails.application"

  let(:template) { ActionView::Template.new(
    source,
    path,
    handler,
    **options,
    **(supports_updated_at? ? {updated_at: updated_at} : {})
  ) }

  let(:source) { "<p>test</p>" }
  let(:path) { "/some/path/to/file.erb" }
  let(:handler) { ActionView::Template::Handlers::ERB }
  let(:options) {{
    virtual_path: virtual_path,
    format: format,
  }}
  let(:format) { :html }
  let(:virtual_path) { "posts/index" }

  let(:supports_updated_at?) { Deface.before_rails_6? }
  let(:updated_at) { Time.now - 600 }

  describe "with no overrides defined" do
    it "should initialize new template object" do
      expect(template.is_a?(ActionView::Template)).to eq(true)
    end

    it "should return unmodified source" do
      expect(template.source).to eq("<p>test</p>")
    end

    it "should not change updated_at" do
      expect(template.updated_at).to eq(updated_at) if supports_updated_at?
    end
  end

  describe "with a single remove override defined" do
    let(:updated_at) { Time.now - 300 }
    let(:source) { "<p>test</p><%= raw(text) %>" }

    before do
      Deface::Override.new(virtual_path: "posts/index", name: "Posts#index", remove: "p", text: "<h1>Argh!</h1>")
    end

    it "should return modified source" do
      expect(template.source).to eq("<%= raw(text) %>")
    end

    it "should change updated_at" do
      expect(template.updated_at).to be > updated_at if supports_updated_at?
    end
  end

  describe "method_name" do
    it "should return hash of overrides plus original method_name " do
      deface_hash = Deface::Override.digest(virtual_path: 'posts/index')

      expect(template.send(:method_name)).to eq("_#{Digest::MD5.new.update("#{deface_hash}_#{template.send(:method_name_without_deface)}").hexdigest}")
    end

    it "should alias original method_name method" do
      expect(template.send(:method_name_without_deface)).to match(/\A__some_path_to_file_erb_+[0-9]+_+[0-9]+\z/)
    end
  end

  describe "non erb or haml template" do
    let(:source) { "xml.post => :blah" }
    let(:path) { "/some/path/to/file.erb" }
    let(:handler) { ActionView::Template::Handlers::Builder }
    let(:updated_at) { Time.now - 100 }
    let(:format) { :xml }

    before(:each) do
      Deface::Override.new(virtual_path: "posts/index", name: "Posts#index", remove: "p")
    end

    it "should return unmodified source" do
      expect(template.source).to eq("xml.post => :blah")
      expect(template.source).not_to include("=&gt;")
    end
  end

  describe "#should_be_defaced?(handler)" do
    let(:source) { "xml.post => :blah" }
    let(:format) { :xml }

    # Not so BDD, but it keeps us from making mistakes in the future for instance,
    # we test ActionView::Template here with a handler == ....::Handlers::ERB,
    # while in rails it seems it's an instance of ...::Handlers::ERB.
    it "should be truthy only for haml/erb handlers and their instances" do
      expectations = { Haml::Plugin => true,
                       ActionView::Template::Handlers::ERB => true,
                       ActionView::Template::Handlers::ERB.new => true,
                       ActionView::Template::Handlers::Builder => false }
      expectations.each do |handler, expected|
        expect(template.is_a?(ActionView::Template)).to eq(true)
        syntax = template.send(:determine_syntax, handler)
        expect(template.send(:should_be_defaced?, syntax)).to eq(expected), "unexpected result for handler "+handler.to_s
      end
    end
  end
end

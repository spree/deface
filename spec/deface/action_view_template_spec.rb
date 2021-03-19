require 'spec_helper'

describe Deface::ActionViewExtensions do
  include_context "mock Rails.application"

  before after_rails_6: true do
    skip "This spec is targeted at Rails v6+" if Deface.before_rails_6?
  end

  before before_rails_6: true do
    skip "This spec is targeted at Rails before v6+" unless Deface.before_rails_6?
  end

  let(:template) { ActionView::Template.new(
    source,
    path,
    handler,
    **options,
    **(Deface.before_rails_6? ? {updated_at: updated_at} : {})
  ) }

  let(:source) { "<p>test</p>" }
  let(:path) { "/some/path/to/file.erb" }
  let(:handler) { ActionView::Template::Handlers::ERB }
  let(:options) {{
    virtual_path: virtual_path,
    format: format,
    locals: {}
  }}
  let(:format) { :html }
  let(:virtual_path) { "posts/index" }

  let(:updated_at) { Time.now - 600 }

  describe "with no overrides defined" do
    it "should initialize new template object" do
      expect(template.is_a?(ActionView::Template)).to eq(true)
    end

    it "should return unmodified source" do
      expect(template.source).to eq("<p>test</p>")
    end

    it "should not change updated_at", :before_rails_6 do
      expect(template.updated_at).to eq(updated_at)
    end
  end

  describe "unsupported template" do
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

  describe ".determine_syntax(handler)" do
    let(:source) { "xml.post => :blah" }
    let(:format) { :xml }

    # Not so BDD, but it keeps us from making mistakes in the future for instance,
    # we test ActionView::Template here with a handler == ....::Handlers::ERB,
    # while in rails it seems it's an instance of ...::Handlers::ERB.
    it "recognizes supported syntaxes" do
      expectations = { Haml::Plugin => :haml,
                       ActionView::Template::Handlers::ERB => :erb,
                       ActionView::Template::Handlers::ERB.new => :erb,
                       ActionView::Template::Handlers::Builder => nil }
      expectations.each do |handler, expected|
        expect(template.is_a?(ActionView::Template)).to eq(true)
        expect(described_class.determine_syntax(handler)).to eq(expected), "unexpected result for handler #{handler}"
      end
    end
  end

  describe '#render' do
    let(:source) { "<p>test</p><%= raw(text) %>".inspect }
    let(:local_assigns) { {text: "some <br> text"} }
    let(:lookup_context) { ActionView::LookupContext.new(["#{__dir__}/views"]) }
    let(:view) do
      if Rails::VERSION::STRING >= '6.1'
        ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
      else
        ActionView::Base.new(lookup_context)
      end
    end
    let(:options) { {
      virtual_path: virtual_path,
      format: format,
      locals: local_assigns.keys
    } }

    it 'renders the template modified by deface using :replace' do
      Deface::Override.new(
        virtual_path: virtual_path,
        name: "Posts#index",
        replace: "p",
        text: "<h1>Argh!</h1>"
      )

      expect(template.render(view, local_assigns)).to eq(%{"<h1>Argh!</h1>some <br> text"})
    end

    it 'renders the template modified by deface using :remove' do
      Deface::Override.new(
        virtual_path: virtual_path,
        name: "Posts#index",
        remove: "p",
      )

      expect(template.render(view, local_assigns)).to eq(%{"some <br> text"})
    end

    context 'with a haml template' do
      let(:source) { "%p test\n= raw(text)\n" }
      let(:handler) { Haml::Plugin }

      it 'renders the template modified by deface using :remove' do
        Deface::Override.new(
          virtual_path: virtual_path,
          name: "Posts#index",
          remove: "p",
        )

        expect(template.render(view, local_assigns)).to eq(%{\nsome <br> text})
      end
    end

    context 'with a slim template' do
      let(:source) { "p test\n= raw(text)\n" }
      let(:handler) { Slim::RailsTemplate.new }

      it 'renders the template modified by deface using :remove' do
        Deface::Override.new(
          virtual_path: virtual_path,
          name: "Posts#index",
          remove: "p",
        )

        expect(template.render(view, local_assigns)).to eq(%{\nsome <br> text\n})
      end
    end
  end
end

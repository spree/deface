require 'spec_helper'

module Deface
  describe HamlConverter do
    include_context "mock Rails.application"

    def haml_to_erb(src)
      haml_engine = Deface::HamlConverter.new(src)
      haml_engine.render.gsub("\n", "")
    end

    describe "convert haml to erb" do
      it "should hanlde simple tags" do
        expect(haml_to_erb("%%strong.code#message Hello, World!")).to eq("<strong class='code' id='message'>Hello, World!</strong>")
      end

      it "should handle complex tags" do
        expect(haml_to_erb(%q{#content
  .left.column
    %h2 Welcome to our site!
    %p= print_information
  .right.column
    = render :partial => "sidebar"})).to eq("<div id='content'><div class='left column'><h2>Welcome to our site!</h2><p><%= print_information %></p></div><div class='right column'><%= render :partial => \"sidebar\" %></div></div>")
      end

      it "should handle simple haml attributes" do
        expect(haml_to_erb("%meta{:charset => 'utf-8'}")).to eq("<meta charset='utf-8'>")
        expect(haml_to_erb("%p(alt='hello world')Hello World!")).to eq("<p alt='hello world'>Hello World!</p>")
      end

      it "should handle haml attributes with commas" do
        expect(haml_to_erb("%meta{'http-equiv' => 'X-UA-Compatible', :content => 'IE=edge,chrome=1'}")).to eq("<meta content='IE=edge,chrome=1' http-equiv='X-UA-Compatible'>")
        expect(haml_to_erb("%meta(http-equiv='X-UA-Compatible' content='IE=edge,chrome=1')")).to eq("<meta content='IE=edge,chrome=1' http-equiv='X-UA-Compatible'>")
        expect(haml_to_erb('%meta{:name => "author", :content => "Example, Inc."}')).to eq("<meta content='Example, Inc.' name='author'>")
        expect(haml_to_erb('%meta(name="author" content="Example, Inc.")')).to eq("<meta content='Example, Inc.' name='author'>")

        if RUBY_VERSION > "1.9"
          expect(haml_to_erb('%meta{name: "author", content: "Example, Inc."}')).to eq("<meta content='Example, Inc.' name='author'>")
        end
      end

      it "should handle haml attributes with evaluated values" do
        expect(haml_to_erb("%p{ :alt => hello_world}Hello World!")).to eq("<p data-erb-alt='&lt;%= hello_world %&gt;'>Hello World!</p>")

        if RUBY_VERSION > "1.9"
          expect(haml_to_erb("%p{ alt: @hello_world}Hello World!")).to eq("<p data-erb-alt='&lt;%= @hello_world %&gt;'>Hello World!</p>")
        end

        expect(haml_to_erb("%p(alt=hello_world)Hello World!")).to eq("<p data-erb-alt='&lt;%= hello_world %&gt;'>Hello World!</p>")
        expect(haml_to_erb("%p(alt=@hello_world)Hello World!")).to eq("<p data-erb-alt='&lt;%= @hello_world %&gt;'>Hello World!</p>")
      end

      it "should handle erb loud" do
        expect(haml_to_erb("%h3.title= entry.title")).to eq("<h3 class='title'><%= entry.title %></h3>")
      end

      it "should handle single erb silent" do
        expect(haml_to_erb("- some_method")).to eq("<% some_method %>")
      end

      it "should handle implicitly closed erb loud" do
        expect(haml_to_erb("= if @this == 'this'
  %p hello
")).to eq("<%= if @this == 'this' %><p>hello</p><% end %>")
      end

      it "should handle implicitly closed erb silent" do
        expect(haml_to_erb("- if foo?
  %p hello
")).to eq("<% if foo? %><p>hello</p><% end %>")
      end

      it "should handle blocks passed to erb loud" do
        expect(haml_to_erb("= form_for Post.new do |f|
  %p
    = f.text_field :name")).to eq("<%= form_for Post.new do |f| %><p><%= f.text_field :name %></p><% end %>")

      end


       it "should handle blocks passed to erb silent" do
        expect(haml_to_erb("- @posts.each do |post|
  %p
    = post.name")).to eq("<% @posts.each do |post| %><p><%= post.name %></p><% end %>")

      end
    end
  end
end

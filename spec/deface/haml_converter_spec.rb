# encoding: utf-8

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
        haml_to_erb("%%strong.code#message Hello, World!").should == "<strong class='code' id='message'>Hello, World!</strong>"
      end

      it "should handle complex tags" do
        haml_to_erb(%q{#content
  .left.column
    %h2 Welcome to our site!
    %p= print_information
  .right.column
    = render :partial => "sidebar"}).should == "<div id='content'>  <div class='left column'>    <h2>Welcome to our site!</h2>    <p>    <%= print_information %></p>  </div>  <div class='right column'>    <%= render :partial => \"sidebar\" %>  </div></div>"
      end

      it "should handle simple haml attributes" do
        haml_to_erb("%meta{:charset => 'utf-8'}").should == "<meta charset='utf-8' />"
        haml_to_erb("%p(alt='hello world')Hello World!").should == "<p alt='hello world'>Hello World!</p>"
      end

      it "should handle haml attributes with commas" do
        haml_to_erb("%meta{'http-equiv' => 'X-UA-Compatible', :content => 'IE=edge,chrome=1'}").should == "<meta content='IE=edge,chrome=1' http-equiv='X-UA-Compatible' />"
        haml_to_erb("%meta(http-equiv='X-UA-Compatible' content='IE=edge,chrome=1')").should == "<meta content='IE=edge,chrome=1' http-equiv='X-UA-Compatible' />"
        haml_to_erb('%meta{:name => "author", :content => "Example, Inc."}').should == "<meta content='Example, Inc.' name='author' />"
        haml_to_erb('%meta(name="author" content="Example, Inc.")').should == "<meta content='Example, Inc.' name='author' />"

        if RUBY_VERSION > "1.9"
          haml_to_erb('%meta{name: "author", content: "Example, Inc."}').should == "<meta content='Example, Inc.' name='author' />"
        end
      end

      it "should handle haml attributes with evaluated values" do
        haml_to_erb("%p{ :alt => hello_world}Hello World!").should == "<p data-erb-alt='&lt;%= hello_world %&gt;'>Hello World!</p>"

        if RUBY_VERSION > "1.9"
          haml_to_erb("%p{ alt: @hello_world}Hello World!").should == "<p data-erb-alt='&lt;%= @hello_world %&gt;'>Hello World!</p>"
        end

        haml_to_erb("%p(alt=hello_world)Hello World!").should == "<p data-erb-alt='&lt;%= hello_world %&gt;'>Hello World!</p>"
        haml_to_erb("%p(alt=@hello_world)Hello World!").should == "<p data-erb-alt='&lt;%= @hello_world %&gt;'>Hello World!</p>"
      end

      it "should handle erb loud" do
        haml_to_erb("%h3.title= entry.title").should == "<h3 class='title'><%= entry.title %></h3>"
      end

      it "should handle single erb silent" do
        haml_to_erb("- some_method").should == "<% some_method %>"
      end

      it "should handle implicitly closed erb loud" do
        haml_to_erb("= if @this == 'this'
  %p hello
").should == "<%= if @this == 'this' %><p>hello</p><% end %>"
      end

      it "should handle implicitly closed erb silent" do
        haml_to_erb("- if foo?
  %p hello
").should == "<% if foo? %><p>hello</p><% end %>"
      end

      it "should handle blocks passed to erb loud" do
        haml_to_erb("= form_for Post.new do |f|
  %p
    = f.text_field :name").should == "<%= form_for Post.new do |f| %><p>  <%= f.text_field :name %></p><% end %>"

      end


       it "should handle blocks passed to erb silent" do
        haml_to_erb("- @posts.each do |post|
  %p
    = post.name").should == "<% @posts.each do |post| %><p>  <%= post.name %></p><% end %>"

      end
    end

    describe "convert haml thant includes multi byte string to erb" do
      before { Encoding.default_internal = 'UTF-8' }
      after { Encoding.default_internal = nil }

      it "should handle" do
        haml_to_erb("%%strong.code#message ハロー、ワールド！".force_encoding('ASCII-8BIT')).should == "<strong class='code' id='message'>ハロー、ワールド！</strong>"
      end
    end
  end
end

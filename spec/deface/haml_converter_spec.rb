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
    = post.name").should match("<% @posts.each do |post| %><p>  <%= post.name %></p><% end %>")

      end
    end
  end
end

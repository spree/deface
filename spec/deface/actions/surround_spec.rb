require 'spec_helper'

module Deface
  module Actions
    describe Surround do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single html surround override defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround => "p", :text => "<h1>It's behind you!</h1><div><%= render_original %></div>") }
        let(:source) { "<p>test</p>" }

        it "should return modified source" do
          Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<h1>It's behind you!</h1><div><p>test</p></div>"
        end
      end

      describe "with a single erb surround override defined" do
        before  { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround => "p", :text => "<% some_method('test') do %><%= render_original %><% end %>") }
        let(:source) { "<span><p>test</p></span>" }

        it "should return modified source" do
          Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", '').should == "<span><% some_method('test') do %><p>test</p><% end %></span>"
        end
      end

      describe "with a single surround override defined using :closing_selector" do
        before  { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround => "h1", :closing_selector => "p",
                                       :text => "<% some_method('test') do %><%= render_original %><% end %>") }
        let(:source) { "<span><h1>Start</h1><h2>middle</h2><p><span>This is the</span> end.</p></span>" }

        it "should return modified source" do
          Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", '').should == "<span><% some_method('test') do %><h1>Start</h1><h2>middle</h2><p><span>This is the</span> end.</p><% end %></span>"
        end
      end

      describe "with multiple render_original calls defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround => "p", :text => "<div><%= render_original %></div><h1>It's behind you!</h1><div><%= render_original %></div>") }
        let(:source) { "<p>test</p>" }

        it "should return modified source" do
          Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<div><p>test</p></div><h1>It's behind you!</h1><div><p>test</p></div>"
        end
      end

      describe "with multiple render_original calls defined using :closing_selector" do
        before  { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround => "h1", :closing_selector => "p",
                                       :text => "<% if true %><%= render_original %><% else %><%= render_original %><% end %>") }
        let(:source) { "<span><h1>Start</h1><h2>middle</h2><p><span>This is the</span> end.</p></span>" }

        it "should return modified source" do
          Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", '').should == "<span><% if true %><h1>Start</h1><h2>middle</h2><p><span>This is the</span> end.</p><% else %><h1>Start</h1><h2>middle</h2><p><span>This is the</span> end.</p><% end %></span>"
        end
      end
    end
  end
end

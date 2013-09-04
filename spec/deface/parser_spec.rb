# encoding: UTF-8
 
require 'spec_helper'

module Deface
  describe Parser do

    describe "#convert" do
      it "should parse html fragment" do
        Deface::Parser.convert("<h1>Hello</h1>").should be_an_instance_of(Nokogiri::HTML::DocumentFragment)
        Deface::Parser.convert("<h1>Hello</h1>").to_s.should == "<h1>Hello</h1>"
        Deface::Parser.convert("<title>Hello</title>").should be_an_instance_of(Nokogiri::HTML::DocumentFragment)
        Deface::Parser.convert("<title>Hello</title>").to_s.should == "<title>Hello</title>"
      end

      it "should parse html document" do
        parsed = Deface::Parser.convert("<html><head><title>Hello</title></head><body>test</body>")
        parsed.should be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")

        unless RUBY_PLATFORM == 'java'
          parsed = parsed[1..-1] #ignore doctype added by nokogiri
        end

        #accounting for qwerks in Nokogir between ruby versions / platforms
        if RUBY_PLATFORM == 'java'
          parsed.should == ["<html><head><title>Hello</title></head><body>test</body></html>"]
        elsif RUBY_VERSION < "1.9"
          parsed.should == "<html>\n<head><title>Hello</title></head>\n<body>test</body>\n</html>".split("\n")
        else
          parsed.should == "<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<title>Hello</title>\n</head>\n<body>test</body>\n</html>".split("\n")
        end

        parsed = Deface::Parser.convert("<html><title>test</title></html>")
        parsed.should be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")

        unless RUBY_PLATFORM == 'java'
          parsed = parsed[1..-1] #ignore doctype added by nokogiri
        end

        #accounting for qwerks in Nokogir between ruby versions / platforms
        if RUBY_VERSION < "1.9" || RUBY_PLATFORM == 'java'
          parsed.should == ["<html><head><title>test</title></head></html>"]
        else
          parsed.should == "<html><head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<title>test</title>\n</head></html>".split("\n")
        end

        parsed = Deface::Parser.convert("<html><p>test</p></html>")
        parsed.should be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")

        if RUBY_PLATFORM == 'java'
          parsed.should eq ["<html><head></head><body><p>test</p></body></html>"]
        else
          parsed = parsed[1..-1]
          parsed.should eq ["<html><body><p>test</p></body></html>"]
        end
      end

      # Regression test for #84, #100
      it "should parse html document with erb in the head" do
        parsed = Deface::Parser.convert("<html><head><%= method_name %></head><body></body></html>")
        parsed.should be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")

        if RUBY_PLATFORM == 'java'
          parsed.should == ["<html><head><erb loud=\"\"> method_name </erb></head><body></body></html>"]
        else
          parsed = parsed[1..-1]
          parsed.should == "<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<erb loud> method_name </erb>\n</head>\n<body></body>\n</html>".split("\n")
        end
      end

      it "should parse body tag" do
        tag = Deface::Parser.convert("<body id=\"body\" <%= something %>>test</body>")
        tag.should be_an_instance_of(Nokogiri::XML::Element)
        tag.text.should eq 'test'
        tag.attributes['id'].value.should eq 'body'
        tag.attributes['data-erb-0'].value.should eq '<%= something %>'
      end

      it "should convert <% ... %>" do
        tag = Deface::Parser.convert("<% method_name %>")
        tag = tag.css('erb').first
        tag.attributes['silent'].value.should eq ''
      end

      it "should convert <%= ... %>" do
        tag = Deface::Parser.convert("<%= method_name %>")
        tag = tag.css('erb').first
        tag.attributes['loud'].value.should eq ''
      end

      it "should convert first <% ... %> inside html tag" do
        Deface::Parser.convert("<p <% method_name %>></p>").to_s.should == "<p data-erb-0=\"&lt;% method_name %&gt;\"></p>"
      end

      it "should convert second <% ... %> inside html tag" do
        Deface::Parser.convert("<p <% method_name %> <% x = y %>></p>").to_s.should == "<p data-erb-0=\"&lt;% method_name %&gt;\" data-erb-1=\"&lt;% x = y %&gt;\"></p>"
      end

      it "should convert <% ... %> inside double quoted attr value" do
        Deface::Parser.convert("<p id=\"<% method_name %>\"></p>").to_s.should == "<p data-erb-id=\"&lt;% method_name %&gt;\"></p>"
      end

      if RUBY_PLATFORM == 'java'
        it "should convert <% ... %> contains double quoted  value" do
          Deface::Parser.convert("<p <% method_name \"test\" %>></p>").to_s.should == "<p data-erb-0=\"&lt;% method_name %22test%22 %&gt;\"></p>"
        end
      end

      it "should convert <% ... %> inside single quoted attr value" do
        Deface::Parser.convert("<p id='<% method_name %>'></p>").to_s.should == "<p data-erb-id=\"&lt;% method_name %&gt;\"></p>"
      end

      it "should convert <% ... %> inside non-quoted attr value" do
        tag = Deface::Parser.convert("<p id=<% method_name %>></p>")
        tag = tag.css('p').first
        tag.attributes['data-erb-id'].value.should eq '<% method_name %>'

        tag = Deface::Parser.convert("<p id=<% method_name %> alt=\"test\"></p>")
        tag = tag.css('p').first
        tag.attributes['data-erb-id'].value.should eq '<% method_name %>'
        tag.attributes['alt'].value.should eq 'test'
      end

      it "should convert multiple <% ... %> inside html tag" do
        tag = Deface::Parser.convert(%q{<p <%= method_name %> alt="<% x = 'y' + 
                               \"2\" %>" title='<% method_name %>' <%= other_method %></p>})

        tag = tag.css('p').first
        tag.attributes['data-erb-0'].value.should == "<%= method_name %>"
        tag.attributes['data-erb-1'].value.should == "<%= other_method %>"
        tag.attributes['data-erb-alt'].value.should == "<% x = 'y' + \n                               \\\"2\\\" %>"
        tag.attributes['data-erb-title'].value.should == "<% method_name %>"
      end

      it "should convert <%= ... %> including href attribute" do
        tag = Deface::Parser.convert(%(<a href="<%= x 'y' + "z" %>">A Link</a>))
        tag = tag.css('a').first
        tag.attributes['data-erb-href'].value.should eq "<%= x 'y' + \"z\" %>"
        tag.text.should eq 'A Link'
      end

      it "should escape contents erb tags" do
        tag = Deface::Parser.convert("<% method_name :key => 'value' %>")
        tag = tag.css('erb').first
        tag.attributes.key?('silent').should be_true
        tag.text.should eq " method_name :key => 'value' "
      end

      it "should handle round brackets in erb tags" do
        # commented out line below will fail as : adjacent to ( causes Nokogiri parser issue on jruby
        tag = Deface::Parser.convert("<% method_name(:key => 'value') %>")
        tag = tag.css('erb').first
        tag.attributes.key?('silent').should be_true
        tag.text.should eq " method_name(:key => 'value') "

        tag = Deface::Parser.convert("<% method_name( :key => 'value' ) %>")
        tag = tag.css('erb').first
        tag.attributes.key?('silent').should be_true
        tag.text.should eq " method_name( :key => 'value' ) "
      end

      it "should respect valid encoding tag" do
        source = %q{<%# encoding: ISO-8859-1 %>Can you say ümlaut?}
        Deface::Parser.convert(source)
        source.encoding.name.should == 'ISO-8859-1'
      end

      it "should force default encoding" do
        source = %q{Can you say ümlaut?}
        source.force_encoding('ISO-8859-1')
        Deface::Parser.convert(source)
        source.encoding.should == Encoding.default_external
      end

      it "should force default encoding" do
        source = %q{<%# encoding: US-ASCII %>Can you say ümlaut?}
        lambda { Deface::Parser.convert(source) }.should raise_error(ActionView::WrongEncodingError)
      end
    end

    describe "#undo_erb_markup" do
      it "should revert <erb silent>" do
        Deface::Parser.undo_erb_markup!("<erb silent> method_name </erb>").should == "<% method_name %>"
      end

      it "should revert <erb loud>" do
        Deface::Parser.undo_erb_markup!("<erb loud> method_name </erb>").should == "<%= method_name %>"
      end

      it "should revert data-erb-x attrs inside html tag" do
        Deface::Parser.undo_erb_markup!("<p data-erb-0=\"&lt;% method_name %&gt;\" data-erb-1=\"&lt;% x = y %&gt;\"></p>").should == "<p <% method_name %> <% x = y %>></p>"
      end

      it "should revert data-erb-id attr inside html tag" do
        Deface::Parser.undo_erb_markup!("<p data-erb-id=\"&lt;% method_name &gt; 1 %&gt;\"></p>").should == "<p id=\"<% method_name > 1 %>\"></p>"
      end

      it "should revert data-erb-href attr inside html tag" do
        Deface::Parser.undo_erb_markup!("<a data-erb-href=\"&lt;%= x 'y' + &quot;z&quot; %&gt;\">A Link</a>").should == %(<a href="<%= x 'y' + \"z\" %>">A Link</a>)
      end

      if RUBY_PLATFORM == 'java'
        it "should revert data-erb-x containing double quoted value" do
          Deface::Parser.undo_erb_markup!("<p data-erb-0=\"&lt;% method_name %22test%22 %&gt;\"></p>").should == %(<p <% method_name \"test\" %>></p>)
        end
      end

      it "should unescape contents of erb tags" do
        Deface::Parser.undo_erb_markup!("<% method(:key =&gt; 'value' %>").should == "<% method(:key => 'value' %>"
        Deface::Parser.undo_erb_markup!("<% method(:key =&gt; 'value'\n %>").should == "<% method(:key => 'value'\n %>"
      end

    end

  end

end

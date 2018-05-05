# encoding: UTF-8

require 'spec_helper'

module Deface
  describe Parser do

    describe "#convert" do
      it "should parse html fragment" do
        expect(Deface::Parser.convert("<h1>Hello</h1>")).to be_an_instance_of(Nokogiri::HTML::DocumentFragment)
        expect(Deface::Parser.convert("<h1>Hello</h1>").to_s).to eq("<h1>Hello</h1>")
        expect(Deface::Parser.convert("<title>Hello</title>")).to be_an_instance_of(Nokogiri::HTML::DocumentFragment)
        expect(Deface::Parser.convert("<title>Hello</title>").to_s).to eq("<title>Hello</title>")
        expect(Deface::Parser.convert("<title>Hello Frozen</title>".freeze).to_s).to eq("<title>Hello Frozen</title>")
      end

      it "should parse html document" do
        parsed = Deface::Parser.convert("<html><head><title>Hello</title></head><body>test</body>")
        expect(parsed).to be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")

        unless RUBY_PLATFORM == 'java'
          parsed = parsed[1..-1] #ignore doctype added by nokogiri
        end

        #accounting for qwerks in Nokogir between ruby versions / platforms
        if RUBY_PLATFORM == 'java'
          expect(parsed).to eq(["<html><head><title>Hello</title></head><body>test</body></html>"])
        elsif RUBY_VERSION < "1.9"
          expect(parsed).to eq("<html>\n<head><title>Hello</title></head>\n<body>test</body>\n</html>".split("\n"))
        else
          expect(parsed).to eq("<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<title>Hello</title>\n</head>\n<body>test</body>\n</html>".split("\n"))
        end

        parsed = Deface::Parser.convert("<html><title>test</title></html>")
        expect(parsed).to be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")

        unless RUBY_PLATFORM == 'java'
          parsed = parsed[1..-1] #ignore doctype added by nokogiri
        end

        #accounting for qwerks in Nokogir between ruby versions / platforms
        if RUBY_VERSION < "1.9" || RUBY_PLATFORM == 'java'
          expect(parsed).to eq(["<html><head><title>test</title></head></html>"])
        else
          expect(parsed).to eq("<html><head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<title>test</title>\n</head></html>".split("\n"))
        end

        parsed = Deface::Parser.convert("<html><p>test</p></html>")
        expect(parsed).to be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")

        if RUBY_PLATFORM == 'java'
          expect(parsed).to eq ["<html><head></head><body><p>test</p></body></html>"]
        else
          parsed = parsed[1..-1]
          expect(parsed).to eq ["<html><body><p>test</p></body></html>"]
        end
      end

      # Regression test for #84, #100
      it "should parse html document with erb in the head" do
        parsed = Deface::Parser.convert("<html><head><%= method_name %></head><body></body></html>")
        expect(parsed).to be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")

        if RUBY_PLATFORM == 'java'
          expect(parsed).to eq(["<html><head><erb loud=\"\"> method_name </erb></head><body></body></html>"])
        else
          parsed = parsed[1..-1]
          expect(parsed).to eq("<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<erb loud> method_name </erb>\n</head>\n<body></body>\n</html>".split("\n"))
        end
      end

      it "should parse body tag" do
        tag = Deface::Parser.convert("<body id=\"body\" <%= something %>>test</body>")
        expect(tag).to be_an_instance_of(Nokogiri::XML::Element)
        expect(tag.text).to eq 'test'
        expect(tag.attributes['id'].value).to eq 'body'
        expect(tag.attributes['data-erb-0'].value).to eq '<%= something %>'
      end

      it "should convert <% ... %>" do
        tag = Deface::Parser.convert("<% method_name %>")
        tag = tag.css('erb').first
        expect(tag.attributes['silent'].value).to eq ''
      end

      it "should convert <%= ... %>" do
        tag = Deface::Parser.convert("<%= method_name %>")
        tag = tag.css('erb').first
        expect(tag.attributes['loud'].value).to eq ''
      end

      it "should convert first <% ... %> inside html tag" do
        expect(Deface::Parser.convert("<p <% method_name %>></p>").to_s).to eq("<p data-erb-0=\"&lt;% method_name %&gt;\"></p>")
      end

      it "should convert second <% ... %> inside html tag" do
        expect(Deface::Parser.convert("<p <% method_name %> <% x = y %>></p>").to_s).to eq("<p data-erb-0=\"&lt;% method_name %&gt;\" data-erb-1=\"&lt;% x = y %&gt;\"></p>")
      end

      it "should convert <% ... %> inside double quoted attr value" do
        expect(Deface::Parser.convert("<p id=\"<% method_name %>\"></p>").to_s).to eq("<p data-erb-id=\"&lt;% method_name %&gt;\"></p>")
      end

      if RUBY_PLATFORM == 'java'
        it "should convert <% ... %> contains double quoted  value" do
          expect(Deface::Parser.convert("<p <% method_name \"test\" %>></p>").to_s).to eq("<p data-erb-0=\"&lt;% method_name %22test%22 %&gt;\"></p>")
        end
      end

      it "should convert <% ... %> inside single quoted attr value" do
        expect(Deface::Parser.convert("<p id='<% method_name %>'></p>").to_s).to eq("<p data-erb-id=\"&lt;% method_name %&gt;\"></p>")
      end

      it "should convert <% ... %> inside non-quoted attr value" do
        tag = Deface::Parser.convert("<p id=<% method_name %>></p>")
        tag = tag.css('p').first
        expect(tag.attributes['data-erb-id'].value).to eq '<% method_name %>'

        tag = Deface::Parser.convert("<p id=<% method_name %> alt=\"test\"></p>")
        tag = tag.css('p').first
        expect(tag.attributes['data-erb-id'].value).to eq '<% method_name %>'
        expect(tag.attributes['alt'].value).to eq 'test'
      end

      it "should convert multiple <% ... %> inside html tag" do
        tag = Deface::Parser.convert(%q{<p <%= method_name %> alt="<% x = 'y' + 
                               \"2\" %>" title='<% method_name %>' <%= other_method %></p>})

        tag = tag.css('p').first
        expect(tag.attributes['data-erb-0'].value).to eq("<%= method_name %>")
        expect(tag.attributes['data-erb-1'].value).to eq("<%= other_method %>")
        expect(tag.attributes['data-erb-alt'].value).to eq("<% x = 'y' + \n                               \\\"2\\\" %>")
        expect(tag.attributes['data-erb-title'].value).to eq("<% method_name %>")
      end

      it "should convert <%= ... %> including href attribute" do
        tag = Deface::Parser.convert(%(<a href="<%= x 'y' + "z" %>">A Link</a>))
        tag = tag.css('a').first
        expect(tag.attributes['data-erb-href'].value).to eq "<%= x 'y' + \"z\" %>"
        expect(tag.text).to eq 'A Link'
      end

      it "should escape contents erb tags" do
        tag = Deface::Parser.convert("<% method_name :key => 'value' %>")
        tag = tag.css('erb').first
        expect(tag.attributes.key?('silent')).to be_truthy
        expect(tag.text).to eq " method_name :key => 'value' "
      end

      it "should handle round brackets in erb tags" do
        # commented out line below will fail as : adjacent to ( causes Nokogiri parser issue on jruby
        tag = Deface::Parser.convert("<% method_name(:key => 'value') %>")
        tag = tag.css('erb').first
        expect(tag.attributes.key?('silent')).to be_truthy
        expect(tag.text).to eq " method_name(:key => 'value') "

        tag = Deface::Parser.convert("<% method_name( :key => 'value' ) %>")
        tag = tag.css('erb').first
        expect(tag.attributes.key?('silent')).to be_truthy
        expect(tag.text).to eq " method_name( :key => 'value' ) "
      end

      it "should respect valid encoding tag" do
        source = %q{<%# encoding: ISO-8859-1 %>Can you say ümlaut?}
        Deface::Parser.convert(source)
        expect(source.encoding.name).to eq('ISO-8859-1')
      end

      it "should force default encoding" do
        source = %q{Can you say ümlaut?}
        source.force_encoding('ISO-8859-1')
        Deface::Parser.convert(source)
        expect(source.encoding).to eq(Encoding.default_external)
      end

      it "should force default encoding" do
        source = %q{<%# encoding: US-ASCII %>Can you say ümlaut?}
        expect { Deface::Parser.convert(source) }.to raise_error(ActionView::WrongEncodingError)
      end
    end

    describe "#undo_erb_markup" do
      it "should revert <erb silent>" do
        expect(Deface::Parser.undo_erb_markup!("<erb silent> method_name </erb>")).to eq("<% method_name %>")
      end

      it "should revert <erb loud>" do
        expect(Deface::Parser.undo_erb_markup!("<erb loud> method_name </erb>")).to eq("<%= method_name %>")
      end

      it "should revert data-erb-x attrs inside html tag" do
        expect(Deface::Parser.undo_erb_markup!("<p data-erb-0=\"&lt;% method_name %&gt;\" data-erb-1=\"&lt;% x = y %&gt;\"></p>")).to eq("<p <% method_name %> <% x = y %>></p>")
      end

      it "should revert data-erb-id attr inside html tag" do
        expect(Deface::Parser.undo_erb_markup!("<p data-erb-id=\"&lt;% method_name &gt; 1 %&gt;\"></p>")).to eq("<p id=\"<% method_name > 1 %>\"></p>")
      end

      it "should revert data-erb-href attr inside html tag" do
        expect(Deface::Parser.undo_erb_markup!("<a data-erb-href=\"&lt;%= x 'y' + &quot;z&quot; %&gt;\">A Link</a>")).to eq(%(<a href="<%= x 'y' + \"z\" %>">A Link</a>))
      end

      if RUBY_PLATFORM == 'java'
        it "should revert data-erb-x containing double quoted value" do
          expect(Deface::Parser.undo_erb_markup!("<p data-erb-0=\"&lt;% method_name %22test%22 %&gt;\"></p>")).to eq(%(<p <% method_name \"test\" %>></p>))
        end
      end

      it "should unescape contents of erb tags" do
        expect(Deface::Parser.undo_erb_markup!("<% method(:key =&gt; 'value' %>")).to eq("<% method(:key => 'value' %>")
        expect(Deface::Parser.undo_erb_markup!("<% method(:key =&gt; 'value'\n %>")).to eq("<% method(:key => 'value'\n %>")
      end

    end

  end

end

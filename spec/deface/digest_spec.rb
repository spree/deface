# encoding: UTF-8

require 'spec_helper'

module Deface
  describe Digest do
    def with_custom_digest
      digest = double("digest")
      original_digest = Digest.digest_class
      Digest.digest_class = digest
      yield digest
    ensure
      Digest.digest_class = original_digest
    end

    it "should use MD5 by default" do
      expect(Digest.hexdigest("123")).to eq "202cb962ac59075b964b07152d234b70"
    end

    it "should use user-provided digest" do
      with_custom_digest do |digest|
        expect(digest).to receive(:hexdigest).with("to_digest").and_return("digested")
        expect(Digest.hexdigest("to_digest")).to eq "digested"
      end
    end

    it "should truncate digest to 32 characters" do
      with_custom_digest do |digest|
        expect(digest).to receive(:hexdigest).with("to_digest").and_return("a" * 50)
        expect(Digest.hexdigest("to_digest").size).to eq 32
      end
    end
  end
end


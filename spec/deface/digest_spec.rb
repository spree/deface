# encoding: UTF-8

require 'spec_helper'

module Deface
  describe Digest do
    it "should use MD5 by default" do
      expect(Digest.new.hexdigest("123")).to eq "202cb962ac59075b964b07152d234b70"
    end

    it "should use user-provided digest" do
      digest = double("digest")
      expect(digest).to receive(:hexdigest).with("to_digest").and_return("digested")
      expect(Digest.new(digest).hexdigest("to_digest")).to eq "digested"
    end

    it "should truncate digest to 32 characters" do
      digest = double("digest")
      expect(digest).to receive(:hexdigest).with("to_digest").and_return("a" * 50)
      expect(Digest.new(digest).hexdigest("to_digest").size).to eq 32
    end
  end
end


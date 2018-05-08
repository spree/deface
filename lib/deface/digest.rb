module Deface
  class Digest
    class <<self
      def digest_class
        @digest_class || ::Digest::MD5
      end

      def digest_class=(klass)
        @digest_class = klass
      end

      def hexdigest(arg)
        new.hexdigest(arg)
      end
    end

    def initialize(klass = nil)
      @digest_class = klass || self.class.digest_class
    end

    def hexdigest(arg)
      @digest_class.hexdigest(arg).truncate(32)
    end
  end
end

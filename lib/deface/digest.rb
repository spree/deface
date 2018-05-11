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
        digest_class.hexdigest(arg)[0...32]
      end
    end
  end
end

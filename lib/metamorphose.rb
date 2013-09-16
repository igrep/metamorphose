require "metamorphose/version"

module Metamorphose

  class RipperSexp
    AT_MARK = "@"

    def initialize sexp
      @sexp = sexp
    end

    def event_name
      @sexp.first
    end

    class << self
      def self.detect sexp
        first = sexp.first
        case first
        when Array
          self.detect first
        when Symbol
          if first[0] == AT_MARK
            ScannerEvent.new( sexp )
          else
            ParserEvent.new( sexp )
          end
        else
          raise ArgumentError, "#{sexp.inspect} doesn't seem to be a S expression!"
        end
      end
    end

    class ScannerEvent < RipperSexp
      def token
        @sexp[1]
      end
      def location_info
        @sexp[2]
      end
    end

    class ParserEvent < RipperSexp
    end

  end

end

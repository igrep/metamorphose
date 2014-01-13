require "metamorphose/version"

require 'ripper/core'

module Metamorphose

  def metamorphose_source source_code
    m = Metamorphoser.new( self, source_code )
    m.parse
    m.result
  end

  def _metamorphose_piece value, expression, line_column
    self.metamorphose_piece value, expression, line_column
    value
  end

  class Metamorphoser < ::Ripper

    def initialize metamorphoser_module, *rest
      @metamorphoser_module = metamorphoser_module
      @metamorphosed_source_pieces = []
      @source_piece_stack = SourcePiece::Stack.new
      super( *rest )
    end

    PARSER_EVENT_TABLE.each do |event_sym, arity|
      event = event_sym.to_s
      if /_new\z/ =~ event and arity == 0
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}
            []
          end
        End
      elsif /_add\z/ =~ event
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}(list, item)
            list.push item
            list
          end
        End
      else
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}(*args)
            args.unshift :#{event}
            args
          end
        End
      end
    end

    # Parser event: local variable reference
    def on_var_ref identifier
      @source_piece_stack.wrap_current_by self
      identifier
    end

    # Parser event: method call without arguments
    alias on_vcall on_var_ref

    # Parser event: method call with arguments
    def on_command method_name, _
      @source_piece_stack.wrap_current_by self
      method_name
    end

    SCANNER_EVENTS.each do |event|
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event} token
          @source_piece_stack.push_non_wrappable token
          token
        end
      End
    end

    # Scanner event: any identifier (method name or variable name).
    def on_ident token
      @source_piece_stack.push_new_piece token, self.lineno, self.column
      token
    end

    def wrap_source_piece source_piece
      "#@metamorphoser_module._metamorphose_piece(" \
        "(#{source_piece.source})," \
        " \"#{source_piece.source}\"," \
        " [#{source_piece.line_number}, #{source_piece.column_number}]" \
      ")"
    end

    def result
      @source_piece_stack.join
    end

    class SourcePiece
      attr_reader :source, :line_number, :column_number

      def initialize initial_source, line_number = nil, column_number = nil
        @source = initial_source
        @line_number = line_number
        @column_number = column_number
      end

      def append_source token
        @source << token
      end

      def to_s # called in SourcePiece::Stack#join
        @source
      end

      def inspect
        "#<#{self.class} #{@source.inspect} at (#{@line_number}, #{@column_number})>"
      end

      class Stack

        def initialize
          @source_pieces = [ SourcePiece.new('') ]
        end

        def push_new_piece initial_token, line_number, column_number
          @source_pieces.push SourcePiece.new( initial_token, line_number, column_number )
        end

        def push_non_wrappable token
          self.current.append_source token
        end

        def current
          @source_pieces.last
        end

        def wrap_current_by metamorphoser
          wrapped = metamorphoser.wrap_source_piece self.current
          self.push_non_wrappable wrapped
          @source_pieces.pop
        end

        def join
          @source_pieces.join ''.freeze
        end

      end

    end

  end

end

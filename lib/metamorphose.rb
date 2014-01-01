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
      @metamorphosed_tokens = []
      @token_stack = TokenWrapper::Stack.new
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
            puts "on_#{event}: '\#{list.inspect}', '\#{item}'"
            list.push item
            list
          end
        End
      else
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}(*args)
            puts "on_#{event}: '\#{args.inspect}'"
            args.unshift :#{event}
            args
          end
        End
      end
    end

    # local variable reference
    def on_var_ref identifier
      puts "on_vcall: '#{identifier.inspect}'"
      @token_stack.wrap_current_with self
      identifier
    end

    # method call without arguments
    alias on_vcall on_var_ref

    SCANNER_EVENTS.each do |event|
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event} token
          puts "on_#{event}: '\#{token}'"
          @token_stack.push_non_wrappable token
          token
        end
      End
    end

    def on_ident token
      puts "#{__method__}: '#{token}'"
      @token_stack.push_wrappable token
      token
    end

    def wrap token
      "#@metamorphoser_module._metamorphose_piece(" \
        "#{token}," \
        " \"#{token}\"," \
        " [#{self.lineno}, #{self.column}]" \
      ")"
    end

    def result
      @token_stack.join
    end

    class TokenWrapper

      def initialize target_token = nil
        @target_token = target_token
        @next_source  = ''
      end

      def append_next_source token
        @next_source << token
      end

      def wrap_with metamorphoser
        "#{metamorphoser.wrap @target_token}#{@next_source}"
      end

      def to_s # called in TokenWrapper::Stack#join
        @next_source
      end

      class Stack

        def initialize
          @tokens = [TokenWrapper.new]
        end

        def push_wrappable wrappable_token
          @tokens.push TokenWrapper.new( wrappable_token )
        end

        def push_non_wrappable token
          self.current.append_next_source token
        end

        def current
          @tokens.last
        end

        def wrap_current_with metamorphoser
          wrapped = self.current.wrap_with metamorphoser
          @tokens.pop
          self.push_non_wrappable wrapped
        end

        def join
          @tokens.join ''.freeze
        end

      end

    end

  end

end

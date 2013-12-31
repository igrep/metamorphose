require "metamorphose/version"

require 'ripper/core'

module Metamorphose

  def metamorphose_source source_code
    m = Metamorphoser.new( self, source_code )
    m.parse
    m.metamorphosed_tokens.join ''
  end

  def _metamorphose_piece value, expression, line_column
    self.metamorphose_piece value, expression, line_column
    value
  end

  class Metamorphoser < ::Ripper
    attr_reader :metamorphosed_tokens

    def initialize metamorphoser_module, *rest
      @metamorphoser_module = metamorphoser_module
      @metamorphosed_tokens = []
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

    # append a method argument
    def on_args_add args_list, item
      puts "#{__method__}: '#{args_list.inspect}', '#{item}'"
      @metamorphosed_tokens << ", "
      args_list.push item
      args_list
    end

    # local variable reference
    def on_var_ref identifier
      puts "on_vcall: '#{identifier.inspect}'"
      @metamorphosed_tokens <<
        "#@metamorphoser_module._metamorphose_piece(" \
          "#{identifier}," \
          " \"#{identifier}\"," \
          " [#{self.lineno}, #{self.column}]" \
        ")"
      identifier
    end

    # method call without arguments
    alias on_vcall on_var_ref

    SCANNER_EVENTS.each do |event|
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event} token
          puts "on_#{event}: '\#{token}'"
          token
        end
      End
    end

  end

end

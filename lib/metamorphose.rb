require "metamorphose/version"

require 'ripper/core'

module Metamorphose

  def metamorphose_source source_code
    m = Metamorphoser.new( self, source_code )
    m.parse
    m.metamorphosed_source
  end

  def _metamorphose_piece value, expression, line_column
    self.metamorphose_piece value, expression, line_column
    value
  end

  class Metamorphoser < ::Ripper
    attr_reader :metamorphosed_source

    def initialize metamorphoser_module, *rest
      @metamorphoser_module = metamorphoser_module
      super( *rest )
    end

    def parse
      @metamorphosed_source = ""
      super
    end

    PARSER_EVENTS.each do |event|
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event}(*args)
          puts "on_#{event}: '\#{args.inspect}'"
          args.unshift :#{event}
          args
        end
      End
    end

    def on_vcall *args
      @metamorphosed_source =
        "#@metamorphoser_module._metamorphose_piece(" \
          "#@metamorphosed_source," \
          " #{@metamorphosed_source.inspect}," \
          " [#{self.lineno}, #{self.column}]" \
        ")"
      args.unshift :vcall
      args
    end

    SCANNER_EVENTS.each do |event|
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event} token
          puts "on_#{event}: '\#{token}'"
          token
        end
      End
    end

    def on_ident token
      puts "on_ident: '#{token}'"
      @metamorphosed_source << token
      token
    end

  end

end

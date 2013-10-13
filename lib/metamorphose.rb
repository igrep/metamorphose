require "metamorphose/version"

require 'ripper/core'

module Metamorphose

  class Metamorphoser < ::Ripper
    attr_reader :metamorphosed_source

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

    SCANNER_EVENTS.each do |event|
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event} token
          puts "on_#{event}: '\#{token}'"
          @metamorphosed_source << token
          token
        end
      End
    end

  end

end

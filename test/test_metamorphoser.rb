$LOAD_PATH << File.join( File.dirname( __FILE__ ), '..',  'lib' )

require 'metamorphose'
require 'awesome_print'

m = Metamorphose::Metamorphoser.new File.open( ARGV[0] )

puts "parsing result: "
ap m.parse

puts "metamorphosed_source: "
puts m.metamorphosed_source

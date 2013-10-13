$LOAD_PATH << File.join( File.dirname( __FILE__ ), '..',  'lib' )

require 'metamorphose'
require 'awesome_print'

m = Metamorphose::Metamorphoser.new File.open( ARGV[0] )
ap m.parse

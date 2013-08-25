require 'spec_helper'

describe Metamorphose do
  before( :all ){ MetamorphoseForDescription = Module.new { extend Metamorphose } }
  subject { MetamorphoseForDescription }
  it 'should have a version number' do
    Metamorphose::VERSION.should_not be_nil
  end

  describe ".metamorphose_source" do
    let( :result ) { subject.metamorphose_source source_code }

    context 'given a simple expression in Ruby' do
      let( :source_code ) { 'hoge' }
      let( :line_num ) { 1 }
      let( :col_num ) { 1 }
      it 'returns the expression wrapped with metamorphose_piece' do
        result.should eq %Q'MetamorphoseForDescription.metamorphose_piece(hoge, "hoge", [#{line_num}, #{col_num}])'
      end
      it 'returns the source code which should be evaluated as before metamorphosed' do
        eval( result, TOPLEVEL_BINDING ).should be eval( source_code, TOPLEVEL_BINDING )
      end
    end

    context 'given a source code in Ruby' do
      let( :source_code ) { 'hoge ab, cd' }
      let( :line_num ) { 1 }
      let( :col_num_hoge ) { source_code.index( 'hoge' ) + 1 }
      let( :col_num_ab ) { source_code.index( 'ab' ) + 1 }
      let( :col_num_cd ) { source_code.index( 'cd' ) + 1 }
      it 'returns the source code each of whose values are wrapped with metamorphose_piece' do
        result.should eq(
          'MetamorphoseForDescription.metamorphose_piece(' \
            '(' \
            'hoge ' \
            "MetamorphoseForDescription.metamorphose_piece(ab, \"ab\", [#{line_num}, #{col_num_ab}]), " \
            "MetamorphoseForDescription.metamorphose_piece(cd, \"cd\", [#{line_num}, #{col_num_cd}])" \
            '),' \
            "[#{line_num}, #{col_num_hoge}] " \
          ')'
        )
      end
      it 'returns the source code which should be evaluated as before metamorphosed' do
        eval( result, TOPLEVEL_BINDING ).should be eval( source_code, TOPLEVEL_BINDING )
      end
    end

  end
end
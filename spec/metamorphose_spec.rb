require 'spec_helper'

describe Metamorphose do

  it 'should have a version number' do
    Metamorphose::VERSION.should_not be_nil
  end

  describe ".metamorphose_source" do
    context "when there's a metamorphose module implementing metamorphose_piece in a binding" do
      before( :all ) do
        # save binding to evaluate this module later
        @binding = binding
        MetamorphoseForDescription = Module.new {
          extend Metamorphose
          def metamorphose_piece _value, _expression, _line_column
            # do nothing
          end
        }
      end

      subject { MetamorphoseForDescription }

      let( :result ) { subject.metamorphose_source source_code }

      context 'given a simple expression in Ruby' do
        let( :source_code ) { 'hoge' }
        let( :line_num ) { 1 }
        let( :col_num ) { source_code.length }
        it 'returns the expression wrapped with _metamorphose_piece' do
          result.should eq %Q'MetamorphoseForDescription._metamorphose_piece(hoge, "hoge", [#{line_num}, #{col_num}])'
        end

        context 'when the expression does not have no runtime error.' do
          before { eval 'def hoge; end', @binding }
          it 'returns the source code which should be evaluated as before metamorphosed' do
            eval( result, @binding ).should eq eval( source_code, @binding )
          end
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
            'MetamorphoseForDescription._metamorphose_piece(' \
              '(' \
                'hoge ' \
                "MetamorphoseForDescription._metamorphose_piece(ab, \"ab\", [#{line_num}, #{col_num_ab}]), " \
                "MetamorphoseForDescription._metamorphose_piece(cd, \"cd\", [#{line_num}, #{col_num_cd}])" \
              '),' \
              "[#{line_num}, #{col_num_hoge}] " \
            ')'
          )
        end

        context 'when the source code does not have no runtime error.' do
          before do
            eval 'def hoge *args; end', TOPLEVEL_BINDING
            eval 'def ab; end', TOPLEVEL_BINDING
            eval 'def cd; end', TOPLEVEL_BINDING
          end
          it 'returns the source code which should be evaluated as before metamorphosed' do
            eval( result, TOPLEVEL_BINDING ).should eq eval( source_code, TOPLEVEL_BINDING )
          end
        end

      end

    end

  end
end

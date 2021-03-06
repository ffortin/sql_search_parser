class SQLSearch::Parser

rule
  /* search conditions */

  search_condition
    : boolean_term
    | search_condition OR boolean_term { result = Conditions::Or.new(:left => val[0], :right => val[2]) }

  boolean_term
    : boolean_factor
    | boolean_term AND boolean_factor { result = Conditions::And.new(:left => val[0], :right => val[2]) }

  boolean_factor:
    : NOT boolean_test { result = Conditions::Not.new(:value => val[1]) }
    | boolean_test

  boolean_test
    : boolean_primary

  boolean_primary
    : predicate
    | LPAREN search_condition RPAREN { result = val[1] }

  predicate:
    comparison_predicate
    |between_predicate
    |like_predicate
    |test_for_null
    |in_predicate
    ;

  comparison_predicate:
    scalar_exp COMPARISON scalar_exp { result = Comparisons::Base.new(:left => val[0], :right => val[2], :operator => val[1].to_sym) }
    ;

  between_predicate:
    scalar_exp NOT BETWEEN scalar_exp AND scalar_exp
    |scalar_exp BETWEEN scalar_exp AND scalar_exp
    ;

  like_predicate:
    scalar_exp NOT LIKE atom opt_escape { result = Conditions::Not.new(:value => Comparisons::Base.new(:left => val[0], :right => val[3], :operator => :LIKE)) }
    |scalar_exp LIKE atom opt_escape { result = Comparisons::Base.new(:left => val[0], :right => val[2], :operator => :LIKE) }
    ;

  opt_escape:
    /* empty */
    |ESCAPE atom
    ;

  test_for_null:
    column_ref IS NOT NULL { result = Comparisons::Base.new(:left => val[0], :right => val[3], :operator => :'<>') }
    |column_ref IS NULL { result = Comparisons::Base.new(:left => val[0], :right => val[2], :operator => :'=') }
    ;

  in_predicate:
    scalar_exp NOT IN LPAREN atom_commalist RPAREN { result = Conditions::Not.new(:value => Comparisons::In.new(:left => val[0], :right => Atoms::InValues.new(:values => val[4]))) }
    |scalar_exp IN LPAREN atom_commalist RPAREN { result = Comparisons::In.new(:left => val[0], :right => Atoms::InValues.new(:values => val[3])) }
    ;

  atom_commalist:
    atom { result = [val[0]] }
    |atom_commalist COMMA atom { result = val[0].concat([val[2]]) }
    ;

    /* scalar expressions */

  scalar_exp:
    scalar_exp ADD scalar_exp { result = Atoms::Scalar.new(:left => val[0], :right => val[2], :operation => :'+')}
    |scalar_exp SUBTRACT scalar_exp { result = Atoms::Scalar.new(:left => val[0], :right => val[2], :operation => :'-')}
    |scalar_exp MULTIPLY scalar_exp { result = Atoms::Scalar.new(:left => val[0], :right => val[2], :operation => :'*')}
    |scalar_exp DIVIDE scalar_exp { result = Atoms::Scalar.new(:left => val[0], :right => val[2], :operation => :'/')}
    |ADD scalar_exp { result = Atoms::UnaryScalar.new(:value => val[1], :operation => :'+')}
    |SUBTRACT scalar_exp { result = Atoms::UnaryScalar.new(:value => val[1], :operation => :'-')}
    |atom
    |column_ref
    |LPAREN scalar_exp RPAREN
    ;

  atom:
    literal
    ;

  literal:
    STRING { result = Atoms::Literal.new(:value => val[0], :type => :string) }
    |APPROXNUM { result = Atoms::Literal.new(:value => val[0], :type => :float) }
    |INTNUM { result = Atoms::Literal.new(:value => val[0], :type => :int) }
    |TIME { result = Atoms::Literal.new(:value => val[0], :type => :datetime) }
    ;

  column_ref:
    NAME { result = Atoms::Column.new(:name => val[0]) }
    |NAME DOT NAME { result = Atoms::Column.new(:name => val[0], :table=> val[2]) }
    |NAME DOT NAME DOT NAME { result = Atoms::Column.new(:name => val[4], :table=> val[2], :space => val[0]) }
    ;

end

---- header
  require 'date'
  require_relative 'parser.rex.rb'

---- inner
  def parse(input)
    scan_str(input)
  end


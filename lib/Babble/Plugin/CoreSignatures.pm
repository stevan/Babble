package Babble::Plugin::CoreSignatures;

use Moo;

sub extend_grammar { } # PPR::X can already parse everything we need

# .......bbbbbSSSSSSSa
# sub foo :Bar ($baz) {

# .......bSSSSSSSaaaaa
# sub foo ($baz) :Bar {

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->each_match_within('SubroutineDeclaration' => [
    'sub \b (?&PerlOWS) (?&PerlOldQualifiedIdentifier)',
    '(?:', # 5.20, 5.28+
      [ before => '(?: (?&PerlOWS) (?>(?&PerlAttributes)) )?+' ],
      [ sig => '(?&PerlOWS) (?&PerlParenthesesList)' ], # not optional for us
      [ after => '(?&PerlOWS)' ],
    '|', # 5.22 - 5.26
      [ before => '(?&PerlOWS)' ],
      [ sig => '(?&PerlParenthesesList) (?&PerlOWS)' ], # not optional for us
      [ after => '(?: (?>(?&PerlAttributes)) (?&PerlOWS) )?+' ],
    ')',
    [ body => '(?&PerlBlock)' ],
  ] => sub {
    my $s = (my $m = shift)->submatches;
    s/^\s+//, s/\s+$// for my $sig_text = $s->{sig}->text;
    $s->{body}->transform_text(sub { s/^{/{ my ${sig_text} = \@_; / });
    $s->{sig}->replace_text('');
  });
}

1;
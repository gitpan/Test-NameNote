package Test::NameNote;
use strict;
use warnings;
our $VERSION = '0.01';

=head1 NAME

Test::NameNote - add notes to test names

=head1 SYNOPSIS

Adds notes to test names in L<Test::Builder>-based test scripts.  Each
Test::NameNote object encapsulates a singe note, which will be added to the
names of all tests run while the object is in scope.

  use Test::More tests => 10;
  use Test::NameNote;

  ok foo(), "foo true";
  foreach my $foo (0, 1) {
      my $n1 = Test::NameNote->new("foo=$foo");
      foreach my $bar (0, 1) {
          my $n2 = Test::NameNote->new("bar=$bar");
          is thing($foo, $bar), "thing", "thing returns thing";
          is thang($foo, $bar), "thang", "thang returns thang";
      }
  }
  ok bar(), "bar true";

  # prints:
  1..10
  ok 1 - foo true
  ok 2 - thing returns thing (foo=0,bar=0)
  ok 3 - thang returns thang (foo=0,bar=0)
  ok 4 - thing returns thing (foo=0,bar=1)
  ok 5 - thang returns thang (foo=0,bar=1)
  ok 6 - thing returns thing (foo=1,bar=0)
  ok 7 - thang returns thang (foo=1,bar=0)
  ok 8 - thing returns thing (foo=1,bar=1)
  ok 9 - thang returns thang (foo=1,bar=1)
  ok 10 - bar true

=cut

use Test::Builder;
use Sub::Prepend 'prepend';

our @_notes;
our $_wrapped_test_group_ok = 0;

_wrap('Test::Builder::ok');

sub _wrap {
    my $target = shift;

    prepend $target => sub {
        if (@_notes) {
            my $note = join ',', map {$$_} @_notes;
            if (defined $_[2] and length $_[2]) {
                $_[2] .= " ($note)";
            } else {
                $_[2] = $note;
            }
        } 
    };
}

sub new {
    my ($pkg, $note) = @_;

    if (!$_wrapped_test_group_ok and exists &Test::Group::_Runner::ok) {
        _wrap('Test::Group::_Runner::ok');
        $_wrapped_test_group_ok = 1;
    }

    push @_notes, \$note;
    return bless { NoteRef => \$note }, ref($pkg)||$pkg;
}

sub DESTROY {
    my $self = shift;

    @_notes = grep {$_ ne $self->{NoteRef}} @_notes;
}

1;


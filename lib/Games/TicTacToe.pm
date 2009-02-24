package Games::TicTacToe;

use strict;
use warnings;
use Data::Dumper;
use YAML::Syck;
use List::Util qw/shuffle min/;

use version; our $VERSION = qv('0.0.1');
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/field area player level debug/);

sub new {
    my ( $class, @field ) = @_;
    @field = (
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
    ) unless(@field);
    my @area;
    for (my $i=0; $i<=$#field; $i++) {
        push(@area, $i) if ($field[$i] eq '0');
    }
    my $left_num = @area;
    my $player = ($left_num % 2) ? 1 : 2;
    my $self = {
        'field'  => \@field,
        'area'   => \@area,
        'player' => $player,
        'level'  => 5,
        'debug'  => 0,
    };
    bless $self, $class;
    return $self;
}

sub _can_hit {
    my $self     = shift;
    my $location = shift;
    my @res      = grep { $_ eq $location } @{ $self->area };
    return @res;
}

sub hit {
    my ( $self, $location ) = @_;
    my @area = shuffle( @{ $self->area } );
    if ( defined $location && $location =~ m/^[0-8]$/msgx ) {
        @area = grep { $_ != $location } @area;
        return unless($self->_can_hit($location));
    }
    else {
        $location = shift(@area);
    }
    $self->{'area'}           = \@area;
    $self->field->[$location] = $self->player;
    $self->{'player'}         = ( $self->player == 1 ) ? 2 : 1;
    return { 'location' => $location, 'field' => $self->field };
}

sub playout {
    my $self  = shift;
    my $ret   = $self->hit();
    print "---------- Playout start ----------\n" if $self->debug;
    print $self->show() if $self->debug;
    my $first = $ret->{'location'};
    my $res = 0;
    while ( $res ne '3' ) {
        $res = $self->is_finished();
        last if ($res);
        $self->hit();
        print $self->show() if $self->debug;
    }
    print "最初の着手は $first : その結果 $res\n" if $self->debug;
    return { 'first' => $first, 'res' => $res };
}

sub is_finished {
    my $self = shift;
    my @area = @{ $self->area };
    my $res;
    my $condition = [
        [ 0, 1, 2 ],    # 1列目のチェック
        [ 3, 4, 5 ],    # 2列目のチェック
        [ 6, 7, 8 ],    # 3列目のチェック
        [ 0, 3, 6 ],    # 1行目のチェック
        [ 1, 4, 7 ],    # 2行目のチェック
        [ 2, 5, 8 ],    # 3行目のチェック
        [ 0, 4, 8 ],    # 左上から右下への斜めチェック
        [ 2, 4, 6 ],    # 右上から左下への斜めチェック
    ];
    foreach (@$condition) {
        return $res if ( $res = $self->_value_of_equal($_) );
    }
    return 3 unless (@area);
    return 0;
}

sub calc_next_matrix {
    my $self = shift;
    my $score = [];
    my @field    = @{$self->field};
    for ( 1 .. $self->level ) {
        my $t      = new Games::TicTacToe(@field);
        $t->toggle_debug() if $self->debug;
        my $result = $t->playout;
        next unless($result->{'res'});
        my $location = $result->{'first'};
        $score->[$location]->{'total'}++;
        $score->[$location]->{'win'} = 0 unless ($score->[$location]->{'win'});
        $score->[$location]->{'per'} = 0 unless ($score->[$location]->{'per'});
        if ($result->{'res'} eq '1' || $result->{'res'} eq '2') {
            ( $result->{'res'} eq $self->player )
              ? $score->[$location]->{'win'}++
              : $score->[$location]->{'win'}--;
        }
        $score->[$location]->{'per'} =
          $score->[$location]->{'win'} / $score->[$location]->{'total'};
    }
    return $score;

}

sub next_location {
    my $self     = shift;
    my $score    = shift || $self->calc_next_matrix();
    my $location = min( @{ $self->area } );
    for ( @{ $self->area } ) {
        next unless ( defined $score->[$_]{'per'} );
        unless ( defined $score->[$location]{'per'} ) {
            $location = $_;
            next;
        }
        $location = $_ if ( $score->[$_]{'per'} > $score->[$location]{'per'} );
    }
    return $location;
}

sub _value_of_equal {
    my $self  = shift;
    my @l     = @{ $_[0] };
    my $field = $self->field;
    if (   ( $field->[ $l[0] ] eq $field->[ $l[1] ] )
        && ( $field->[ $l[1] ] eq $field->[ $l[2] ] ) )
    {
        return $field->[ $l[0] ];
    }
    else {
        return 0;
    }
}

sub change_level {
    my $self = shift;
    $self->{'level'} = shift;
}

sub toggle_debug {
    my $self = shift;
    $self->{'debug'} = ($self->debug) ? 0 : 1;
}

sub show {
    my $self  = shift;
    my $field = $self->field;
    my @d = ("　", "○", "×");
    my $level = $self->level;
    my $board = << "EOF";
Game Field.    Location ID.
┌─┬─┬─┐┌─┬─┬─┐
│$d[$field->[0]]│$d[$field->[1]]│$d[$field->[2]]││ 0│ 1│ 2│
├─┼─┼─┤├─┼─┼─┤
│$d[$field->[3]]│$d[$field->[4]]│$d[$field->[5]]││ 3│ 4│ 5│
├─┼─┼─┤├─┼─┼─┤
│$d[$field->[6]]│$d[$field->[7]]│$d[$field->[8]]││ 6│ 7│ 8│
└─┴─┴─┘└─┴─┴─┘
Current level: $level
EOF
    return $board;
}

sub _show_matrix {
    my $self   = shift;
    my $score  = shift;
    my $level  = $self->level;
    my @s;
    for ( my $i = 0 ; $i <= 9 ; $i++ ) {
        $s[$i] = ( $score->[$i] )
          ? sprintf '%4s', int( $score->[$i]->{'per'} * 100 )
          : '    ';
    }
    my $board = << "EOF";
Score matrix.        Location ID.
┌──┬──┬──┐┌──┬──┬──┐
│$s[0]│$s[1]│$s[2]││  0 │  1 │  2 │
├──┼──┼──┤├──┼──┼──┤
│$s[3]│$s[4]│$s[5]││  3 │  4 │  5 │
├──┼──┼──┤├──┼──┼──┤
│$s[6]│$s[7]│$s[8]││  6 │  7 │  8 │
└──┴──┴──┘└──┴──┴──┘
Current level: $level
EOF
    return $board;
}

1;

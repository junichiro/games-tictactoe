#!/usr/bin/perl

use strict;
use warnings;
use FindBin::libs;
use Data::Dumper;
use Term::ReadLine;
use Games::TicTacToe;

my $ttt  = Games::TicTacToe->new();
my $term = Term::ReadLine->new("TicTacToe");
print $ttt->show;
my $play = run_loop( $ttt, $term );

sub run_loop {
    my ( $ttt, $term ) = @_;
    while ( defined( my $in = $term->readline("TicTacToe > ") ) ) {
        if ( $in =~ m!^([0-8])$! ) {
            if ( $ttt->hit($1) ) {
                print $ttt->show;
                if ( my $player = $ttt->is_finished() ) {
                    if ( $player eq '3' ) {
                        print "Draw!\n\n";
                    }
                    else {
                        print "player $player Win!\n\n";
                    }
                    return;
                }
            }
            else {
                print "Can't hit this point! ($1)\n";
            }
        }
        elsif ( $in eq 'o' || $in eq 'other' ) {
            my $score = $ttt->calc_next_matrix();
            print $ttt->_show_matrix($score);
            my $next_location = $ttt->next_location($score);
            if ( $ttt->hit($next_location) ) {
                print $ttt->show;
                if ( my $player = $ttt->is_finished() ) {
                    if ( $player eq '3' ) {
                        print "Draw!\n\n";
                    }
                    else {
                        print "player $player Win!\n\n";
                    }
                    return;
                }
            }
            else {
                print "Can't hit this point! ($next_location)\n";
            }
        }
        elsif ( $in eq 's' || $in eq 'score' ) {
            my $score = $ttt->calc_next_matrix();
            print $ttt->_show_matrix($score);
            my $next_location = $ttt->next_location($score);
        }
        elsif ( $in eq 'r' || $in eq 'random' ) {
            if ( $ttt->hit() ) {
                print $ttt->show;
                if ( my $player = $ttt->is_finished() ) {
                    if ( $player eq '3' ) {
                        print "Draw!\n\n";
                    }
                    else {
                        print "player $player Win!\n\n";
                    }
                    return;
                }
            }
            else {
                print "Can't hit this point!\n";
            }
        }
        elsif ( $in eq 'e' || $in eq 'exivision' ) {
            while (1) {
                my $score = $ttt->calc_next_matrix();
                print $ttt->_show_matrix($score);
                my $next_location = $ttt->next_location($score);
                if ( $ttt->hit($next_location) ) {
                    print $ttt->show;
                    if ( my $player = $ttt->is_finished() ) {
                        if ( $player eq '3' ) {
                            print "Draw!\n\n";
                        }
                        else {
                            print "player $player Win!\n\n";
                        }
                        return;
                    }
                }
            }
        }
        elsif ( $in =~ m!^l(\d*)$! ) {
            $ttt->change_level($1);
            print "CPU level changes into $1\n\n";
        }
        elsif ( $in eq 'd' || $in eq 'debug' ) {
            $ttt->toggle_debug();
            print "Toggle debug mode\n\n";
        }
        elsif ( $in eq 'resign' ) {
            print "You lose.\n\n";
            return;
        }
        elsif ( $in eq 'g' ) {
            print Dumper( $ttt->area );
            print $ttt->show;
        }
        elsif ( $in eq 'quit' ) {
            return;
        }
        else {
            print "Read help message!\n";
            print "[num]     着手\n";
            print "[s]       各着手のスコアを計算\n";
            print "[o]       相手が着手する\n";
            print "[g]       ボードを再描画する\n";
            print "[l]       レベルを変える\n";
            print "[d]       デバッグモードを on/off\n";
            print "[quit]    終了\n";
        }
    }
}

# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/modules";
use CAF::RuleBasedEditor qw(:rule_constants);
use Readonly;
use CAF::Object;
use Test::More tests => 135;
use Test::NoWarnings;
use Test::Quattor;
use Test::Quattor::Object;
use Carp qw(confess);

Test::NoWarnings::clear_warnings();


=pod

=head1 SYNOPSIS

Basic test for rule-based editor (_updateConfigLine() method)

=cut

Readonly my $FILENAME => '/my/file';

my $obj = Test::Quattor::Object->new();

$SIG{__DIE__} = \&confess;

my $changes;

Readonly my $QUATTOR_COMMENT => "\t\t# Line generated by Quattor";

# Various combination of keyword and values
Readonly my $KEYWORD_SIMPLE => 'A_KEYWORD';
Readonly my $KEYWORD_SIMPLE_2 => 'KEYWORD_2';
Readonly my $KEYWORD_SPACE => 'A KEYWORD';

Readonly my $VALUE_STR => 'this is a value';
Readonly my $VALUE_STR_2 => 'this is another value';


# Expected line contents
Readonly my $EXPECTED_KW_VAL_SIMPLE => 'A_KEYWORD this is a value
';
Readonly my $EXPECTED_KW_VAL2_SIMPLE => 'A_KEYWORD this is another value
';
Readonly my $EXPECTED_KW_VAL_SPACE => 'A KEYWORD this is a value
';
Readonly my $EXPECTED_KW_VAL_COLON => 'A_KEYWORD:this is a value
';
Readonly my $EXPECTED_KW_VAL_COLON_SPACE => 'A_KEYWORD : this is a value
';
Readonly my $EXPECTED_KW_VAL_EQUAL => 'A_KEYWORD=this is a value
';
Readonly my $EXPECTED_KW_VAL2_EQUAL => 'A_KEYWORD=this is another value
';
Readonly my $EXPECTED_KW_VAL_EQUAL_SPACE => 'A_KEYWORD = this is a value
';

Readonly my $EXPECTED_SH_VAR_SIMPLE => 'A_KEYWORD=this is a value' . $QUATTOR_COMMENT . '
';
Readonly my $EXPECTED_SH_VAR_SIMPLE_2 => 'A_KEYWORD=this is another value' . $QUATTOR_COMMENT . '
';
Readonly my $EXPECTED_SH_VAR_SIMPLE_3 => 'KEYWORD2=this is another value' . $QUATTOR_COMMENT . '
';
Readonly my $EXPECTED_SH_VAR_KW_ONLY => $KEYWORD_SIMPLE.'='.$QUATTOR_COMMENT."\n";
Readonly my $EXPECTED_ENV_VAR_SIMPLE => 'export A_KEYWORD=this is a value' . $QUATTOR_COMMENT . '
';
Readonly my $EXPECTED_ENV_VAR_SIMPLE_2 => 'export A_KEYWORD=this is another value' . $QUATTOR_COMMENT . '
';
Readonly my $EXPECTED_ENV_VAR_SIMPLE_3 => 'export KEYWORD_2=this is another value' . $QUATTOR_COMMENT . '
';


#########################################
# Function actually executing the tests #
#########################################

sub test_update_line {
    my ($obj, $fn, $initial_data, $args, $expected, $test_info, $expected_changes) = @_;

    set_file_contents($fn, $initial_data);
    my $fh = CAF::RuleBasedEditor->open($fn, log => $obj);
    ok(defined($fh), "$fn was opened $test_info");
    $fh->_updateConfigLine(@$args);
    is("$fh", $expected, "$fn has expected contents $test_info");
    my $changes = $fh->close();

    if ( defined($expected_changes) ) {
      is($changes, $expected_changes, "$fn has the expected number of changes $test_info");
    }
}


#############
# Main code #
#############

# LINE_FORMAT_KW_VAL

test_update_line($obj, $FILENAME, '', [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, 0],
                                      $EXPECTED_KW_VAL_SIMPLE, "(KW_VAL: line added to empty file)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SPACE, $VALUE_STR, LINE_FORMAT_KW_VAL, 0],
                                      $EXPECTED_KW_VAL_SIMPLE.$EXPECTED_KW_VAL_SPACE, "(KW_VAL: line appended)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR_2, LINE_FORMAT_KW_VAL, 0],
                                      $EXPECTED_KW_VAL2_SIMPLE, "(KW_VAL: line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, 0],
                                      $EXPECTED_KW_VAL_SIMPLE.'set '.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL: set line appended)");

test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, '', LINE_FORMAT_KW_VAL, 0, 1],
                                      $KEYWORD_SIMPLE."\n", "(KW_VAL: multiple flag set but empty value, line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR_2, LINE_FORMAT_KW_VAL, 0, 1],
                                      $EXPECTED_KW_VAL_SIMPLE.$EXPECTED_KW_VAL2_SIMPLE, "(KW_VAL: multiple flag set, additional line for the keyword)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, LINE_OPT_SEP_COLON, 1],
                                      $EXPECTED_KW_VAL_COLON, "(KW_VAL: multiple flag set, same keyword/value with different separator)");
test_update_line($obj, $FILENAME, "#".$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, LINE_OPT_SEP_EQUAL, 1],
                                      $EXPECTED_KW_VAL_EQUAL, "(KW_VAL: multiple flag set, same keyword/valuei as commented line with different separator)");

test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, LINE_OPT_SEP_COLON],
                                      $EXPECTED_KW_VAL_COLON, "(KW_VAL: separator changed from ' ' to ':', line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_COLON, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, 0],
                                      $EXPECTED_KW_VAL_SIMPLE, "(KW_VAL: separator changed from ':' to ' ', line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_COLON, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, LINE_OPT_SEP_EQUAL],
                                      $EXPECTED_KW_VAL_EQUAL, "(KW_VAL: separator changed from ':' to '=', line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_EQUAL, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, LINE_OPT_SEP_COLON | LINE_OPT_SEP_SPACE_AROUND],
                                      $EXPECTED_KW_VAL_COLON_SPACE, "(KW_VAL: separator changed from '=' to ' : ', line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, LINE_OPT_SEP_EQUAL | LINE_OPT_SEP_SPACE_AROUND],
                                      $EXPECTED_KW_VAL_EQUAL_SPACE, "(KW_VAL: separator changed from ' : ' to ' = ', line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, LINE_OPT_SEP_EQUAL],
                                      $EXPECTED_KW_VAL_EQUAL, "(KW_VAL: separator changed from ' : ' to '=', line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, LINE_OPT_SEP_SPACE_AROUND],
                                      $EXPECTED_KW_VAL_SIMPLE, "(KW_VAL: separator changed from ' : ' to ' ', line replaced)");

test_update_line($obj, $FILENAME, '', [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL, 0],
                                      $KEYWORD_SPACE."\n", "(KW_VAL: keyword without value added)");
test_update_line($obj, $FILENAME, $KEYWORD_SPACE, [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL, 0],
                                      $KEYWORD_SPACE, "(KW_VAL: keyword without value not replaced)");
test_update_line($obj, $FILENAME, $KEYWORD_SPACE."\n", [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL, 0, 1],
                                      $KEYWORD_SPACE."\n", "(KW_VAL: keyword without value not replaced, multiple flag ignored)");
test_update_line($obj, $FILENAME, "#".$KEYWORD_SPACE, [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL, 0],
                                      $KEYWORD_SPACE."\n", "(KW_VAL: commented keyword with missign new line and without value uncommented)");


# LINE_FORMAT_KW_VAL_SET

test_update_line($obj, $FILENAME, '', [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, 0],
                                      'set '.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL_SET: line added to empty file)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SPACE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, 0],
                                      'set '.$EXPECTED_KW_VAL_SIMPLE.'set '.$EXPECTED_KW_VAL_SPACE, "(KW_VAL_SET: line appended)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR_2, LINE_FORMAT_KW_VAL_SET, 0],
                                      'set '.$EXPECTED_KW_VAL2_SIMPLE, "(KW_VAL_SET: line replaced)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, 0],
                                      'set '.$EXPECTED_KW_VAL_SIMPLE.'setenv '.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL_SET: setenv line appended)");

test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, '', LINE_FORMAT_KW_VAL_SET, 0, 1],
                                      'set '.$KEYWORD_SIMPLE."\n", "(KW_VAL_SET: multiple flag set but empty value, line replaced)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR_2, LINE_FORMAT_KW_VAL_SET, 0, 1],
                                      'set '.$EXPECTED_KW_VAL_SIMPLE.'set '.$EXPECTED_KW_VAL2_SIMPLE, "(KW_VAL_SET: multiple flag set, additional line for the keyword)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, LINE_OPT_SEP_COLON, 1],
                                      'set '.$EXPECTED_KW_VAL_COLON, "(KW_VAL_SET: multiple flag set, same keyword/value with different separator)");
test_update_line($obj, $FILENAME, "# set ".$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, LINE_OPT_SEP_EQUAL, 1],
                                      'set '.$EXPECTED_KW_VAL_EQUAL, "(KW_VAL_SET: multiple flag set, same keyword/value as commented line with different separator)");

test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, LINE_OPT_SEP_COLON],
                                      'set '.$EXPECTED_KW_VAL_COLON, "(KW_VAL_SET: separator changed from ' ' to ':', line replaced)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_COLON, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, 0],
                                      'set '.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL_SET: separator changed from ':' to ' ', line replaced)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_COLON, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, LINE_OPT_SEP_EQUAL],
                                      'set '.$EXPECTED_KW_VAL_EQUAL, "(KW_VAL_SET: separator changed from ':' to '=', line replaced)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_EQUAL, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, LINE_OPT_SEP_COLON | LINE_OPT_SEP_SPACE_AROUND],
                                      'set '.$EXPECTED_KW_VAL_COLON_SPACE, "(KW_VAL_SET: separator changed from '=' to ' : ', line replaced)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, LINE_OPT_SEP_EQUAL | LINE_OPT_SEP_SPACE_AROUND],
                                      'set '.$EXPECTED_KW_VAL_EQUAL_SPACE, "(KW_VAL_SET: separator changed from ' : ' to ' = ', line replaced)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, LINE_OPT_SEP_EQUAL],
                                      'set '.$EXPECTED_KW_VAL_EQUAL, "(KW_VAL_SET: separator changed from ' : ' to '=', line replaced)");
test_update_line($obj, $FILENAME, 'set '.$EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SET, LINE_OPT_SEP_SPACE_AROUND],
                                      'set '.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL_SET: separator changed from ' : ' to ' ', line replaced)");

test_update_line($obj, $FILENAME, '', [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL_SET, 0],
                                      'set '.$KEYWORD_SPACE."\n", "(KW_VAL_SET: keyword without value added)");
test_update_line($obj, $FILENAME, 'set '.$KEYWORD_SPACE, [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL_SET, 0],
                                      'set '.$KEYWORD_SPACE, "(KW_VAL_SET: keyword without value not replaced)");
test_update_line($obj, $FILENAME, 'set '.$KEYWORD_SPACE."\n", [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL_SET, 0, 1],
                                      'set '.$KEYWORD_SPACE."\n", "(KW_VAL_SET: keyword without value not replaced, multiple flag ignored)");
test_update_line($obj, $FILENAME, "#set  ".$KEYWORD_SPACE, [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL_SET, 0],
                                      'set '.$KEYWORD_SPACE."\n", "(KW_VAL_SET: commented keyword with missign new line and without value uncommented)");

# LINE_FORMAT_KW_VAL_SETENV

test_update_line($obj, $FILENAME, '', [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, 0],
                                      'setenv '.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL_SETENV line added to empty file)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SPACE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, 0],
                                      'setenv '.$EXPECTED_KW_VAL_SIMPLE.'setenv '.$EXPECTED_KW_VAL_SPACE, "(KW_VAL_SETENV line appended)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR_2, LINE_FORMAT_KW_VAL_SETENV, 0],
                                      'setenv '.$EXPECTED_KW_VAL2_SIMPLE, "(KW_VAL_SETENV line replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL, 0],
                                      'setenv '.$EXPECTED_KW_VAL_SIMPLE.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL_SETENV keyword/value line appended)");

test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, '', LINE_FORMAT_KW_VAL_SETENV, 0, 1],
                                      'setenv '.$KEYWORD_SIMPLE."\n", "(KW_VAL_SETENV multiple flag set but empty value, line replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR_2, LINE_FORMAT_KW_VAL_SETENV, 0, 1],
                                      'setenv '.$EXPECTED_KW_VAL_SIMPLE.'setenv '.$EXPECTED_KW_VAL2_SIMPLE, "(KW_VAL_SETENV multiple flag set, additional line for the keyword)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, LINE_OPT_SEP_COLON, 1],
                                      'setenv '.$EXPECTED_KW_VAL_COLON, "(KW_VAL_SETENV multiple flag set, same keyword/value with different separator)");
test_update_line($obj, $FILENAME, "# setenv ".$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, LINE_OPT_SEP_EQUAL, 1],
                                      'setenv '.$EXPECTED_KW_VAL_EQUAL, "(KW_VAL_SETENV multiple flag set, same keyword/value as commented line with different separator)");

test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_SIMPLE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, LINE_OPT_SEP_COLON],
                                      'setenv '.$EXPECTED_KW_VAL_COLON, "(KW_VAL_SETENV separator changed from ' ' to ':', line replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_COLON, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, 0],
                                      'setenv '.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL_SETENV separator changed from ':' to ' ', line replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_COLON, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, LINE_OPT_SEP_EQUAL],
                                      'setenv '.$EXPECTED_KW_VAL_EQUAL, "(KW_VAL_SETENV separator changed from ':' to '=', line replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_EQUAL, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, LINE_OPT_SEP_COLON | LINE_OPT_SEP_SPACE_AROUND],
                                      'setenv '.$EXPECTED_KW_VAL_COLON_SPACE, "(KW_VAL_SETENV separator changed from '=' to ' : ', line replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, LINE_OPT_SEP_EQUAL | LINE_OPT_SEP_SPACE_AROUND],
                                      'setenv '.$EXPECTED_KW_VAL_EQUAL_SPACE, "(KW_VAL_SETENV separator changed from ' : ' to ' = ', line replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, LINE_OPT_SEP_EQUAL],
                                      'setenv '.$EXPECTED_KW_VAL_EQUAL, "(KW_VAL_SETENV separator changed from ' : ' to '=', line replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$EXPECTED_KW_VAL_COLON_SPACE, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_KW_VAL_SETENV, LINE_OPT_SEP_SPACE_AROUND],
                                      'setenv '.$EXPECTED_KW_VAL_SIMPLE, "(KW_VAL_SETENV separator changed from ' : ' to ' ', line replaced)");

test_update_line($obj, $FILENAME, '', [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL_SETENV, 0],
                                      'setenv '.$KEYWORD_SPACE."\n", "(KW_VAL_SETENV keyword without value added)");
test_update_line($obj, $FILENAME, 'setenv '.$KEYWORD_SPACE, [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL_SETENV, 0],
                                      'setenv '.$KEYWORD_SPACE, "(KW_VAL_SETENV keyword without value not replaced)");
test_update_line($obj, $FILENAME, 'setenv '.$KEYWORD_SPACE."\n", [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL_SETENV, 0, 1],
                                      'setenv '.$KEYWORD_SPACE."\n", "(KW_VAL_SETENV keyword without value not replaced, multiple flag ignored)");
test_update_line($obj, $FILENAME, "#setenv  ".$KEYWORD_SPACE, [$KEYWORD_SPACE, '', LINE_FORMAT_KW_VAL_SETENV, 0],
                                      'setenv '.$KEYWORD_SPACE."\n", "(KW_VAL_SETENV commented keyword with missign new line and without value uncommented)");


# LINE_FORMAT_ENV_VAR

test_update_line($obj, $FILENAME, '', [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_ENV_VAR, 0],
                                      $EXPECTED_ENV_VAR_SIMPLE, "(ENV_VAR: line added to empty file)");
test_update_line($obj, $FILENAME, 'export '.$EXPECTED_KW_VAL_EQUAL, [$KEYWORD_SIMPLE_2, $VALUE_STR_2, LINE_FORMAT_ENV_VAR, 0],
                                      'export '.$EXPECTED_KW_VAL_EQUAL.$EXPECTED_ENV_VAR_SIMPLE_3, "(ENV_VAR: line appended)");
test_update_line($obj, $FILENAME, 'export '.$EXPECTED_KW_VAL_EQUAL, [$KEYWORD_SIMPLE, $VALUE_STR_2, LINE_FORMAT_ENV_VAR, 0],
                                      $EXPECTED_ENV_VAR_SIMPLE_2, "(ENV_VAR: line replaced)");
test_update_line($obj, $FILENAME, 'export '.$EXPECTED_KW_VAL_EQUAL, [$KEYWORD_SIMPLE, '', LINE_FORMAT_ENV_VAR, 0],
                                      'export '.$EXPECTED_SH_VAR_KW_ONLY,"(ENV_VAR: line replaced with keyword only");
test_update_line($obj, $FILENAME, '# '.$EXPECTED_ENV_VAR_SIMPLE_2, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_ENV_VAR, 0],
                                      $EXPECTED_ENV_VAR_SIMPLE, "(ENV_VAR: commented line updated with new value");

# LINE_FORMAT_ENV_VAR

test_update_line($obj, $FILENAME, '', [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_SH_VAR, 0],
                                      $EXPECTED_SH_VAR_SIMPLE, "(SH_VAR: line added to empty file)");
test_update_line($obj, $FILENAME, $EXPECTED_SH_VAR_SIMPLE_3, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_SH_VAR, 0],
                                      $EXPECTED_SH_VAR_SIMPLE_3.$EXPECTED_SH_VAR_SIMPLE, "(SH_VAR: line appended)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL2_EQUAL, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_SH_VAR, 0],
                                      $EXPECTED_SH_VAR_SIMPLE, "(SH_VAR: line replaced)");
test_update_line($obj, $FILENAME, $EXPECTED_KW_VAL_EQUAL, [$KEYWORD_SIMPLE, '', LINE_FORMAT_SH_VAR, 0],
                                      $EXPECTED_SH_VAR_KW_ONLY,"(SH_VAR: line replaced with keyword only");
test_update_line($obj, $FILENAME, '# '.$EXPECTED_SH_VAR_SIMPLE_2, [$KEYWORD_SIMPLE, $VALUE_STR, LINE_FORMAT_SH_VAR, 0],
                                      $EXPECTED_SH_VAR_SIMPLE, "(SH_VAR: commented line updated with new value");



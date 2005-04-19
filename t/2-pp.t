#!/usr/bin/perl
# $File: //member/autrijus/PAR/t/2-pp.t $ $Author: autrijus $
# $Revision: #10 $ $Change: 10678 $ $DateTime: 2004/05/24 13:46:23 $

use strict;
use Cwd;
use Config;
use FindBin;
use File::Spec;
use ExtUtils::MakeMaker;

chdir File::Spec->catdir($FindBin::Bin, File::Spec->updir);

my $cwd = getcwd();
my $test_dir = File::Spec->catdir($cwd, 'contrib', 'automated_pp_test');

my $parl = File::Spec->catfile($cwd, 'blib', 'script', "parl$Config{_exe}");
my $startperl = $Config{startperl};
$startperl =~ s/^#!//;

my $orig_X = $^X;
my $orig_startperl = $startperl;

if (!-e $parl) {
    print "1..1\n";
    print "ok 1 # skip 'parl' not found\n";
    exit;
}
elsif (!($^X = main->can_run($^X))) {
    print "1..1\n";
    print "ok 1 # skip '$orig_X' not found\n";
    exit;
}
elsif (!($startperl = main->can_run($startperl))) {
    print "1..1\n";
    print "ok 1 # skip '$orig_startperl' not found\n";
    exit;
}

if (defined &Win32::GetShortPathName) {
    $^X = lc(Win32::GetShortPathName($^X));
    $startperl = lc(Win32::GetShortPathName($startperl));
}

if ($startperl ne $^X) {
    print "1..1\n";
    print "ok 1 # skip '$^X' is not the same as '$startperl'\n";
    exit;
}

unshift @INC, File::Spec->catdir($cwd, 'inc');
unshift @INC, File::Spec->catdir($cwd, 'blib', 'lib');
unshift @INC, File::Spec->catdir($cwd, 'blib', 'script');

$ENV{PAR_GLOBAL_CLEAN} = 1;

$ENV{PATH} = join(
    $Config{path_sep},
    grep length,
        File::Spec->catdir($cwd, 'blib', 'script'),
        $ENV{PATH},
);
$ENV{PERL5LIB} = join(
    $Config{path_sep},
    grep length,
        File::Spec->catdir($cwd, 'blib', 'lib'),
        $test_dir,
        $ENV{PERL5LIB},
);

chdir $test_dir;
do "automated_pp_test.pl";

sub can_run {
    my ($self, $cmd) = @_;

    my $_cmd = $cmd;
    return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

    for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
        my $abs = File::Spec->catfile($dir, $_[1]);
        return $abs if (-x $abs or $abs = MM->maybe_command($abs));
    }

    return;
}

__END__

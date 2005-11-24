#line 1 "inc/Module/Install/PRIVATE/PAR.pm - /usr/local/lib/perl5/site_perl/5.8.6/Module/Install/PRIVATE/PAR.pm"
# $File: //member/autrijus/Module-Install-PRIVATE/lib/Module/Install/PRIVATE/PAR.pm $ $Author: autrijus $
# $Revision: #14 $ $Change: 10724 $ $DateTime: 2004/06/02 11:57:09 $ vim: expandtab shiftwidth=4

package Module::Install::PRIVATE::PAR;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

use 5.006;
use FindBin;
use Config ();

my %no_parl  = ();

sub Autrijus_PAR {
    my $self = shift;
    my $bork = $no_parl{$^O};
    my $cc   = $self->can_cc unless $bork;
    my $par  = $self->fetch_par('', '', !$cc) unless $cc or $bork;
    my $exe  = $Config::Config{_exe};
    my $dynperl = $Config::Config{useshrplib} && ($Config::Config{useshrplib} ne 'false');

    if ($bork) {
        warn "Binary loading known to fail on $^O; won't generate 'script/parl$exe'!\n";
    }
    elsif (!$par and !$cc) {
        warn "No compiler found, won't generate 'script/parl$exe'!\n";
    }

    # XXX: this branch is currently not entered
    if ($cc and $par) {
        my $answer = $self->prompt(
            "*** Pre-built PAR package found.  Use it instead of recompiling [y/N]?"
        );
        if ($answer !~ /^[Yy]/) {
            $self->load('preamble')->{preamble} = '';
            $par = '';
        }
    } 

    my @bin = ("script/parl$exe", "myldr/par$exe");
    push @bin, ("script/parldyn$exe", "myldr/static$exe") if $dynperl;

    $FindBin::Bin = '.' unless -e "$FindBin::Bin/Makefile.PL";
    my $par_exe = "$FindBin::Bin/$bin[1]";

    if ($par) {
        open my $fh, '>', $par_exe or die "Cannot write to $par_exe";
        close $fh;
    }
    elsif (-f $par_exe and not -s $par_exe) {
        unlink $par_exe;
    }

    $self->clean_files(@bin) if $par or $cc;

    $self->makemaker_args(
        MAN1PODS		=> {
            'script/par.pl'	=> 'blib/man1/par.pl.1',
            'script/pp'	        => 'blib/man1/pp.1',
            'script/tkpp'       => 'blib/man1/tkpp.1',
          ($par or $cc) ? (
            'script/parl.pod'   => 'blib/man1/parl.1',
          ) : (),
        },
        EXE_FILES		=> [
            'script/par.pl',
            'script/pp',
            'script/tkpp',
          (!$par and $cc) ? (
            "script/parl$exe",
            $dynperl ? (
                "script/parldyn$exe",
            ) : (),
          ) : (),
        ],
        DIR                     => [
          (!$par and $cc) ? (
            'myldr'
          ) : (),
        ],
        NEEDS_LINKING	        => 1,
    );
}

sub Autrijus_PAR_fix {
    my $self = shift;

    my $exe = $Config::Config{_exe};
    return unless $exe eq '.exe';

    open my $in, '<', "$FindBin::Bin/Makefile" or return;
    open my $out, '>', "$FindBin::Bin/Makefile.new" or return;
    while (<$in>) {
        next if /^\t\$\(FIXIN\) .*\Q$exe\E$/;
        next if /^\@\[$/ or /^\]$/;
        print $out $_;
    }
    close $out;
    close $in;
    unlink "$FindBin::Bin/Makefile";
    rename "$FindBin::Bin/Makefile.new" => "$FindBin::Bin/Makefile";
}

1;

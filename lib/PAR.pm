package PAR;
$PAR::VERSION = '0.87';

use 5.006;
use strict;
use warnings;
use Config '%Config';

=head1 NAME

PAR - Perl Archive Toolkit

=head1 VERSION

This document describes version 0.87 of PAR, released January 31, 2005.

=head1 SYNOPSIS

(If you want to make an executable that contains all module, scripts and
data files, please consult the bundled L<pp> utility instead.)

Following examples assume a F<foo.par> file in Zip format; support for
compressed tar (F<*.tgz>/F<*.tbz2>) format is under consideration.

To use F<Hello.pm> from F<./foo.par>:

    % perl -MPAR=./foo.par -MHello
    % perl -MPAR=./foo -MHello          # the .par part is optional

Same thing, but search F<foo.par> in the C<@INC>;

    % perl -MPAR -Ifoo.par -MHello
    % perl -MPAR -Ifoo -MHello          # ditto

Following paths inside the PAR file are searched:

    /lib/
    /arch/
    /i386-freebsd/              # i.e. $Config{archname}
    /5.8.0/                     # i.e. $Config{version}
    /5.8.0/i386-freebsd/        # both of the above
    /

PAR files may also (recursively) contain other PAR files.
All files under following paths will be considered as PAR
files and searched as well:

    /par/i386-freebsd/          # i.e. $Config{archname}
    /par/5.8.0/                 # i.e. $Config{version}
    /par/5.8.0/i386-freebsd/    # both of the above
    /par/

Run F<script/test.pl> or F<test.pl> from F<foo.par>:

    % perl -MPAR foo.par test.pl        # only when $0 ends in '.par'

However, if the F<.par> archive contains either F<script/main.pl> or
F<main.pl>, then it is used instead:

    % perl -MPAR foo.par test.pl        # runs main.pl; @ARGV is 'test.pl'

Use in a program:

    use PAR 'foo.par';
    use Hello; # reads within foo.par

    # PAR::read_file() returns a file inside any loaded PARs
    my $conf = PAR::read_file('data/MyConfig.yaml');

    # PAR::par_handle() returns an Archive::Zip handle
    my $zip = PAR::par_handle('foo.par')
    my $src = $zip->memberNamed('lib/Hello.pm')->contents;

You can also use wildcard characters:

    use PAR '/home/foo/*.par';  # loads all PAR files in that directory

=head1 DESCRIPTION

This module lets you easily bundle a typical F<blib/> tree into a zip
file, called a Perl Archive, or C<PAR>.

It supports loading XS modules by overriding B<DynaLoader> bootstrapping
methods; it writes shared object file to a temporary file at the time it
is needed.

To generate a F<.par> file, all you have to do is compress the modules
under F<arch/> and F<lib/>, e.g.:

    % perl Makefile.PL
    % make
    % cd blib
    % zip -r mymodule.par arch/ lib/

Afterward, you can just use F<mymodule.par> anywhere in your C<@INC>,
use B<PAR>, and it will Just Work.

For convenience, you can set the C<PERL5OPT> environment variable to
C<-MPAR> to enable C<PAR> processing globally (the overhead is small
if not used); setting it to C<-MPAR=/path/to/mylib.par> will load a
specific PAR file.  Alternatively, consider using the F<par.pl> utility
bundled with this module, or using the self-contained F<parl> utility
on machines without PAR.pm installed.

Note that self-containing scripts and executables created with F<par.pl>
and F<pp> may also be used as F<.par> archives:

    % pp -o packed.exe source.pl        # generate packed.exe
    % perl -MPAR=packed.exe other.pl    # this also works
    % perl -MPAR -Ipacked.exe other.pl  # ditto

Please see L</SYNOPSIS> for most typical use cases.

=head1 NOTES

Settings in F<META.yml> packed inside the PAR file may affect PAR's
operation.  For example, F<pp> provides the C<-C> (C<--clean>) option
to control the default behavior of temporary file creation.

Currently, F<pp>-generated PAR files may attach four PAR-specific
attributes in F<META.yml>:

    par:
      clean: 0          # default value of PAR_CLEAN
      signature: ''     # key ID of the SIGNATURE file
      verbatim: 0       # was packed prerequisite's PODs preserved?
      version: x.xx     # PAR.pm version that generated this PAR

User-defined environment variables, like I<PAR_CLEAN>, always
overrides the ones set in F<META.yml>.  The algorithm for generating
caching/temporary directory is as follows:

=over 4

=item *

If I<PAR_TEMP> is specified, use it as the cache directory for
extracted libraries, and do not clean it up after execution.

=item *

If I<PAR_TEMP> is not set, but I<PAR_CLEAN> is specified, set
I<PAR_TEMP> to C<I<TEMP>\par-I<USER>\temp-I<PID>\>, cleaning it
after execution.

=item *

If both are not set, use C<I<TEMP>\par-I<USER>\temp-I<MTIME>\>
as the I<PAR_TEMP>, reusing any existing files inside.  I<MTIME>
is the last-modified timestamp of the program.

=back

=cut

use vars qw(@PAR_INC);  # explicitly stated PAR library files
use vars qw(%PAR_INC);  # sets {$par}{$file} for require'd modules
use vars qw(@LibCache %LibCache);       # I really miss pseudohash.
use vars qw($LastAccessedPAR $LastTempFile);

my $ver  = $Config{version};
my $arch = $Config{archname};
my $progname = $ENV{PAR_PROGNAME} || $0;
my $is_insensitive_fs = (
    -s $progname
        and (-s lc($progname) || -1) == (-s uc($progname) || -1)
        and (-s lc($progname) || -1) == -s $progname
);
my $par_temp;

sub import {
    my $class = shift;

    _set_progname();
    _set_par_temp();

    $progname = $ENV{PAR_PROGNAME} ||= $0;
    $is_insensitive_fs = (-s $progname and (-s lc($progname) || -1) == (-s uc($progname) || -1));

    foreach my $par (@_) {
        if ($par =~ /[?*{}\[\]]/) {
            require File::Glob;
            foreach my $matched (File::Glob::glob($par)) {
                push @PAR_INC, unpar($matched, undef, undef, 1);
            }
            next;
        }

        push @PAR_INC, unpar($par, undef, undef, 1);
    }

    return if $PAR::__import;
    local $PAR::__import = 1;

    unshift @INC, \&find_par unless grep { $_ eq \&find_par } @INC;

    require PAR::Heavy;
    PAR::Heavy::_init_dynaloader();

    if (unpar($progname)) {
        # XXX - handle META.yml here!
        push @PAR_INC, unpar($progname, undef, undef, 1);

        _extract_inc($progname) unless $ENV{PAR_CLEAN};

        my $zip = $LibCache{$progname};
        my $member = _first_member( $zip,
            "script/main.pl",
            "main.pl",
        );

        # finally take $ARGV[0] as the hint for file to run
        if (defined $ARGV[0] and !$member) {
            $member = _first_member( $zip,
                "script/$ARGV[0]",
                "script/$ARGV[0].pl",
                $ARGV[0],
                "$ARGV[0].pl",
            ) or die qq(Can't open perl script "$ARGV[0]": No such file or directory);
            shift @ARGV;
        }
        elsif (!$member) {
            die "Usage: $0 script_file_name.\n";
        }

        _run_member($member);
    }
}

sub _first_member {
    my $zip = shift;
    my %names = map { ( $_->fileName => $_ ) } $zip->members;
    my %lc_names = map { ( lc($_->fileName) => $_ ) } $zip->members;
    foreach my $name (@_) {
        return $names{$name} if $names{$name};
        return $lc_names{lc($name)} if $is_insensitive_fs and $lc_names{lc($name)};
    }
    return;
}

sub _run_member {
    my $member = shift;
    my $clear_stack = shift;
    my ($fh, $is_new, $filename) = _tempfile($member->crc32String . ".pl");

    if ($is_new) {
        my $file = $member->fileName;
        print $fh "package main; shift \@INC;\n";
        if (defined &Internals::PAR::CLEARSTACK and $clear_stack) {
            print $fh "Internals::PAR::CLEARSTACK();\n";
        }
        print $fh "#line 1 \"$file\"\n";
        $member->extractToFileHandle($fh);
        seek ($fh, 0, 0);
    }

    unshift @INC, sub { $fh };

    $ENV{PAR_0} = $filename; # for Pod::Usage
    { do 'main'; die $@ if $@; exit }
}

sub _extract_inc {
    my $file = shift;
    my $inc = "$par_temp/inc";
    my $dlext = do {
        require Config;
        (defined %Config::Config) ? $Config::Config{dlext} : '';
    };

    if (!-d $inc) {
        for (1 .. 10) { mkdir("$inc.lock", 0755) and last; sleep 1 }

        open my $fh, '<', $file or die "Cannot find '$file': $!";
        binmode($fh);
        bless($fh, 'IO::File');

        my $zip = Archive::Zip->new;
        ( $zip->readFromFileHandle($fh, $file) == Archive::Zip::AZ_OK() )
            or die "Read '$file' error: $!";

        for ( $zip->memberNames() ) {
            next if m{\.\Q$dlext\E[^/]*$};
            s{^/}{};
            $zip->extractMember($_, "$inc/" . $_);
        }
        rmdir("$inc.lock");
    }

    unshift @INC, grep -d, map join('/', $inc, @$_),
        [ 'lib' ], [ 'arch' ], [ $arch ], [ $ver ], [ $ver, $arch ], [];
}

sub find_par {
    my ($self, $file, $member_only) = @_;

    my $scheme;
    foreach (@PAR_INC ? @PAR_INC : @INC) {
        my $path = $_;
        if ($[ < 5.008001) {
            # reassemble from "perl -Ischeme://path" autosplitting
            $path = "$scheme:$path" if !@PAR_INC
                and $path and $path =~ m!//!
                and $scheme and $scheme =~ /^\w+$/;
            $scheme = $path;
        }
        my $rv = unpar($path, $file, $member_only, 1) or next;
        $PAR_INC{$path}{$file} = 1;
        $INC{$file} = $LastTempFile if (lc($file) =~ /^(?!tk).*\.pm$/);
        return $rv;
    }

    return;
}

sub reload_libs {
    my @par_files = @_;
    @par_files = sort keys %LibCache unless @par_files;

    foreach my $par (@par_files) {
        my $inc_ref = $PAR_INC{$par} or next;
        delete $LibCache{$par};
        foreach my $file (sort keys %$inc_ref) {
            delete $INC{$file};
            require $file;
        }
    }
}

sub read_file {
    my $file = pop;

    foreach my $zip (@LibCache) {
        my $member = _first_member($zip, $file) or next;
        return scalar $member->contents;
    }

    return;
}

sub par_handle {
    my $par = pop;
    return $LibCache{$par};
}

my %escapes;
sub unpar {
    my ($par, $file, $member_only, $allow_other_ext) = @_;
    my $zip = $LibCache{$par};
    my @rv = $par;

    return if $PAR::__unpar;
    local $PAR::__unpar = 1;

    unless ($zip) {
        if ($par =~ m!^\w+://!) {
            require File::Spec;
            require LWP::Simple;

            # reflector support
            $par .= "pm=$file" if $par =~ /[?&;]/;

            $ENV{PAR_CACHE} ||= '_par';
            mkdir $ENV{PAR_CACHE}, 0777;
            if (!-d $ENV{PAR_CACHE}) {
                $ENV{PAR_CACHE} = File::Spec->catdir(File::Spec->tmpdir, 'par');
                mkdir $ENV{PAR_CACHE}, 0777;
                return unless -d $ENV{PAR_CACHE};
            }

            my $file = $par;
            if (!%escapes) {
                $escapes{chr($_)} = sprintf("%%%02X", $_) for 0..255;
            }
            {
                use bytes;
                $file =~ s/([^\w\.])/$escapes{$1}/g;
            }
            $file = File::Spec->catfile( $ENV{PAR_CACHE}, $file);
            LWP::Simple::mirror( $par, $file );
            return unless -e $file;
            $par = $file;
        }
        elsif (ref($par) eq 'SCALAR') {
            my ($fh) = _tempfile();
            print $fh $$par;
            $par = $fh;
        }
        elsif (!(($allow_other_ext or $par =~ /\.par\z/i) and -f $par)) {
            $par .= ".par";
            return unless -f $par;
        }

        require Archive::Zip;
        $zip = Archive::Zip->new;

	my @file;
        if (!ref $par) {
	    @file = $par;

            open my $fh, '<', $par;
            binmode($fh);

            $par = $fh;
            bless($par, 'IO::File');
        }

        Archive::Zip::setErrorHandler(sub {});
        my $rv = $zip->readFromFileHandle($par, @file);
        Archive::Zip::setErrorHandler(undef);
        return unless $rv == Archive::Zip::AZ_OK();

        push @LibCache, $zip;
        $LibCache{$_[0]} = $zip;

        foreach my $member ( $zip->membersMatching(
            "^par/(?:$Config{version}/)?(?:$Config{archname}/)?"
        ) ) {
            next if $member->isDirectory;
            my $content = $member->contents();
            next unless $content =~ /^PK\003\004/;
            push @rv, unpar(\$content, undef, undef, 1);
        }
    }

    $LastAccessedPAR = $zip;

    return @rv unless defined $file;

    my $member = _first_member($zip,
        "lib/$file",
        "arch/$file",
        "$arch/$file",
        "$ver/$file",
        "$ver/$arch/$file",
        $file,
    ) or return;

    return $member if $member_only;

    my ($fh, $is_new);
    ($fh, $is_new, $LastTempFile) = _tempfile($member->crc32String . ".pm");
    die "Bad Things Happened..." unless $fh;

    if ($is_new) {
        $member->extractToFileHandle($fh);
        seek ($fh, 0, 0);
    }

    return $fh;
}

# The C version of this code appears in myldr/mktmpdir.c
sub _set_par_temp {
    if ($ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/) {
        $par_temp = $1;
        return;
    }

    require File::Spec;

    foreach my $path (
        (map $ENV{$_}, qw( TMPDIR TEMP TMP )),
        qw( C:\\TEMP /tmp . )
    ) {
        next unless $path and -d $path and -w $path;
        my $username = defined(&Win32::LoginName)
            ? &Win32::LoginName()
            : $ENV{USERNAME} || $ENV{USER} || 'SYSTEM';
        $username =~ s/\W/_/g;

        my $stmpdir = File::Spec->catdir($path, "par-$username");
        mkdir $stmpdir, 0755;
        if (!$ENV{PAR_CLEAN} and my $mtime = (stat($progname))[9]) {
            my $ctx = eval { require Digest::SHA; Digest::SHA->new(1) }
                   || eval { require Digest::SHA1; Digest::SHA1->new }
                   || eval { require Digest::MD5; Digest::MD5->new };

            if ($ctx and open(my $fh, "<$progname")) {
                binmode($fh);
                $ctx->addfile($fh);
                close($fh);
            }

            $stmpdir = File::Spec->catdir(
                $stmpdir,
                "cache-" . ( $ctx ? $ctx->hexdigest : $mtime )
            );
        }
        else {
            $ENV{PAR_CLEAN} = 1;
            $stmpdir = File::Spec->catdir($stmpdir, "temp-$$");
        }

        $ENV{PAR_TEMP} = $stmpdir;
        mkdir $stmpdir, 0755;
        last;
    }

    $par_temp = $1 if $ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/;
}

sub _tempfile {
    if ($ENV{PAR_CLEAN} or !@_) {
        require File::Temp;

        if (defined &File::Temp::tempfile) {
            # under Win32, the file is created with O_TEMPORARY,
            # and will be deleted by the C runtime; having File::Temp
            # delete it has the only effect of giving ugly warnings
            my ($fh, $filename) = File::Temp::tempfile(
                DIR     => $par_temp,
                UNLINK  => ($^O ne 'MSWin32'),
            ) or die "Cannot create temporary file: $!";
            binmode($fh);
            return ($fh, 1, $filename);
        }
    }

    require File::Spec;
    my $filename = File::Spec->catfile( $par_temp, $_[0] );
    if (-r $filename) {
        open my $fh, '<', $filename or die $!;
        binmode($fh);
        return ($fh, 0, $filename);
    }

    open my $fh, '+>', $filename or die $!;
    binmode($fh);
    return ($fh, 1, $filename);
}

sub _set_progname {
    require File::Spec;

    if ($ENV{PAR_PROGNAME} and $ENV{PAR_PROGNAME} =~ /(.+)/) {
        $progname = $1;
    }
    $progname ||= $0;

    if (( () = File::Spec->splitdir($progname) ) > 1 or !$ENV{PAR_PROGNAME}) {
        if (open my $fh, $progname) {
            return if -s $fh;
        }
        if (-s "$progname$Config{_exe}") {
            $progname .= $Config{_exe};
            return;
        }
    }

    foreach my $dir (split /\Q$Config{path_sep}\E/, $ENV{PATH}) {
        next if exists $ENV{PAR_TEMP} and $dir eq $ENV{PAR_TEMP};
        my $name = File::Spec->catfile($dir, "$progname$Config{_exe}");
        if (-s $name) { $progname = $name; last }
        $name = File::Spec->catfile($dir, "$progname");
        if (-s $name) { $progname = $name; last }
    }
}

1;

=head1 SEE ALSO

L<PAR::Tutorial>, L<PAR::FAQ>

L<par.pl>, L<parl>, L<pp>

L<Archive::Zip>, L<perlfunc/require>

L<ex::lib::zip>, L<Acme::use::strict::with::pride>

=head1 ACKNOWLEDGMENTS

Nicholas Clark for pointing out the mad source filter hook within the
(also mad) coderef C<@INC> hook, as well as (even madder) tricks one
can play with PerlIO to avoid source filtering.

Ton Hospel for convincing me to ditch the C<Filter::Simple>
implementation.

Uri Guttman for suggesting C<read_file> and C<par_handle> interfaces.

Antti Lankila for making me implement the self-contained executable
options via C<par.pl -O>.

See the F<AUTHORS> file in the distribution for a list of people who
have sent helpful patches, ideas or comments.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

L<http://par.perl.org/> is the official PAR website.  You can write
to the mailing list at E<lt>par@perl.orgE<gt>, or send an empty mail to
E<lt>par-subscribe@perl.orgE<gt> to participate in the discussion.

Please submit bug reports to E<lt>bug-par@rt.cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2002, 2003, 2004, 2005 by Autrijus Tang
E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

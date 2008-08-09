package PAR::SetupTemp;
$PAR::VERSION = '0.982';

use 5.006;
use strict;
use warnings;

use PAR::SetupProgname;

=head1 NAME

PAR::SetupTemp - Setup $ENV{PAR_TEMP}

=head1 SYNOPSIS

PAR guts, beware. Check L<PAR>

=head1 DESCRIPTION

Routines to setup the C<PAR_TEMP> environment variable.
The documentation of how the temporary directories are handled
is currently scattered across the C<PAR> manual and the
C<PAR::Environment> manual.

The C<set_par_temp_env()> subroutine sets up the C<PAR_TEMP>
environment variable.

=cut

# for PAR internal use only!
our $PARTemp;

# The C version of this code appears in myldr/mktmpdir.c
# This code also lives in PAR::Packer's par.pl as _set_par_temp!
sub set_par_temp_env {
    PAR::SetupProgname::set_progname()
      unless defined $PAR::SetupProgname::Progname;

    if ($ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/) {
        $PARTemp = $1;
        return;
    }

    return if $ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/;

    require File::Spec;

    foreach my $path (
        (map $ENV{$_}, qw( PAR_TMPDIR TMPDIR TEMPDIR TEMP TMP )),
        qw( C:\\TEMP /tmp . )
    ) {
        next unless $path and -d $path and -w $path;
        my $username;
        my $pwuid;
        # does not work everywhere:
        eval {($pwuid) = getpwuid($>) if defined $>;};

        if ( defined(&Win32::LoginName) ) {
            $username = &Win32::LoginName;
        }
        elsif (defined $pwuid) {
            $username = $pwuid;
        }
        else {
            $username = $ENV{USERNAME} || $ENV{USER} || 'SYSTEM';
        }
        $username =~ s/\W/_/g;

        my $stmpdir = File::Spec->catdir($path, "par-$username");
        ($stmpdir) = $stmpdir =~ /^(.*)$/s;
        mkdir $stmpdir, 0755;
        if (!$ENV{PAR_CLEAN} and my $mtime = (stat($PAR::SetupProgname::Progname))[9]) {
            my $ctx = eval { require Digest::SHA; Digest::SHA->new(1) }
                   || eval { require Digest::SHA1; Digest::SHA1->new }
                   || eval { require Digest::MD5; Digest::MD5->new };

            # Workaround for bug in Digest::SHA 5.38 and 5.39
            my $sha_version = eval { $Digest::SHA::VERSION } || 0;
            if ($sha_version eq '5.38' or $sha_version eq '5.39') {
                $ctx->addfile($PAR::SetupProgname::Progname, "b") if ($ctx);
            }
            else {
                if ($ctx and open(my $fh, "<$PAR::SetupProgname::Progname")) {
                    binmode($fh);
                    $ctx->addfile($fh);
                    close($fh);
                }
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

    $PARTemp = $1 if $ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/;
}

1;

__END__

=head1 SEE ALSO

The PAR homepage at L<http://par.perl.org>.

L<PAR>, L<PAR::Environment>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>,
Steffen Mueller E<lt>smueller@cpan.orgE<gt>

L<http://par.perl.org/> is the official PAR website.  You can write
to the mailing list at E<lt>par@perl.orgE<gt>, or send an empty mail to
E<lt>par-subscribe@perl.orgE<gt> to participate in the discussion.

Please submit bug reports to E<lt>bug-par@rt.cpan.orgE<gt>. If you need
support, however, joining the E<lt>par@perl.orgE<gt> mailing list is
preferred.

=head1 COPYRIGHT

Copyright 2002-2008 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut


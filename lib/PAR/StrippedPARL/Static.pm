package PAR::StrippedPARL::Static;
use vars qw/$VERSION/;
$VERSION = '0.958';

my $Data_Pos = tell DATA;

=head1 NAME

PAR::StrippedPARL::Static - Data package containing a static PARL

=head1 SYNOPSIS

  my $binary = PAR::StrippedPARL::Static->get_data();
  if (not defined $binary) {
      die "Static stripped PARL not available";
  }
  open my $fh, '>', 'parl' or die $!;
  binmode $fh;
  print $fh $binary;

  # or:
  unless( PAR::StrippedPARL::Static->write_data('parl') ) {
      die "Static stripped PARL not available";
  }

=head1 DESCRIPTION

This class is internal to PAR. Do not use it outside of PAR.

This class is basically just a container for a static binary PAR loader
which doesn't include the PAR code like the F<parl> or F<parl.exe>
you are used to. If you're really curious, I'll tell you it is
just a copy of the F<myldr/static> (or F<myldr/static.exe>) file.

The data is appended during the C<make> phase of the PAR build process.

If the binary data isn't appended during the build process, the two class
methods will return the empty list.

=head1 CLASS METHODS

=head2 get_data

Returns the binary data attached to this package or the empty list if
the binary data could not be accessed.

Returns the empty list on failure.

=cut

sub get_data {
    my $class = shift;
    seek DATA, $Data_Pos, 0 or die $!;
    binmode DATA;
    local $/ = undef;
    my $data = <DATA>;
    $data =~ s/^\s*//;
    my $binary = unpack 'u', $data;
    return() if not defined $binary or $binary !~ /\S/;
    return $binary;
}

=head2 write_data

Takes a file name as argument and writes the binary data to the file.

Returns true on success and the empty list on failure.

=cut

sub write_data {
    my $class = shift;
    my $file = shift;
    if (not defined $file) {
        warn "${class}->write_data() needs a file name as argument";
        return();
    }
    my $binary = $class->get_data();
    return() if not defined $binary;

    open my $fh, '>', $file or die "Could not open file '$file' for writing: $!";
    binmode $fh;
    print $fh $binary;
    close $fh;

    return 1;
}

=head1 AUTHORS

Steffen Mueller E<lt>smueller@cpan.orgE<gt>,
Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

__DATA__


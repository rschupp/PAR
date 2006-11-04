=head1 NAME

PAR::Environment - Index and reference of PAR environment variables

=head1 DESCRIPTION

PAR uses various environment variables both during the building process of
executables or PAR archives and the I<use> of them. Since the wealth of
combinations and settings might confuse one or the other (like me), this
document is intended to document all environment variables which PAR uses.

Wherever I want to refer to the C<$ENV{FOO}> environment hash entry, I will
usually talk about the C<FOO> variable for brevity.

=head1 INDEX OF ENVIRONMENT VARIABLES

B<Please note that this is still very, very incomplete! Contributions welcome!>

For each variable, there should be a description what it contains, when
it can be expected to exist (and contain meaningful information),
when it is sensible to define it yourself, and what effect this has.

Of course, the description may use examples.

=head2 PAR_0

If the running program is run from within a PAR archive or pp-produced
executable, this variable contains the name of the extracted program
(i.e. .pl file). This is useful of you want to open the source code
file of the running program.

For example, if you package a file F<foo.pl> into
F<bar.par> and run F<foo.pl> with this command

  par.pl foo.par bar.pl

then the C<PAR_0> variable will contain something like
C</tmp/par-tsee/cache-b175f53eb731da9594e0dde337d66013ddf25a44/495829f0.pl>
where C<tsee> is my username and
C</tmp/par-tsee/cache-b175f53eb731da9594e0dde337d66013ddf25a44/> is the
PAR cache directory (C<PAR_TEMP>).

This works the same for executable binaries (F<.exe>, ...).

If you are looking for the name and path of the pp-ed binary file,
please refer to the C<PAR_PROGNAME> variable.

=head2 PAR_ARGC

# FIXME

=head2 PAR_ARGV_0 ...

# FIXME

=head2 PAR_CLEAN

# FIXME

=head2 PAR_DEBUG

# FIXME

=head2 PAR_GLOBAL_CLEAN

# FIXME

=head2 PAR_GLOBAL_TEMP

# FIXME

=head2 PAR_GLOBAL_TMPDIR

# FIXME

=head2 PAR_GLOBAL_DEBUG

# FIXME

=head2 PAR_INITIALIZED

This environment variable is for internal use by the PAR binary loader
only.

=head2 PAR_PROGNAME

# FIXME

=head2 PAR_RUN

This environment variable was set during constructions of C<PAR::Packer>
objects (usually during F<pp> runs only) by versions of PAR up to
0.957. Since PAR 0.958, this variable is unused.

=head2 PAR_SPAWNED

This variable is used internally by the F<parl> binary loader to signal
the child process that it's the child.

You should not rely on this variable outside of the PAR binary loader
code. For a slightly more detailed discussion, please refer to the
F<who_am_i.txt> documentation file in the PAR source distribution
which was contributed by Alan Stewart.

=head2 PAR_TEMP

# FIXME

=head2 PAR_TMPDIR

B<This needs some attention!>

Do not set C<PAR_TMPDIR>. Set C<PAR_GLOBAL_TMPDIR> or
C<PAR_GLOBAL_TEMP> instead.

While determining where to create the temporary directory C<PAR_TEMP>
for the PAR cache of the running executable or PAR archive,
F<PAR.pm> and the corresponding C code in F<myldr/mktmpdir.c>
try to find the systems temporary path via various means.

First, the environment variable C<PAR_TMPDIR> is tried and used
if it exists, then in order C<TMPDIR>, C<TEMPDIR>
(since 0.958), C<TEMP>, C<TMP>.

Finally, the literal paths C<C:\\TEMP>, C</tmp> and C<.> are
tried as fallbacks.

Don't get this mixed up with C<PAR_TEMP>. C<PAR_TEMP> contains the
temporary directory of this specific cache. If C<PAR_TMP> is, for
example C</tmp/foo>, then the cache directory (C<PAR_TEMP>) will
be something like C</tmp/foo/cache-XXXXXXXXXXXXXXXX>.

=head2 PAR_VERBATIM

The C<PAR_VERBATIM> variable controls the way Perl code is packaged
into a PAR archive or binary executable. If it is set to a true
value during the packaging process, modules (and scripts) are
B<not> passed through the default C<PAR::Filter::PodStrip> filter
which removes all POD documentation from the code. Note that the
C<PAR::Filter::PatchContent> filter is still applied.

The C<-F> option to the F<pp> tool overrides the C<PAR_VERBATIM>
setting. That means if you set C<PAR_VERBATIM=1> but specify
C<-F PodStrip> on the C<pp> command line, the C<PodStrip> filter
will be applied.

=head2 PAR_VERBOSE

Setting this environment variable to a positive integer
has the same effect as using the C<-verbose> switch to F<pp>.

=head2 PP_OPTS

During a F<pp> run, the contents of the C<PP_OPTS> variable are
treated as if they were part of the command line. In newer versions
of PAR, you can also write options to a file and execute F<pp>
as follows to read the options from the file:

  pp @FILENAME

That can, of course, be combined with other command line arguments
to F<pp> or the C<PP_OPTS> variable.

=head2 TMP, TEMP, TMPDIR, TEMPDIR

Please refer to C<PAR_TMPDIR>.

=head1 SEE ALSO

The PAR homepage at L<http://par.perl.org>.

L<PAR>, L<PAR::Tutorial>, L<PAR::FAQ> (For a more current FAQ,
refer to the homepage.)

L<par.pl>, L<parl>, L<pp>

L<PAR::Dist> for details on PAR distributions.

=head1 AUTHORS

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

L<http://par.perl.org/> is the official PAR website.  You can write
to the mailing list at E<lt>par@perl.orgE<gt>, or send an empty mail to
E<lt>par-subscribe@perl.orgE<gt> to participate in the discussion.

Please submit bug reports to E<lt>bug-par@rt.cpan.orgE<gt>. If you need
support, however, joining the E<lt>par@perl.orgE<gt> mailing list is
preferred.

=head1 COPYRIGHT

PAR: Copyright 2006 by Audrey Tang,
E<lt>cpan@audreyt.orgE<gt>.

This document: Copyright 2006 by Steffen Mueller,
E<lt>smueller@cpan.orgE<gt>

Some information has been taken from Alan Stewart's extra documentation in the
F<contrib/> folder of the PAR distribution.

This program or documentation is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

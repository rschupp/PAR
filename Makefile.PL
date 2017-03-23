#!/usr/bin/perl

use strict;
use 5.008001;
BEGIN { push @INC, '.' unless $INC[-1] eq '.' }
use inc::Module::Install;

name        'PAR';
abstract    'Perl Archive Tookit';
all_from    'lib/PAR.pm';

perl_version '5.008001';
requires    'File::Temp'        => 0.05;
requires    'Compress::Zlib'    => ($^O eq 'MSWin32') ? 1.16 : 1.30;
requires    'Archive::Zip'      => 1.00;
requires    'PAR::Dist'         => 0.32;
requires    'AutoLoader'        => '5.66_02';
requires    'Digest::SHA'       => '5.45';

auto_provides;

license     'perl_5';
resources   repository          => 'https://github.com/rschupp/PAR',
            MailingList         => 'par@perl.org';

clean_files 't/hello.par';

WriteAll sign => 0;

sub MY::postamble {
    return <<'...';
pure_all :: 
	$(PERL) t/gen-hello-par.pl
...
}

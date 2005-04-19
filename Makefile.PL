#!/usr/bin/perl

use 5.006;
use inc::Module::Install;

name	    ('PAR');
abstract    ('Perl Archive Tookit');
version_from('lib/PAR.pm');
license	    ('perl');

requires    ('perl'             => 5.006);
requires    ('File::Temp'       => 0.05);
requires    ('Compress::Zlib'	=> ($^O eq 'MSWin32') ? 1.16 : 1.30);
requires    ('Archive::Zip'	=> 1.00);
requires    ('Module::ScanDeps'	=> 0.45);
requires    ('PAR::Dist'	=> 0.06);
features    (
    'Windows --icon and --info support'	=> [
	-default => 0,
	recommends  ('Parse::Binary' => 0.04),
	recommends  ('Win32::Exe' => 0.04),
    ],
) if ($^O eq 'MSWin32');

features    (
    'Digital signature support'	=> [
	-default => 0,
	recommends  ('Digest' => 0),
        (
            (eval { require Digest::SHA1; 1 } or
             eval { require Digest::SHA; 1 }  or
             eval { require Digest::SHA::PurePerl; 1 }) ? () :
            recommends( (can_cc() ? 'Digest::SHA' : 'Digest::SHA::PurePerl') => 0 )
        ),
	recommends  ('Module::Signature' => 0.35),
    ],
) if (eval { require Crypt::OpenPGP; 1 } or can_run('gpg'));

include('ExtUtils::AutoInstall');
include_deps('Test::More');

sign(1);
auto_install_now( -default => 0 );
no_index(directory => 'contrib');

&Autrijus->write;
&WriteAll;
&Autrijus->fix;

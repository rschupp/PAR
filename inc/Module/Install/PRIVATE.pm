#line 1 "inc/Module/Install/PRIVATE.pm - /usr/local/lib/perl5/site_perl/5.8.5/Module/Install/PRIVATE.pm"
package Module::Install::PRIVATE;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

sub Autrijus { $_[0] }

sub write {
    my ($self, $name) = @_;

    $self->author('Autrijus Tang (autrijus@autrijus.org)');
    $self->par_base('AUTRIJUS');
    $self->name($name ||= $self->name);

    my $method = "Autrijus_$name";
    $self->$method;
}

sub fix {
    my $self = shift;
    $name = $self->name;
    my $method = "Autrijus_${name}_fix";
    $self->$method;
}

1;

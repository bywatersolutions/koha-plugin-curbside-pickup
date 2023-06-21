package Koha::Plugin::Com::ByWaterSolutions::CurbsidePickup;

use Modern::Perl;

use Mojo::JSON qw(decode_json to_json);

use base qw(Koha::Plugins::Base);

use Cwd qw(abs_path);
use Encode qw(decode);
use File::Slurp qw(read_file);
use Module::Metadata;

use C4::Auth;
use C4::Circulation qw(CanBookBeIssued AddIssue);
use C4::Context;
use C4::Installer qw(TableExists);
use Koha::DateUtils qw(dt_from_string);
use Koha::Libraries;
use Koha::Schema;
use Koha::CurbsidePickupIssues;
use Koha::CurbsidePickupPolicies;
use Koha::CurbsidePickups;

our $VERSION         = "{VERSION}";
our $MINIMUM_VERSION = "{MINIMUM_VERSION}";

our $metadata = {
    name            => 'Curbside Pickup',
    author          => 'Kyle M Hall, ByWater Solutions',
    date_authored   => '2020-08-04',
    date_updated    => "1900-01-01",
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin adds curbside pickup of holds to Koha',
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub install() {
    my ( $self, $args ) = @_;

    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

sub uninstall() {
    my ( $self, $args ) = @_;

    return 1;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ($self) = @_;

    return 'curbsidepickup';
}

1;

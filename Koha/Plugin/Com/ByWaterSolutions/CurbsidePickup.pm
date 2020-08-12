package Koha::Plugin::Com::ByWaterSolutions::CurbsidePickup;

use Modern::Perl;

use Mojo::JSON qw(decode_json to_json);

use base qw(Koha::Plugins::Base);

use File::Slurp qw(read_file);
use Cwd qw(abs_path);

use C4::Auth;
use C4::Context;
use C4::Circulation;
use Koha::DateUtils;
use Koha::Libraries;

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

sub tool {
    require Koha::CurbsidePickups;
    require Koha::CurbsidePickupPolicies;
    require Koha::Schema::Result::CurbsidePickupPolicy;
    require Koha::Schema::Result::CurbsidePickup;

    my ( $self, $args ) = @_;

    my $cgi      = $self->{'cgi'};
    my $template = $self->get_template( { file => 'tool.tt' } );

    my $branchcode = C4::Context->userenv->{branch};

    my $action = $cgi->param('action');

    my $CurbsidePickupPolicy = Koha::CurbsidePickupPolicies->find( { branchcode => $branchcode } );
    $template->param( policy => $CurbsidePickupPolicy );

    if ( $action eq 'find-patron' ) {
        my $cardnumber     = $cgi->param('cardnumber');
        my $borrowernumber = $cgi->param('borrowernumber');

        my $patron =
          $cardnumber
          ? Koha::Patrons->find( { cardnumber => $cardnumber } )
          : Koha::Patrons->find($borrowernumber);

        my $existing_curbside_pickups;

        if ( $patron ){
            $existing_curbside_pickups = Koha::CurbsidePickups->search(
                {
                    branchcode                => $branchcode,
                    borrowernumber            => $patron->id,
                    delivered_datetime        => undef,
                    scheduled_pickup_datetime => { '>' => \'DATE(NOW())' },
                }
            );
        } else {
            $template->param( problem => {
                type => 'no_patron_found',
                cardnumber => $cardnumber
            });
        }

        $template->param(
            patron      => $patron,
            tab         => 'schedule-pickup',
            policy_json => to_json( $CurbsidePickupPolicy->TO_JSON ),
            existing_curbside_pickups => $existing_curbside_pickups,
        );
    }
    elsif ( $action eq 'create-pickup' ) {
        my $borrowernumber            = $cgi->param('borrowernumber');
        my $scheduled_pickup_datetime = $cgi->param('pickup_time');
        my $notes                     = $cgi->param('notes');

        my $existing_curbside_pickups = Koha::CurbsidePickups->search(
            {
                branchcode                => $branchcode,
                borrowernumber            => $borrowernumber,
                delivered_datetime        => undef,
                scheduled_pickup_datetime => { '>' => \'DATE(NOW())' },
            }
        )->count();

        if ($existing_curbside_pickups) {
            $template->param(
                problem => {
                    type   => 'too_many_pickups',
                    patron => Koha::Patrons->find($borrowernumber)
                }
            );
        }
        else {
            my $curbside_pickup = Koha::CurbsidePickup->new(
                {
                    branchcode                => $branchcode,
                    borrowernumber            => $borrowernumber,
                    scheduled_pickup_datetime => $scheduled_pickup_datetime,
                    notes                     => $notes,
                }
            )->store();
        }
    }
    elsif ( $action eq 'cancel' ) {
        my $id              = $cgi->param('id');
        my $curbside_pickup = Koha::CurbsidePickups->find($id);
        $curbside_pickup->delete() if $curbside_pickup;
    }
    elsif ( $action eq 'mark-as-staged' ) {
        my $id              = $cgi->param('id');
        my $curbside_pickup = Koha::CurbsidePickups->find($id);
        $curbside_pickup->set(
            {
                staged_datetime  => dt_from_string(),
                staged_by        => C4::Context->userenv->{number},
                arrival_datetime => undef,
            }
        )->store()
          if $curbside_pickup;
    }
    elsif ( $action eq 'mark-as-unstaged' ) {
        my $id              = $cgi->param('id');
        my $curbside_pickup = Koha::CurbsidePickups->find($id);
        $curbside_pickup->set(
            {
                staged_datetime  => undef,
                staged_by        => undef,
                arrival_datetime => undef,
            }
        )->store()
          if $curbside_pickup;
    }
    elsif ( $action eq 'mark-patron-has-arrived' ) {
        my $id              = $cgi->param('id');
        my $curbside_pickup = Koha::CurbsidePickups->find($id);
        $curbside_pickup->set(
            {
                arrival_datetime => dt_from_string(),
            }
        )->store()
          if $curbside_pickup;
    }
    elsif ( $action eq 'mark-as-delivered' ) {
        my $id = $cgi->param('id');

        my $curbside_pickup = Koha::CurbsidePickups->find($id);
        my $patron          = $curbside_pickup->patron;
        my $holds           = $patron->holds;
        foreach my $hold ( $holds->as_list ) {
            my @not_checked_out;
            if ( $hold->found eq 'W' && $hold->branchcode eq $branchcode ) {
                my ( $issuingimpossible, $needsconfirmation ) =
                  CanBookBeIssued( $patron, $hold->item->barcode );

                unless ( keys %$issuingimpossible ) {
                    my $issue = AddIssue( $patron->unblessed, $hold->item->barcode );
                    push( @not_checked_out, $hold ) unless $issue;
                }
            }

            if (@not_checked_out) {
                $template->param(
                    problem => {
                        type   => 'checkout',
                        patron => $patron,
                        holds  => \@not_checked_out
                    }
                );
            }
        }

        $curbside_pickup->set(
            {
                delivered_datetime => dt_from_string(),
                delivered_by       => C4::Context->userenv->{number},
            }
        )->store()
          if $curbside_pickup;
    }

    my $curbside_pickups = Koha::CurbsidePickups->search(
        {
            branchcode                => $branchcode,
            scheduled_pickup_datetime => { '>' => \'DATE(NOW())' },
        },
        {
            order_by => { -asc => 'scheduled_pickup_datetime' }
        }
    );

    $template->param(
        branchcode       => $branchcode,
        curbside_pickups => $curbside_pickups,
        pickups_json     => to_json( $curbside_pickups->TO_JSON ),
        tab              => $cgi->param('tab'),
    );
    $self->output_html( $template->output() );
}

sub opac_js {
    my ($self) = @_;

    return read_file( abs_path( $self->mbf_path('opac.js') ) );
}

sub intranet_js {
    my ($self) = @_;

    return read_file( abs_path( $self->mbf_path('intranet.js') ) );
}

sub configure {
    require Koha::CurbsidePickups;
    require Koha::CurbsidePickupPolicies;
    require Koha::Schema::Result::CurbsidePickupPolicy;
    require Koha::Schema::Result::CurbsidePickup;

    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $libraries =
      Koha::Libraries->search( {}, { order_by => ['branchname'] } );

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        my %policies = map { $_->branchcode => $_ }
          Koha::CurbsidePickupPolicies->search()->as_list;

        $template->param(
            policies  => \%policies,
            libraries => $libraries,
        );

        $self->output_html( $template->output() );
    }
    else {
        foreach my $library ( $libraries->as_list ) {
            my $branchcode = $library->branchcode;

            my $params;

            $params->{branchcode}      = $branchcode;
            $params->{enabled}         = $cgi->param("enable-$branchcode") || 0;
            $params->{pickup_interval} = $cgi->param("interval-$branchcode");
            $params->{patrons_per_interval} =
              $cgi->param("max-per-interval-$branchcode");
            $params->{patron_scheduled_pickup} =
              $cgi->param("patron-scheduled-$branchcode") || 0;

            for my $day (
                qw( sunday monday tuesday wednesday thursday friday saturday ))
            {
                for my $start_end (qw( start end )) {
                    for my $hour_min (qw( hour minute )) {

                        my $value = $cgi->param(
                            "pickup-$start_end-$hour_min-$day-$branchcode");
                        $value = undef if $value eq q{};

                        my $key = $day . '_' . $start_end . '_' . $hour_min;

                        $params->{$key} = $value;
                    }
                }
            }

            my $CurbsidePickupPolicy = Koha::CurbsidePickupPolicies->find(
                { branchcode => $branchcode } );
            $CurbsidePickupPolicy->delete if $CurbsidePickupPolicy;

            Koha::CurbsidePickupPolicy->new($params)->store();
        }
        $self->go_home();
    }
}

sub install() {
    my ( $self, $args ) = @_;

    my $dbh = C4::Context->dbh;

    $dbh->do(
        q{
CREATE TABLE `curbside_pickup_policy` (
  `id` int(11) NOT NULL auto_increment,
  `branchcode` varchar(10) NOT NULL,
  `enabled` INT(1) NOT NULL DEFAULT 0,
  `pickup_interval` INT(2) NOT NULL DEFAULT 0,
  `patrons_per_interval` INT(2) NOT NULL DEFAULT 0,
  `patron_scheduled_pickup` INT(1) NOT NULL DEFAULT 0,
  `sunday_start_hour` INT(2) NULL DEFAULT NULL,
  `sunday_start_minute` INT(2) NULL DEFAULT NULL,
  `sunday_end_hour` INT(2) NULL DEFAULT NULL,
  `sunday_end_minute` INT(2) NULL DEFAULT NULL,
  `monday_start_hour` INT(2) NULL DEFAULT NULL,
  `monday_start_minute` INT(2) NULL DEFAULT NULL,
  `monday_end_hour` INT(2) NULL DEFAULT NULL,
  `monday_end_minute` INT(2) NULL DEFAULT NULL,
  `tuesday_start_hour` INT(2) NULL DEFAULT NULL,
  `tuesday_start_minute` INT(2) NULL DEFAULT NULL,
  `tuesday_end_hour` INT(2) NULL DEFAULT NULL,
  `tuesday_end_minute` INT(2) NULL DEFAULT NULL,
  `wednesday_start_hour` INT(2) NULL DEFAULT NULL,
  `wednesday_start_minute` INT(2) NULL DEFAULT NULL,
  `wednesday_end_hour` INT(2) NULL DEFAULT NULL,
  `wednesday_end_minute` INT(2) NULL DEFAULT NULL,
  `thursday_start_hour` INT(2) NULL DEFAULT NULL,
  `thursday_start_minute` INT(2) NULL DEFAULT NULL,
  `thursday_end_hour` INT(2) NULL DEFAULT NULL,
  `thursday_end_minute` INT(2) NULL DEFAULT NULL,
  `friday_start_hour` INT(2) NULL DEFAULT NULL,
  `friday_start_minute` INT(2) NULL DEFAULT NULL,
  `friday_end_hour` INT(2) NULL DEFAULT NULL,
  `friday_end_minute` INT(2) NULL DEFAULT NULL,
  `saturday_start_hour` INT(2) NULL DEFAULT NULL,
  `saturday_start_minute` INT(2) NULL DEFAULT NULL,
  `saturday_end_hour` INT(2) NULL DEFAULT NULL,
  `saturday_end_minute` INT(2) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`branchcode`),
  FOREIGN KEY (branchcode) REFERENCES branches(branchcode) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    }
    );

    $dbh->do(
        q{
CREATE TABLE `curbside_pickups` (
  `id` int(11) NOT NULL auto_increment,
  `borrowernumber` int(11) NOT NULL,
  `branchcode` varchar(10) NOT NULL,
  `scheduled_pickup_datetime` datetime NOT NULL,
  `staged_datetime` datetime NULL DEFAULT NULL,
  `staged_by` int(11) NULL DEFAULT NULL,
  `arrival_datetime` datetime NULL DEFAULT NULL,
  `delivered_datetime` datetime NULL DEFAULT NULL,
  `delivered_by` int(11) NULL DEFAULT NULL,
  `notes` text NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (branchcode) REFERENCES branches(branchcode) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (borrowernumber) REFERENCES borrowers(borrowernumber) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (staged_by) REFERENCES borrowers(borrowernumber) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	}
    );

    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

sub uninstall() {
    my ( $self, $args ) = @_;

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

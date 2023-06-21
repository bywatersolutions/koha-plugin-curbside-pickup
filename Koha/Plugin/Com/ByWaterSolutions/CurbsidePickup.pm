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

BEGIN {
    my $path = Module::Metadata->find_module_by_name(__PACKAGE__);
    $path =~ s!\.pm$!/lib!;
    unshift @INC, $path;

    require Koha::CurbsidePickupIssues;
    require Koha::CurbsidePickupPolicies;
    require Koha::CurbsidePickups;
    require Koha::Schema::Result::CurbsidePickup;
    require Koha::Schema::Result::CurbsidePickupIssue;
    require Koha::Schema::Result::CurbsidePickupPolicy;

    # register the additional schema classes
    Koha::Schema->register_class(CurbsidePickup => 'Koha::Schema::Result::CurbsidePickup');
    Koha::Schema->register_class(CurbsidePickupPolicy => 'Koha::Schema::Result::CurbsidePickupPolicy');
    Koha::Schema->register_class(CurbsidePickupIssue => 'Koha::Schema::Result::CurbsidePickupIssue');
    # ... and force a refresh of the database handle so that it includes
    # the new classes
    Koha::Database->schema({ new => 1 });
}

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
            $self->_notify_new_pickup($curbside_pickup);
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
                    if ( $issue ) {
                        Koha::CurbsidePickupIssue->new({
                            curbside_pickup_id => $id,
                            issue_id           => $issue->id,
                            reserve_id         => $hold->id,
                        })->store();
                    } else {
                        push( @not_checked_out, $hold );
                    }
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
                arrival_datetime   => $curbside_pickup->arrival_datetime || dt_from_string(),
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

sub _notify_new_pickup {
    my ( $self, $pickup ) = @_;

    my $patron = $pickup->patron;

    # Try to get the borrower's email address
    my $to_address = $patron->notice_email_address;

    my $messagingprefs = C4::Members::Messaging::GetMessagingPreferences(
        {
            borrowernumber => $patron->id,
            message_name   => 'Hold_Filled'
        }
    );

    my $library = $pickup->library->unblessed;

    my $admin_email_address = $library->{branchemail}
      || C4::Context->preference('KohaAdminEmailAddress');

    my %letter_params = (
        module     => 'reserves',
        branchcode => $pickup->branchcode,
        lang       => $patron->lang,
        tables     => {
            'branches'  => $library,
            'borrowers' => $patron->unblessed,
        },
        substitute => {
            curbside_pickup => $pickup,
        }
    );

    my $send_notification = sub {
        my ( $mtt, $letter_code, $patron ) = (@_);
        return unless defined $letter_code;
        $letter_params{letter_code}            = $letter_code;
        $letter_params{message_transport_type} = $mtt;
        my $letter = C4::Letters::GetPreparedLetter(%letter_params);
        unless ($letter) {
            warn "Could not find a letter called '$letter_params{'letter_code'}' for $mtt in the 'Holds (reserves)' module";
            return;
        }

        C4::Letters::EnqueueLetter(
            {
                letter                 => $letter,
                borrowernumber         => $patron->id,
                from_address           => $admin_email_address,
                message_transport_type => $mtt,
            }
        );
    };

    while ( my ( $mtt, $letter_code ) =
        each %{ $messagingprefs->{transports} } )
    {
        warn "Curbside Pickup Plugin: borrowernumber " . $patron->id . "requested a notice by email but does not have an email to send to!"
            if $mtt eq 'email' and not $to_address;

        warn "Curbside Pickup Plugin: borrowernumber " . $patron->id . "requested a notice by SMS but does not have an SMS number to send to!"
            if $mtt eq 'sms' and not $patron->smsalertnumber;

        warn "Curbside Pickup Plugin: borrowernumber " . $patron->id . "requested a notice by phone but does not have an phone number to send to!"
            if $mtt eq 'phone' and not $patron->phone;

        next
          if (
            ( $mtt eq 'email' and not $to_address )    # No email address
            or ( $mtt eq 'sms' and not $patron->smsalertnumber ) # No SMS number
            or ( $mtt eq 'phone' and not $patron->phone )    # No phone number
          );

        $send_notification->( $mtt, 'CURBSIDE', $patron );
    }
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
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $libraries =
      Koha::Libraries->search( {}, { order_by => ['branchname'] } );

    unless ( $cgi->param('save') ) {

        my $dir = $self->bundle_path.'/i18n';
        opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
        my @files = grep { /^[^.]/ && -f "$dir/$_" } readdir($dh);
        closedir $dh;

        my @tokens;
        foreach my $file (@files) {
            my @splitted = split(/\./, $file, -1);
            my $lang = $splitted[0];
            push @tokens, {key => $lang, text => decode("UTF-8", $self->mbf_read('i18n/'.$file))};
        }

        my $template = $self->get_template( { file => 'configure.tt' } );

        my %policies = map { $_->branchcode => $_ }
          Koha::CurbsidePickupPolicies->search()->as_list;

        $template->param(
            policies  => \%policies,
            libraries => $libraries,
            tokens => \@tokens,
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

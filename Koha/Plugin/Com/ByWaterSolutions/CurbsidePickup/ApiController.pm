package Koha::Plugin::Com::ByWaterSolutions::CurbsidePickup::ApiController;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';

use Koha::CurbsidePickupPolicies;
use Koha::CurbsidePickups;
use Koha::DateUtils qw(dt_from_string);
use Koha::Libraries;

use Try::Tiny qw(catch try);

=head1 API

=head2 Class Methods

=head3 pickups

Returns existing future pickups for the given patron

=cut

sub pickups {
    my $c = shift->openapi->valid_input or return;

    my $patron_id = $c->param('patron_id');

    my $patron = Koha::Patrons->find($patron_id);
    return $c->render_resource_not_found('Patron')
        unless $patron;

    my $curbside_pickups = $patron->curbside_pickups->search(
        {
            scheduled_pickup_datetime => { '>' => \'DATE(NOW())' },
        },
        { order_by => { -asc => 'scheduled_pickup_datetime' } }
    );

    my @data;
    foreach my $cp ( $curbside_pickups->as_list ) {
        my $data = $cp->unblessed;
        $data->{branchname} = $cp->library->branchname;

        push( @data, $data );
    }

    return $c->render( status => 200, openapi => \@data );
}

=head3 create_pickup

Creates and returns a new pickup for the given patron

=cut

sub create_pickup {
    my $c = shift->openapi->valid_input or return;

    my $patron_id = $c->param('patron_id');

    my $patron = Koha::Patrons->find($patron_id);
    return $c->render_resource_not_found('Patron')
        unless $patron;

    return try {
        my $body       = $c->req->json;
        my $library_id = $body->{library_id};
        my $notes      = $body->{notes};

        my $existing_curbside_pickups = $patron->curbside_pickups->search(
            {
                branchcode                => $library_id,
                delivered_datetime        => undef,
                scheduled_pickup_datetime => { '>' => \'DATE(NOW())' },
            }
        )->count();

        if ($existing_curbside_pickups) {
            return $c->render(
                status  => 403,
                openapi => { error => "Patron already has a pickup scheduled for this library." }
            );
        } else {
            my $pickup_datetime = dt_from_string( $body->{pickup_datetime} );

            my $pickup = Koha::CurbsidePickup->new(
                {
                    borrowernumber            => $patron_id,
                    branchcode                => $library_id,
                    scheduled_pickup_datetime => $pickup_datetime,
                    notes                     => $notes
                }
            )->store();

            $pickup->notify_new_pickup();

            return $c->render( status => 200, openapi => $c->object->to_api($pickup) );
        }
    } catch {
        $c->unhandled_exception();
    };
}

=head3 delete_pickup

Creates and returns a new pickup for the given patron

=cut

sub delete_pickup {
    my $c = shift->openapi->valid_input or return;

    my $patron_id = $c->param('patron_id');
    my $pickup_id = $c->param('curbside_pickup_id');

    return try {
        my $patron = Koha::Patrons->find($patron_id);
        return $c->render_resource_not_found('Patron')
            unless $patron;

        my $pickup = $patron->curbside_pickups->find($pickup_id);
        return $c->render_resource_not_found('Curbside pickup')
            unless $pickup;

        $pickup->delete();

        return $c->render_resource_deleted();
    } catch {
        $c->unhandled_exception();
    };
}

=head3 all_pickups

Returns all existing scheduled curbside pickups

=cut

sub all_pickups {
    my $c = shift->openapi->valid_input or return;

    return try {
        my $curbside_pickups = Koha::CurbsidePickups->search(
            {
                scheduled_pickup_datetime => { '>' => \'DATE(NOW())' },
            },
            { order_by => { -asc => 'scheduled_pickup_datetime' } }
        );

        my @data;
        foreach my $cp ( $curbside_pickups->as_list ) {
            my $data = $cp->unblessed;

            delete $data->{borrowernumber};
            delete $data->{delivered_by};
            delete $data->{staged_by};
            delete $data->{notes};

            push( @data, $data );
        }

        return $c->render( status => 200, openapi => \@data );
    } catch {
        $c->unhandled_exception();
    };
}

=head3 all_policies

Returns all library pickup policies

=cut

sub all_policies {
    my $c = shift->openapi->valid_input or return;

    return try {
        my $policies = Koha::CurbsidePickupPolicies->search();

        my @data;
        foreach my $p ( $policies->as_list ) {
            my $data = $p->unblessed;
            $data->{branchname} = $p->library->branchname;
            push( @data, $data );
        }

        return $c->render( status => 200, openapi => \@data );
    } catch {
        $c->unhandled_exception();
    };
}

=head3 mark_arrived

Indicates the patron has arrived for the given curbside pickup appointment

=cut

sub mark_arrived {
    my $c = shift->openapi->valid_input or return;

    my $patron_id = $c->param('patron_id');

    return try {
        my $patron = Koha::Patrons->find($patron_id);
        return $c->render_resource_not_found('Patron')
            unless $patron;

        my $curbside_pickup_id = $c->param('curbside_pickup_id');

        my $pickup = $patron->curbside_pickups->find($curbside_pickup_id);
        return $c->render_resource_not_found('Curbside pickup')
            unless $pickup;

        unless ( $pickup->staged_datetime ) {
            return $c->render(
                status  => 403,
                openapi => { error => "Curbside pickup not ready." }
            );
        }

        if ( $pickup->arrival_datetime ) {
            return $c->render(
                status  => 403,
                openapi => { error => "Curbside pickup already marked as arrived." }
            );
        }

        $pickup->arrival_datetime( dt_from_string() );
        $pickup->store();

        return $c->render( status => 200, openapi => $pickup );
    } catch {
        $c->unhandled_exception();
    };
}

1;

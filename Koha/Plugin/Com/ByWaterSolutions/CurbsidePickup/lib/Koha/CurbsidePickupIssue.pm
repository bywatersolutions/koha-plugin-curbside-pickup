package Koha::CurbsidePickupIssue;

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

use Carp;

use Koha::Database;
use Koha::Checkouts;

use base qw(Koha::Object);

=head1 NAME

Koha::CurbsidePickupIssue - Koha Curbside Pickup Issue Object class

=head1 API

=head2 Class methods

=head3 library

Return the branch associated with this policy

=cut

sub checkout {
    my ( $self ) = @_;

    return Koha::Checkouts->find( $self->issue_id );
}

=head2 Internal methods

=head3 _type

=cut

sub _type {
    return 'CurbsidePickupIssue';
}

1;
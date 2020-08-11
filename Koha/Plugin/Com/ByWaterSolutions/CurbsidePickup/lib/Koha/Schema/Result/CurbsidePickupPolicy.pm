use utf8;
package Koha::Schema::Result::CurbsidePickupPolicy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::CurbsidePickupPolicy

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<curbside_pickup_policy>

=cut

__PACKAGE__->table("curbside_pickup_policy");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 branchcode

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 enabled

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 pickup_interval

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 patrons_per_interval

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 patron_scheduled_pickup

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 sunday_start_hour

  data_type: 'integer'
  is_nullable: 1

=head2 sunday_start_minute

  data_type: 'integer'
  is_nullable: 1

=head2 sunday_end_hour

  data_type: 'integer'
  is_nullable: 1

=head2 sunday_end_minute

  data_type: 'integer'
  is_nullable: 1

=head2 monday_start_hour

  data_type: 'integer'
  is_nullable: 1

=head2 monday_start_minute

  data_type: 'integer'
  is_nullable: 1

=head2 monday_end_hour

  data_type: 'integer'
  is_nullable: 1

=head2 monday_end_minute

  data_type: 'integer'
  is_nullable: 1

=head2 tuesday_start_hour

  data_type: 'integer'
  is_nullable: 1

=head2 tuesday_start_minute

  data_type: 'integer'
  is_nullable: 1

=head2 tuesday_end_hour

  data_type: 'integer'
  is_nullable: 1

=head2 tuesday_end_minute

  data_type: 'integer'
  is_nullable: 1

=head2 wednesday_start_hour

  data_type: 'integer'
  is_nullable: 1

=head2 wednesday_start_minute

  data_type: 'integer'
  is_nullable: 1

=head2 wednesday_end_hour

  data_type: 'integer'
  is_nullable: 1

=head2 wednesday_end_minute

  data_type: 'integer'
  is_nullable: 1

=head2 thursday_start_hour

  data_type: 'integer'
  is_nullable: 1

=head2 thursday_start_minute

  data_type: 'integer'
  is_nullable: 1

=head2 thursday_end_hour

  data_type: 'integer'
  is_nullable: 1

=head2 thursday_end_minute

  data_type: 'integer'
  is_nullable: 1

=head2 friday_start_hour

  data_type: 'integer'
  is_nullable: 1

=head2 friday_start_minute

  data_type: 'integer'
  is_nullable: 1

=head2 friday_end_hour

  data_type: 'integer'
  is_nullable: 1

=head2 friday_end_minute

  data_type: 'integer'
  is_nullable: 1

=head2 saturday_start_hour

  data_type: 'integer'
  is_nullable: 1

=head2 saturday_start_minute

  data_type: 'integer'
  is_nullable: 1

=head2 saturday_end_hour

  data_type: 'integer'
  is_nullable: 1

=head2 saturday_end_minute

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "branchcode",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "enabled",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "pickup_interval",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "patrons_per_interval",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "patron_scheduled_pickup",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "sunday_start_hour",
  { data_type => "integer", is_nullable => 1 },
  "sunday_start_minute",
  { data_type => "integer", is_nullable => 1 },
  "sunday_end_hour",
  { data_type => "integer", is_nullable => 1 },
  "sunday_end_minute",
  { data_type => "integer", is_nullable => 1 },
  "monday_start_hour",
  { data_type => "integer", is_nullable => 1 },
  "monday_start_minute",
  { data_type => "integer", is_nullable => 1 },
  "monday_end_hour",
  { data_type => "integer", is_nullable => 1 },
  "monday_end_minute",
  { data_type => "integer", is_nullable => 1 },
  "tuesday_start_hour",
  { data_type => "integer", is_nullable => 1 },
  "tuesday_start_minute",
  { data_type => "integer", is_nullable => 1 },
  "tuesday_end_hour",
  { data_type => "integer", is_nullable => 1 },
  "tuesday_end_minute",
  { data_type => "integer", is_nullable => 1 },
  "wednesday_start_hour",
  { data_type => "integer", is_nullable => 1 },
  "wednesday_start_minute",
  { data_type => "integer", is_nullable => 1 },
  "wednesday_end_hour",
  { data_type => "integer", is_nullable => 1 },
  "wednesday_end_minute",
  { data_type => "integer", is_nullable => 1 },
  "thursday_start_hour",
  { data_type => "integer", is_nullable => 1 },
  "thursday_start_minute",
  { data_type => "integer", is_nullable => 1 },
  "thursday_end_hour",
  { data_type => "integer", is_nullable => 1 },
  "thursday_end_minute",
  { data_type => "integer", is_nullable => 1 },
  "friday_start_hour",
  { data_type => "integer", is_nullable => 1 },
  "friday_start_minute",
  { data_type => "integer", is_nullable => 1 },
  "friday_end_hour",
  { data_type => "integer", is_nullable => 1 },
  "friday_end_minute",
  { data_type => "integer", is_nullable => 1 },
  "saturday_start_hour",
  { data_type => "integer", is_nullable => 1 },
  "saturday_start_minute",
  { data_type => "integer", is_nullable => 1 },
  "saturday_end_hour",
  { data_type => "integer", is_nullable => 1 },
  "saturday_end_minute",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2020-08-05 13:42:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1tV+lnIXUhTkyG68cvG3YQ

=head2 branchcode

Type: belongs_to

Related object: L<Koha::Schema::Result::Branch>

=cut

__PACKAGE__->belongs_to(
  "branchcode",
  "Koha::Schema::Result::Branch",
  { branchcode => "branchcode" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

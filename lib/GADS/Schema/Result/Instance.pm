use utf8;

package GADS::Schema::Result::Instance;

=head1 NAME

GADS::Schema::Result::Instance

=cut

use strict;
use warnings;

use Log::Report;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<instance>

=cut

__PACKAGE__->table("instance");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 site_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 email_welcome_text

  data_type: 'text'
  is_nullable: 1

=head2 email_welcome_subject

  data_type: 'text'
  is_nullable: 1

=head2 email_delete_text

  data_type: 'text'
  is_nullable: 1

=head2 email_delete_subject

  data_type: 'text'
  is_nullable: 1

=head2 email_reject_text

  data_type: 'text'
  is_nullable: 1

=head2 email_reject_subject

  data_type: 'text'
  is_nullable: 1

=head2 register_text

  data_type: 'text'
  is_nullable: 1

=head2 sort_layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sort_type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 homepage_text

  data_type: 'text'
  is_nullable: 1

=head2 homepage_text2

  data_type: 'text'
  is_nullable: 1

=head2 register_title_help

  data_type: 'text'
  is_nullable: 1

=head2 register_telephone_help

  data_type: 'text'
  is_nullable: 1

=head2 register_email_help

  data_type: 'text'
  is_nullable: 1

=head2 register_organisation_help

  data_type: 'text'
  is_nullable: 1

=head2 register_notes_help

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "site_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "email_welcome_text",
  { data_type => "text", is_nullable => 1 },
  "email_welcome_subject",
  { data_type => "text", is_nullable => 1 },
  "email_delete_text",
  { data_type => "text", is_nullable => 1 },
  "email_delete_subject",
  { data_type => "text", is_nullable => 1 },
  "email_reject_text",
  { data_type => "text", is_nullable => 1 },
  "email_reject_subject",
  { data_type => "text", is_nullable => 1 },
  "register_text",
  { data_type => "text", is_nullable => 1 },
  "sort_layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sort_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "homepage_text",
  { data_type => "text", is_nullable => 1 },
  "homepage_text2",
  { data_type => "text", is_nullable => 1 },
  "register_title_help",
  { data_type => "text", is_nullable => 1 },
  "register_telephone_help",
  { data_type => "text", is_nullable => 1 },
  "register_email_help",
  { data_type => "text", is_nullable => 1 },
  "register_organisation_help",
  { data_type => "text", is_nullable => 1 },
  "register_notes_help",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 currents

Type: has_many

Related object: L<GADS::Schema::Result::Current>

=cut

__PACKAGE__->has_many(
  "currents",
  "GADS::Schema::Result::Current",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 graphs

Type: has_many

Related object: L<GADS::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
  "graphs",
  "GADS::Schema::Result::Graph",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 layouts

Type: has_many

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->has_many(
  "layouts",
  "GADS::Schema::Result::Layout",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 metric_groups

Type: has_many

Related object: L<GADS::Schema::Result::MetricGroup>

=cut

__PACKAGE__->has_many(
  "metric_groups",
  "GADS::Schema::Result::MetricGroup",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 site

Type: belongs_to

Related object: L<GADS::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "GADS::Schema::Result::Site",
  { id => "site_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 sort_layout

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
  "sort_layout",
  "GADS::Schema::Result::Layout",
  { id => "sort_layout_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 user_lastrecords

Type: has_many

Related object: L<GADS::Schema::Result::UserLastrecord>

=cut

__PACKAGE__->has_many(
  "user_lastrecords",
  "GADS::Schema::Result::UserLastrecord",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 views

Type: has_many

Related object: L<GADS::Schema::Result::View>

=cut

__PACKAGE__->has_many(
  "views",
  "GADS::Schema::Result::View",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub delete
{   my $self = shift;
    $self->result_source->schema->resultset('Layout')->search({
        instance_id => $self->id,
    })->count
        and error __"All fields must be deleted from this table before it can be deleted";
    $self->next::method(@_);
}

1;

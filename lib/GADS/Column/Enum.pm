=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::Column::Enum;

use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef HashRef/;

extends 'GADS::Column';

has enumvals => (
    is => 'rw',
    lazy => 1,
    builder => sub {
        my $self = shift;
        my $enumrs = $self->schema->resultset('Enumval')->search({
            layout_id => $self->id,
            deleted   => 0,
        });
        $enumrs->result_class('DBIx::Class::ResultClass::HashRefInflator');
        my @enumvals = $enumrs->all;
        \@enumvals;
    },
);

# Indexed list of enumvals
has _enumvals_index => (
    is   => 'rw',
    isa  => HashRef,
    lazy => 1,
    builder => sub {
        my $self = shift;
        my %enumvals = map {$_->{id} => $_} @{$self->enumvals};
        \%enumvals;
    },
);

has ordering => (
    is  => 'rw',
    isa => sub {
        !defined $_[0] || $_[0] eq "desc" || $_[0] eq "asc"
            or error "Invalid enum order value: {ordering}", ordering => $_[0];
    }
);

has '+value_field_as_index' => (
    default => 'id',
);

after build_values => sub {
    my ($self, $original) = @_;
    $self->ordering($original->{ordering});
};

after 'write' => sub {
    my $self = shift;

    # Trees are dealt with separately using AJAX calls
    # First insert and update values
    foreach my $en (@{$self->enumvals})
    {
        if ($en->{id})
        {
            my $enumval = $self->schema->resultset('Enumval')->find($en->{id})
                or error __x"Bad ID {id} for multiple select update", id => $en->{id};
            $enumval->update({ value => $en->{value} });
        }
        else {
            my $new = $self->schema->resultset('Enumval')->create({ value => $en->{value}, layout_id => $self->id });
            $en->{id} = $new->id;
        }
    }

    # And set it again, as new values with have their ID now
    $self->enumvals($self->enumvals); # Set this for retrieval in form on error

    # Then delete any that no longer exist
    $self->_delete_unused_nodes;
    my $newitem = { ordering => $self->ordering };
    $self->schema->resultset('Layout')->find($self->id)->update($newitem);
};

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    if (!defined $self->enumval($value)) # unchanged deleted value
    {
        return 0 unless $options{fatal};
        error __x"'{int}' is not a valid enum ID for '{col}'",
            int => $value, col => $self->name;
    }
    1;
}

# Any value is valid for a search, as it can include begins_with etc
sub validate_search {1};

sub cleanup
{   my ($class, $schema, $id) = @_;
    # Rely on tree cleanup instead. If we have our own here, then
    # it may error for tree types if the rows reference parents.
};

sub enumval
{   my ($self, $id) = @_;
    return unless $id;
    $self->_enumvals_index->{$id};
}

sub random
{   my $self = shift;
    my %hash = %{$self->_enumvals_index};
    return unless %hash;
    $hash{(keys %hash)[rand keys %hash]}->{value};
}

sub enumvals_from_form
{   my ($self, $original) = @_;

    sub collectenum
    {
        my ($value, $id) = @_;
        error __x"'{value}' is not a valid value for the multiple select", value => $value
            unless $value =~ /^[ \S]+$/;
        {
            id    => $id,
            value => $value,
        };
    };

    # Collect all the enum values. These can be in a variety of formats. New
    # ones will be a scalar for a single one or an arrayref for multiples.
    # Existing ones will have a unique field ID. This is maintained to retain
    # the data associated with that entry.
    my @enumvals;
    foreach my $v (keys %$original)
    {
        next unless $v =~ /^enumval(\d*)/;
        if (ref $original->{$v} eq 'ARRAY')
        {
            foreach my $w (@{$original->{$v}})
            {
                my $e = collectenum($w, 0);
                push @enumvals, $e if $e;
            }
        }
        else {
            my $e = collectenum($original->{$v}, $1);
            push @enumvals, $e if $e;
        }
    }

    $self->enumvals(\@enumvals);
}
   
sub _delete_unused_nodes
{   my $self = shift;

    my @all = $self->schema->resultset('Enumval')->search({
        layout_id => $self->id,
    })->all;

    foreach my $node (@all)
    {
        next if $node->deleted; # Already deleted
        unless (grep {$node->id == $_->{id}} @{$self->enumvals})
        {
            my $count = $self->schema->resultset('Enum')->search({
                layout_id => $self->id,
                value     => $node->id
            })->count; # In use somewhere
            if ($count)
            {
                $node->update({ deleted => 1 });
            }
            else {
                $node->delete;
            }
        }
    }
}

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('Enumval')->search({
        layout_id => $self->id,
        deleted   => 0,
    });
}

1;


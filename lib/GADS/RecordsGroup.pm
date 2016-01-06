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

package GADS::RecordsGroup;

use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

extends 'GADS::Records';

has group_by => (
    is     => 'rw',
    isa    => ArrayRef,
    coerce => sub {
        ref $_[0] eq 'ARRAY' ? $_[0] : [$_[0]];
    },
);

# Whether to force a particular column ID to MAX aggregate. Used when the
# normal aggregate operator is a SUM, to get the y-axis grouping value, which
# might be a text field.
has col_max => (
    is  => 'rw',
    isa => Maybe[Int],
);

# Whether to apply the aggregate operator to all selected fields. Normally the
# MAX operator will be used as a default, so as to select text fields
# correctly.
has aggregate_all => (
    is  => 'rw',
    isa => Bool,
);

# The aggregate operator to use
has operator => (
    is  => 'rw',
    isa => Str,
);

# The main column to perform the aggregation on (y-axis). Will be undef for a
# multiple-column x-axis, as each x-axis value's column will be used for the
# y-axis.  In this case, the operator will be used on all selected columns. Set
# via column_id.
has column => (
    is  => 'lazy',
);

# See above
has column_id => (
    is  => 'rw',
    isa => Int,
);

# The following dr_* properties specify whether to select values across a
# daterange, interpolating as required
has dr_column => (
    is  => 'rw',
    isa => Maybe[Int],
);

has dr_interval => (
    is  => 'rw',
    isa => Maybe[Str],
);

has dr_from => (
    is  => 'rwp',
    isa => DateAndTime,
);

has dr_to => (
    is  => 'rwp',
    isa => DateAndTime,
);

sub _build_column
{   my $self = shift;
    $self->layout->column($self->column_id);
}

sub search
{   shift->_search_group;
}

sub _search_group
{   my ($self, %options) = @_;

    my $prefetches  = $self->prefetches;
    my $joins       = $self->joins;
    my @group_by    = @{$self->group_by};

    $self->construct_search(%options);

    # Work out the field name to select, and the appropriate aggregate function
    my @select_fields;
    foreach (@{$self->columns_retrieved_do})
    {
        my $op = $self->col_max && $self->col_max == $_->id
               ? 'max'
               : $self->aggregate_all
               ? $self->operator
               : 'max';
        # Don't use SUM() for non-numeric columns
        $op = 'max' if $op eq 'sum' && !$_->numeric;
        push @select_fields, {
            $op => $self->_fqvalue($_),
            -as => $_->field
        };
        # Also add linked column if required
        push @select_fields, {
            $op => $self->_fqvalue($_->link_parent),
            -as => $_->field."_link",
        } if $_->link_parent;
    };

    push @select_fields, {
        $self->operator => $self->_fqvalue($self->column),
        -as             => $self->column->field."_".$self->{operator},
    } if $self->column;

    push @select_fields, {
        $self->operator => $self->_fqvalue($self->column->link_parent),
        -as             => $self->column->field."_".$self->{operator}."_link",
    } if $self->column && $self->column->link_parent;

    # If we want to aggregate by month, we need to do some tricky conditional
    # summing. We can't do this with the abstraction layer, so need to resort
    # to literal SQL
    if ($self->dr_column)
    {
        my $increment  = $self->dr_interval.'s'; # Increment between x-axis values
        my $dr_col     = $self->layout->column($self->dr_column); # The daterange column for x-axis
        my $field      = $dr_col->field;
        my $field_link = $dr_col->link_parent && $dr_col->link_parent->field; # Related link field

        # First find out earliest and latest date in this result set
        my $select = [
            { min => "$field.from", -as => 'start_date'},
            { max => "$field.to", -as => 'end_date'},
        ];
        # Include linked field if applicable
        push @$select, (
            { min => "$field_link.from", -as => 'start_date_link'},
            { max => "$field_link.to", -as => 'end_date_link'},
        ) if $field_link;

        my ($result) = $self->schema->resultset('Current')->search(
            [-and => $self->search_query], {
                select => $select,
                join   => [
                    {
                        'record' => [@$prefetches, @$joins],
                    },
                    $self->linked_hash,
                ],
            },
        )->all;

        my $dt_parser = $self->schema->storage->datetime_parser;
        # Find min/max dates from above, including linked field if required
        my $daterange_from = $self->_min_date(
            $result->get_column('start_date'),
            ($field_link ? $result->get_column('start_date_link') : undef)
        );
        my $daterange_to   = $self->_max_date(
            $result->get_column('end_date'),
            ($field_link ? $result->get_column('end_date_link') : undef)
        );
        $daterange_from->truncate(to => 'month');
        $daterange_to->truncate(to => 'month');
        # Pass dates back to caller
        $self->_set_dr_from($daterange_from);
        $self->_set_dr_to  ($daterange_to);

        # The literal CASE statement, which we reuse for each required period
        my $from_field   = $self->schema->storage->dbh->quote_identifier('from');
        my $to_field     = $self->schema->storage->dbh->quote_identifier('to');
        my $col_val      = $self->_fqvalue($self->column);
        my $col_val_link = $self->column->link_parent && $self->_fqvalue($self->column->link_parent);

        my $case = $field_link
            ? "CASE WHEN "
              . "($field.$from_field < %s OR $field_link.$from_field < %s) "
              . "AND ($field.$to_field >= %s OR $field_link.$to_field >= %s) "
              . "THEN %s ELSE 0 END"
            : "CASE WHEN $field.$from_field"
              . " < %s AND $field.$to_field"
              . " >= %s THEN %s ELSE 0 END";

        my $pointer = $daterange_from->clone;
        while ($pointer->epoch <= $daterange_to->epoch)
        {
            # Add the required timespan to the CASE statement
            my $from  = $self->schema->storage->dbh->quote(
                $dt_parser->format_date($pointer->clone->add($increment => 1))
            );
            my $to    = $self->schema->storage->dbh->quote(
                $dt_parser->format_date($pointer)
            );
            my $sum   = $self->operator eq 'count' ? 1 : $col_val;
            my $casef = $field_link
                      ? sprintf($case, $from, $from, $to, $to, $sum)
                      : sprintf($case, $from, $to, $sum);
            # Finally add it to the select, naming it after the epoch of
            # the time-period start
            push @select_fields, {
                sum => \$casef,
                -as => $pointer->epoch,
            };
            # Also add link parent field as well if required
            if ($self->column->link_parent)
            {
                my $sum   = $self->operator eq 'count' ? 1 : $col_val_link;
                my $casef = $field_link
                          ? sprintf($case, $from, $from, $to, $to, $sum)
                          : sprintf($case, $from, $to, $sum);
                push @select_fields, {
                    sum => \$casef,
                    -as => $pointer->epoch."_link",
                };
            }
            $pointer->add($increment => 1);
        }
    }

    my @g;
    # Add on the actual columns to group by in the SQL statement
    foreach (@group_by)
    {
        my $col = $self->layout->column($_->{id});
        # Whether we need to pluck a particular date value, used to group the
        # x-axis to days, months etc.
        if (my $pluck = $_->{pluck}) {

            push @g, $self->schema->resultset('Current')->dt_SQL_pluck(
                { -ident => $self->_fqvalue($col) }, 'year'
            );

            push @g, $self->schema->resultset('Current')->dt_SQL_pluck(
                { -ident => $self->_fqvalue($col) }, 'month'
            ) if $pluck eq 'month' || $pluck eq 'day';

            push @g, $self->schema->resultset('Current')->dt_SQL_pluck(
                { -ident => $self->_fqvalue($col) }, 'day_of_month'
            ) if $pluck eq 'day';

        } else {
            push @g, $self->_fqvalue($col);
        }
    };
    my $select = {
        select => [@select_fields],
        join     => [
            {
                'record' => [@$prefetches, @$joins],
            },
            $self->linked_hash,
        ],
        group_by => [@g],
    };

    my $result = $self->schema->resultset('Current')->search(
        [-and => $self->search_query], $select
    );

    $self->results([$result->all]);
}

sub _min_date { shift->_min_max_date('min', @_) };
sub _max_date { shift->_min_max_date('max', @_) };

sub _min_max_date
{   my ($self, $action, $date1, $date2) = @_;
    my $dt_parser = $self->schema->storage->datetime_parser;
    my $d1 = $date1 && $dt_parser->parse_date($date1);
    my $d2 = $date2 && $dt_parser->parse_date($date2);
    return $d1 if !$d2;
    return $d2 if !$d1;
    if ($action eq 'min') {
        return $d1 if $d1->epoch < $d2->epoch;
    } else {
        return $d1 if $d1->epoch > $d2->epoch;
    }
    return $d2;
}

1;


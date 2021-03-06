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

package GADS::Datum::Daterange;

use DateTime;
use DateTime::Span;
use GADS::SchemaInstance;
use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum';

has schema => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        GADS::SchemaInstance->instance;
    },
);

# Set datum value with value from user
has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;

        $self->oldvalue($self->clone);
        my $newvalue = $self->_parse_dt($value, 'user');
        my $from_old = $self->oldvalue && $self->oldvalue->value ? $self->oldvalue->value->start->epoch : 0;
        my $to_old   = $self->oldvalue && $self->oldvalue->value ? $self->oldvalue->value->end->epoch   : 0;
        my $from_new = $newvalue ? $newvalue->start->epoch : 0;
        my $to_new   = $newvalue ? $newvalue->end->epoch   : 0;
        $self->changed(1) if $from_old != $from_new || $to_old != $to_new;
        $self->value($newvalue);
    }
);

has value => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $value = $self->init_value;
        my $v = $self->_parse_dt($value, 'db');
        $self->has_value(1) if defined $value || $self->init_no_value;
        $self->value($v);
    },
);

around blank => sub {
    my ($orig, $self) = @_;
    $self->from_dt && $self->to_dt ? 0 : 1;
};

# Can't use predicate, as value may not have been built on
# second time it's set
has has_value => (
    is => 'rw',
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->(
        $self,
        value           => $self->value,
        schema          => $self->schema,
    );
};

sub from_form
{   my $self = shift;
    $self->value && $self->value->start->format_cldr($self->column->dateformat);
}

sub to_form
{   my $self = shift;
    $self->value && $self->value->end->format_cldr($self->column->dateformat);
}

sub from_dt
{   my $self = shift;
    $self->value && $self->value->start;
}

sub to_dt
{   my $self = shift;
    $self->value && $self->value->end;
}

sub _parse_dt
{   my ($self, $original, $source) = @_;

    $original or return;

    # Array ref will be received from form
    if (ref $original eq 'ARRAY')
    {
        $original = {
            from => $original->[0],
            to   => $original->[1],
        };
    }
    # Otherwise assume it's a hashref: { from => .., to => .. }

    return
        if !$original->{from} && !$original->{to};

    my ($from, $to);
    if ($source eq 'db')
    {
        my $db_parser = $self->schema->storage->datetime_parser;
        $from = $db_parser->parse_date($original->{from});
        $to   = $db_parser->parse_date($original->{to});
    }
    else { # Assume 'user'
        $self->column->validate($original, fatal => 1);
        $from = $self->column->parse_date($original->{from});
        $to   = $self->column->parse_date($original->{to});
    }

    DateTime::Span->from_datetimes(start => $from, end => $to);
}

# XXX Why is this needed? Error when creating new record otherwise
sub as_integer
{   my $self = shift;
    $self->value; # Force update of values
    $self->value && $self->value->start ? $self->value->start->epoch : 0;
}

sub as_string
{   my $self = shift;
    $self->value; # Force update of values
    $self->_as_string($self->value);
}

sub _as_string
{   my ($self, $range) = @_;
    return "" unless $range;
    return "" unless $range->start && $range->end;
    my $format = $self->column->dateformat;
    $range->start->format_cldr($format) . " to " . $range->end->format_cldr($format);
}

1;


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

package GADS::Datum::File;

use Moo;
use namespace::clean;

use overload '""' => \&as_string;

extends 'GADS::Datum';

has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;
        my $first_time = 1 unless $self->has_id;
        my $new_id;
        $value = $value->{value} if ref $value && ref $value->{value};
        if (ref $value && $value->{content})
        {
            # New file uploaded
            $new_id = $self->schema->resultset('Fileval')->create({
                name     => $value->{name},
                mimetype => $value->{mimetype},
                content  => $value->{content},
            })->id;
            $self->name($value->{name});
            $self->mimetype($value->{mimetype});
        }
        elsif(ref $value) {
            $new_id = $value->{id};
            $self->name($value->{name});
            $self->mimetype($value->{mimetype});
        }
        else {
            # Just ID for file passed. Probably a resubmission
            # of a form with previous errors
            $new_id = $value;
        }
        unless ($first_time)
        {
            # Previous value
            $self->changed(1) if (!defined($self->id) && defined $value)
                || (!defined($value) && defined $self->id)
                || (defined $self->id && defined $value && $self->id != $value);
            $self->oldvalue($self->id);
        }
        $self->id($new_id);
    },
);

has id => (
    is        => 'rw',
    predicate => 1,
    trigger   => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
);

has name => (
    is => 'rw',
);

has mimetype => (
    is => 'rw',
);

has schema => (
    is => 'rw',
);

has content => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->schema->resultset('Fileval')->find($self->id)->content;
    },
);

sub as_string
{   my $self = shift;
    $self->name // "";
}

sub html
{   my $self = shift;
    return "" unless $self->id;
    my $id = $self->id;
    my $name = $self->name || "";
    return qq(<a href="/file/$id">$name</a>);
}

1;

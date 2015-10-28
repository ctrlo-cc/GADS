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

package GADS::Records;

use Data::Compare;
use DateTime;
use DateTime::Format::Strptime qw( );
use DBIx::Class::ResultClass::HashRefInflator;
use GADS::Record;
use GADS::View;
use HTML::Entities;
use JSON qw(decode_json encode_json);
use Log::Report;
use POSIX qw(ceil);
use Safe;
use Scalar::Util qw(looks_like_number);
use Text::CSV::Encoded;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

# Preferably this is passed in to prevent extra
# DB reads, but loads it if it isn't
has layout => (
    is       => 'rw',
    required => 1,
);

has user => (
    is       => 'ro',
    required => 1,
);

has pages => (
    is => 'rw',
);

has view => (
    is => 'rw',
);

# Whether to limit any results to only those
# in a specific view
has limit_to_view => (
    is => 'lazy',
);

sub _build_limit_to_view
{   my $self = shift;
    my $limit_to_view = $self->user && $self->user->{limit_to_view} or return;
    GADS::View->new(
        user        => undef, # In case user does not have access
        id          => $limit_to_view,
        schema      => $self->schema,
        layout      => $self->layout,
        instance_id => $self->layout->instance_id,
    );
}

has from => (
    is => 'rw',
);

has to => (
    is => 'rw',
);

# Whether to force recalculation of cached fields
has force_update => (
    is => 'rw',
);

has remembered_only => (
    is => 'rw',
);

# Array ref with column IDs
has columns => (
    is => 'rw',
);

# Array ref with any additional column IDs requested
has columns_extra => (
    is => 'rw',
);

# Value containing the actual columns retrieved
has columns_retrieved => (
    is => 'rw',
);

has rows => (
    is => 'rw',
);

has page => (
    is => 'rw',
);

has include_approval => (
    is      => 'rw',
    default => 0,
);

# Whether to prefetch related records along with the main resultset
has prefetch_related => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has retrieve_related => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has prefetches => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has joins => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

# Same as prefetches, but linked fields
has linked_prefetches => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has linked_joins => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has plus_select => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has order_by => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has order_by_count => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

sub order_by_inc
{   my $self = shift;
    $self->order_by_count($self->order_by_count + 1);
}

has sort => (
    is     => 'rw',
    isa    => Maybe[ArrayRef],
    coerce => sub {
        return unless $_[0];
        # Allow single sorts, or several in an array
        ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ],
    },
);

has schema => (
    is       => 'rw',
    required => 1,
);

has format => (
    is => 'rw',
);

has default_sort => (
    is => 'rw',
);

has results => (
    is => 'rw',
);

sub _search_construct;

sub _default_sort
{   my ($self, $col_id, $type) = @_;

    if ($col_id)
    {
        my $column = $self->layout->column($col_id);
        { $type => $column };
    }
    else {
        { -asc => 'id' };
    }
}

sub _add_jp
{   my ($self, $toadd, $type) = @_;

    my $prefetches        = $self->prefetches;
    my $joins             = $self->joins;
    my $linked_prefetches = $self->linked_prefetches;
    my $linked_joins      = $self->linked_joins;

    # Process a join, prefetch or linked field. We see if we've already done it
    # first before adding. If the join criteria is a hash (ie joining a field
    # and then a value table), then we count the number of value joins, as
    # these will subsequently be labelled _2 etc. In this case, we return index
    # number.
    my %found; my $key;
    ($key) = keys %$toadd if ref $toadd eq 'HASH';
    foreach my $j (@$joins, @$prefetches, @$linked_joins, @$linked_prefetches)
    {
        if ($key && ref $j eq 'HASH')
        {
            $found{$key}++;
            return $found{$key} if Compare $toadd, $j;
        }
        elsif ($toadd eq $j)
        {
            return 1;
        }
    }

    if ($type eq 'join')
    {
        push @$joins, $toadd;
    }
    elsif ($type eq 'prefetch')
    {
        push @$prefetches, $toadd;
    }
    elsif ($type eq 'linked_join')
    {
        push @$linked_joins, $toadd;
    }
    elsif ($type eq 'linked_prefetch')
    {
        push @$linked_prefetches, $toadd;
    }
    $found{$key}++ if $key;
    return $key ? $found{$key} : 1;
}

sub _add_prefetch
{   my $self = shift;
    $self->_add_jp(@_, 'prefetch');
}

sub _add_join
{   my $self = shift;
    $self->_add_jp(@_, 'join');
}

sub _add_linked_prefetch
{   my $self = shift;
    $self->_add_jp(@_, 'linked_prefetch');
}

sub _add_linked_join
{   my $self = shift;
    $self->_add_jp(@_, 'linked_join');
}

# Shortcut to generate the required joining hash for a DBIC search
sub linked_hash
{   my $self = shift;
    if (@{$self->linked_prefetches})
    {
        {
            linked => {
                record => $self->linked_prefetches,
            },
        };
    }
    else {
        {
            linked => 'record',
        }
    }
}

# A function to see if any views have a particular record within
sub search_views
{   my ($self, $current_ids, @views) = @_;

    return unless @views && @$current_ids;

    my $columns = $self->layout->all;
    my @search; my $found_in_a_view;

    # XXX This is up for debate. First, do a search with all views in, as it only
    # requires one SQL query (albeit a big one). If none match, happy days.
    # If one does match though, we have to redo all the searches individually
    # to find which one matched. Is this the most efficient way of doing it?
    foreach my $view (@views)
    {
        my $filter  = $view->filter || '{}';
        my $view_id = $view->id;
        trace qq(About to decode filter for view ID $view_id);
        my $decoded = decode_json($filter);
        # XXX Do not send alerts for hidden fields
        if (keys %$decoded)
        {
            my @s = @{$self->_search_construct($decoded, $self->layout, 1)};
            push @search, \@s;
        }
        else {
            # The view has no filter, so it must contain the record.
            # Skip straight to the next step.
            $found_in_a_view = 1;
            last;
        }
    }

    my $joins = $self->joins;

    my $search       = {
        'me.instance_id' => $self->layout->instance_id,
    };
    my $total_count = $self->schema->resultset('Current')->search({
        instance_id => $self->layout->instance_id,
        record_id   => { '!=' => undef } # Not sure why, but some IDs have no record. Bug?
    })->count;
    $search->{'me.id'} = $current_ids unless @$current_ids == $total_count; # Array ref
    $search->{'-or'} = \@search if @search;

    $found_in_a_view ||= $self->schema->resultset('Current')->search($search,{
        join     => {'record' => $joins},
    })->count;

    my @foundin;
    if ($found_in_a_view)
    {
        foreach my $view (@views)
        {
            my $filter  = $view->filter || '{}';
            my $view_id = $view->id;
            trace qq(About to decode filter for view ID $view_id);
            my $decoded = decode_json($filter);
            if (keys %$decoded)
            {
                my @s = @{$self->_search_construct($decoded, $self->layout, 1)};
                my @ids = $self->schema->resultset('Current')->search({
                    'me.id'          => $current_ids, # Array ref
                    'me.instance_id' => $self->layout->instance_id,
                    @s,
                },{
                    join     => {'record' => $joins},
                })->get_column('id')->all;
                push @foundin, {
                    view => $view,
                    ids  => \@ids,
                } if @ids;
            }
            else {
                # No filter, definitely in view
                push @foundin, {
                    view => $view,
                    ids  => $current_ids, # Array ref
                };
            }
        }
    }
    @foundin;
}

sub search_all_fields
{   my ($self, $search) = @_;

    $search or return;

    my %results;

    if ($search =~ s/\*/%/g )
    {
        $search = { like => $search };
    }

    my @fields = (
        { type => 'string', plural => 'strings' },
        { type => 'int'   , plural => 'intgrs' },
        { type => 'date'  , plural => 'dates' },
        { type => 'string', plural => 'dateranges' },
        { type => 'string', plural => 'ragvals' },
        { type => 'string', plural => 'calcvals' },
        { type => 'string', plural => 'enums', sub => 1 },
        { type => 'string', plural => 'people', sub => 1 },
        { type => 'file'  , plural => 'files', sub => 1, value_field => 'name' },
        { type => 'current_id' },
    );

    # Set up a date parser
    my $format = DateTime::Format::Strptime->new(
         pattern   => '%Y-%m-%d',
         time_zone => 'local',
    );

    my @columns_can_view = map {$_->id} $self->layout->all(user_can_read => 1);
    # Applies to all types of fields being searched
    my @basic_search = (
        {
            'me.instance_id' => $self->layout->instance_id,
        },
    );
    # Only search limited view if configured for user
    if (my $view = $self->limit_to_view)
    {
        if (my $filter = $view->filter)
        {
            my $decoded = decode_json($filter);
            if (keys %$decoded)
            {
                push @basic_search, @{$self->_search_construct($decoded, $self->layout)};
            }
        }
    }
    foreach my $field (@fields)
    {
        next if ($field->{type} eq 'int' || $field->{type} eq 'current_id')
            && !looks_like_number $search;
        next if $field->{type} eq 'date' &&  !$format->parse_datetime($search);

        # These aren't really needed for current_id, but no harm
        my $plural      = $field->{plural};
        my $value_field = $field->{value_field} || 'value';
        my $s           = $field->{sub} ? "value.$value_field" : "$plural.$value_field";
        my $prefetch    = $field->{type} eq 'current_id'
                        ? undef
                        : $field->{sub}
                        ? {
                              'record' => 
                                  {
                                      $plural => ['value', 'layout']
                                  },
                          } 
                        : {
                              'record' => { $plural => 'layout' },
                          };

        my @search = @basic_search;
        push @search,
            $field->{type} eq 'current_id' ? { id => $search } : { $s => $search };
        push @search, { 'layout.id' => \@columns_can_view }
            unless $field->{type} eq 'current_id';
        my @currents = $self->schema->resultset('Current')->search({ -and => \@search},{
            join => { record => $self->joins},
            prefetch => $prefetch,
            collapse => 1,
        })->all;

        foreach my $current (@currents)
        {
            my @r;
            if ($field->{type} eq 'current_id')
            {
                push @r, "ID: ".$current->id;
            }
            else {
                foreach my $string ($current->record->$plural)
                {
                    my $v = $field->{sub} ? $string->value->$value_field : $string->value;
                    push @r, $string->layout->name. ": ". $v;
                }
            }
            my $hl = join(', ', @r);
            if ($results{$current->id})
            {
                $results{$current->id}->{results} .= ", $hl";
            }
            else {
                $results{$current->id} = {
                    current_id => $current->id,
                    record_id  => $current->record->id,
                    results    => $hl,
                };
            }
        }
    }

    sort {$a->{current_id} <=> $b->{current_id}} values %results;
}

sub search
{   my ($self, %options) = @_;
    #   push @limit, ("record.record_id" => undef)
    #        unless $approval;
    #}
    #push @limit, (approval => $approval);

    my $prefetches  = $self->prefetches([]);
    my $joins       = $self->joins([]);
    my $current_ids = delete $options{current_ids},
    my $rinfo       = $self->construct_search(%options);
    my @search      = @{$rinfo->{search}};
    my @limit       = @{$rinfo->{limit}};

    my $root_table;
    unless ($self->include_approval)
    {
        push @search, (
            { 'record.approval'  => 0 },
            { 'record.record_id' => undef },
        );
    }
    push @search, { 'me.id'          => $current_ids} if $current_ids;
    push @search, { 'me.instance_id' => $self->layout->instance_id };

    $root_table = 'Current';

    my $search = [-and => [@search, @limit]];

    # XXX Okay, this is a bit weird - we join current to record to current.
    # This is because we return records at the end, and it allows current
    # to be used when the record is used. Is there a better way?
    my $linked  = $self->linked_hash;
    my $current = $root_table eq 'Record' ? { current => $linked } : 'current';
    unshift @$prefetches, ($current, 'createdby', 'approvedby');

    my $currents = $self->prefetch_related ? { currents => {record => $prefetches} } : 'currents';
    my $select = {
        prefetch => $root_table eq 'Record' ? $prefetches : [
            {
                'record' => $prefetches
            },
            $currents,
            $linked,
        ],
        join     => $root_table eq 'Record' ? $joins : [
            {
                'record' => $joins
            },
            $linked,
        ],
        '+select' => $self->plus_select,
        order_by  => $self->order_by,
    };

    # First count all values from result
    my $count = $self->schema->resultset($root_table)->search(
        $search, $select
    )->count;

    # Send page information back
    my $rows = $self->rows;
    $self->pages($rows ? ceil($count / $rows) : 1);

    # Now redo query but with just one page of results
    my $page = $self->page
             ? $self->page > $self->pages
             ? $self->pages
             : $self->page
             : undef;

    $select->{rows} = $rows if $rows;
    $select->{page} = $page if $page;
    my $result = $self->schema->resultset($root_table)->search(
        $search, $select
    );

    $result->result_class('DBIx::Class::ResultClass::HashRefInflator');

    # This messy code is to reorder the results slightly, so that
    # related records appear below their parent record
    my @all_ids;
    my %all; my %is_related;
    foreach my $rec ($result->all)
    {
        push @all_ids, $rec->{id};
        my @related = map { $_->{id} } @{$rec->{currents}};
        map { $is_related{$_} = undef } @related;
        $all{$rec->{id}} = GADS::Record->new(
            schema            => $self->schema,
            record            => $rec->{record},
            linked_record     => $rec->{linked}->{record},
            related_records   => \@related,
            parent_id         => $rec->{parent_id},
            linked_id         => $rec->{linked_id},
            user              => $self->user,
            format            => $self->format,
            layout            => $self->layout,
            force_update      => $self->force_update,
            columns_retrieved => $self->columns_retrieved,
        );
    }

    if ($self->retrieve_related)
    {
        # Now get any related records that weren't picked up the first time.
        # First any children of main records retrieved
        my @need = grep { !exists $all{$_} } keys %is_related;
        # Then any parents of children retrieved
        push @need, grep { $_ && !exists $all{$_} } map { $all{$_}->parent_id } @all_ids;

        if (@need) # Only if any to retrieve
        {
            delete $select->{rows}; # No pagination required - all records please
            delete $select->{page};
            my $additional = $self->schema->resultset($root_table)->search({
                'me.id' => \@need,
            }, $select );

            $additional->result_class('DBIx::Class::ResultClass::HashRefInflator');
            foreach my $rec ($additional->all)
            {
                push @all_ids, $rec->{id};
                my @related = map { $_->{id} } @{$rec->{currents}};
                map { $is_related{$_} = undef } @related;
                $all{$rec->{id}} = GADS::Record->new(
                    schema            => $self->schema,
                    record            => $rec->{record},
                    linked_record     => $rec->{linked}->{record},
                    related_records   => \@related,
                    parent_id         => $rec->{parent_id},
                    linked_id         => $rec->{linked_id},
                    user              => $self->user,
                    format            => $self->format,
                    layout            => $self->layout,
                    force_update      => $self->force_update,
                    columns_retrieved => $self->columns_retrieved,
                );
            }
        }
    }

    my @all; my %done;
    foreach my $rec_id (@all_ids)
    {
        next unless $all{$rec_id};
        unless (exists $is_related{$rec_id} || exists $done{$rec_id})
        {
            push @all, $all{$rec_id};
            $done{$rec_id} = undef;
        }
        foreach (@{$all{$rec_id}->related_records})
        {
            next if exists $done{$_} || !$all{$_};
            foreach my $col (@{$self->columns_retrieved})
            {
                $all{$_}->fields->{$col->id} //= $all{$rec_id}->fields->{$col->id};
            }
            push @all, $all{$_};
            $done{$_} = undef;
        }
    }

    $self->results(\@all);
}

sub construct_search
{   my ($self, %options) = @_;

    foreach my $option (keys %options)
    {
        $self->$option($options{$option});
    }
    undef %options;

    my $layout = $self->layout;

    # First, add all the columns in the view as a prefetch. During
    # this stage, we keep track of what we've added, so that we
    # can act accordingly during the filters
    my @columns;
    if ($self->columns)
    {
        my @col_ids = grep {defined $_} @{$self->columns}; # Remove undef column IDs
        my %col_ids;
        @col_ids{@col_ids} = undef;
        @columns = grep { exists $col_ids{$_->id} } $layout->all(order_dependencies => 1);
    }
    elsif (my $view = $self->view)
    {
        @columns = $layout->view(
            $view->id,
            order_dependencies => 1,
            user_can_read      => 1,
            columns_extra      => $self->columns_extra,
        );
    }
    else {
        @columns = $layout->all(
            remembered_only    => $self->remembered_only,
            order_dependencies => 1,
        );
    }
    $self->columns_retrieved(\@columns);

    my %cache_cols;                     # Any column in the view that should be cached
    my $prefetches = $self->prefetches; # Tables to prefetch - data being viewed
    my $joins      = $self->joins;      # Tables to join - data being searched
    my $cache_joins;                    # Tables that have data needed for calculated fields
    my @search_date;                    # The search criteria to narrow-down by date range
    foreach my $c (@columns)
    {
        if ($c->type eq "date" || $c->type eq "daterange")
        {
            # Apply any date filters if required
            my @f;
            if (my $to = $self->to)
            {
                my $f = {
                    id       => $c->id,
                    operator => 'less',
                    value    => $to->ymd,
                };
                push @f, $f;
            }
            if (my $from = $self->from)
            {
                my $f = {
                    id       => $c->id,
                    operator => 'greater',
                    value    => $from->ymd,
                };
                push @f, $f;
            }
            push @search_date, {
                condition => "AND",
                rules     => \@f,
            } if @f;
        }
        # Flag cache if need be - may need updating
        $cache_cols{$c->field} = $c
            if $c->hascache;
        # We're viewing this, so prefetch all the values
        $self->_add_prefetch($c->join);
        $self->_add_linked_prefetch($c->link_parent->join) if $c->link_parent;
    }

    my @limit; # The overall limit, for example reduction by date range or approval field
    # Add any date ranges to the search from above
    if (@search_date)
    {
        # _search_construct returns an array ref, so dereference it first
        my @res = @{($self->_search_construct({condition => 'OR', rules => \@search_date}, $layout))};
        push @limit, @res if @res;
    }

    # Now add all the filters as joins (we don't need to prefetch this data). However,
    # the filter might also be a column in the view from before, in which case add
    # it to, or use, the prefetch. We use the tracking variables from above.
    my @calcsearch; # The search for fields that may need to be recalculated
    my @search;     # The user search
    if (my $view = $self->view)
    {
        if (my $filter = $view->filter)
        {
            my $decoded = decode_json($filter);
            # Do 2 loops through all the filters and gather the joins. The reason is that
            # any extra joins will be added *before* the prefetches, thereby making the
            # prefetch join numbers unpredictable. By doing an initial run, when we
            # repeat we will have predictable join numbers.
            if (keys %$decoded)
            {
                $self->_search_construct($decoded, $layout);
                # Get the user search criteria
                @search     = @{$self->_search_construct($decoded, $layout)};
                # Put together the search to look for undefined calculated fields
                @calcsearch = @{$self->_search_construct($decoded, $layout, \%cache_cols)};
            }
        }
        unless ($self->sort)
        {
            foreach my $sort (@{$view->sorts})
            {
                if (my $col_id = $sort->{layout_id})
                {
                    my $column  = $layout->column($col_id);
                    my $type    = $sort->{type} eq 'desc' ? '-desc' : '-asc';
                    $self->add_sort($column, $type);
                }
                else {
                    # No column defined means sort by ID
                    my $type = $sort->{type} eq 'desc' ? '-desc' : '-asc';
                    push @{$self->order_by}, { $type => 'me.id' };
                }
                # Add the first sort column to the object for retrieval later
                $self->sort({
                    id   => $sort->{layout_id},
                    type => $sort->{type},
                }) unless $self->sort;
            }
        }
    }
    if (my $view = $self->limit_to_view)
    {
        if (my $filter = $view->filter)
        {
            my $decoded = decode_json($filter);
            # Do 2 loops through all the filters and gather the joins. The reason is that
            # any extra joins will be added *before* the prefetches, thereby making the
            # prefetch join numbers unpredictable. By doing an initial run, when we
            # repeat we will have predictable join numbers.
            if (keys %$decoded)
            {
                $self->_search_construct($decoded, $layout);
                # Get the user search criteria
                push @search, @{$self->_search_construct($decoded, $layout)};
            }
        }
    }
    # Configure specific user selected sort, if applicable. This needs to be done
    # after the filters have been added, otherwise the filters could add additonal
    # joins which will put the value_x columns out of kilter. A user selected
    # column will always be in a prefetch, so it's not possible for the reverse
    # to happen
    if (my $sort = $self->sort)
    {
        my @sorts;
        foreach my $s (@$sort)
        {
            my $type = $s->{type} && $s->{type} eq 'desc' ? '-desc' : '-asc';
            if (!$s->{id})
            {
                push @{$self->order_by}, { $type => 'me.id' };
            }
            elsif (my $column = $layout->column($s->{id}))
            {
                $self->add_sort($column, $type);
            }
        }
    }
    # Default sort
    unless (@{$self->order_by})
    {
        my $default_sort = $self->default_sort;
        my $type         = $default_sort->{type} && $default_sort->{type} eq 'desc' ? 'desc' : 'asc';
        if (my $col_id = $default_sort->{id})
        {
            my $col     = $self->layout->column($col_id);
            $self->add_sort($col, "-$type");
            $self->sort({
                id   => $col_id,
                type => $type,
            });
        }
        else {
            push @{$self->order_by}, { "-$type" => 'me.id' };
            $self->sort({
                type => $type,
            });
        }
    }

    {
        search     => \@search,
        limit      => \@limit,
    }
}

sub _table_name
{   my ($self, $column) = @_;
    my $jn = $self->_add_join ($column->join);
    my $index = $jn > 1 ? "_$jn" : '';
    $column->sprefix . $index;
}

sub _table_name_linked
{   my ($self, $column) = @_;
    my $jn = $self->_add_linked_join ($column->join);
    my $index = $jn > 1 ? "_$jn" : '';
    $column->sprefix . $index;
}

sub add_sort
{   my ($self, $column, $type) = @_;

    my $s_table = $self->_table_name($column);
    $self->order_by_inc;
    my $sort_name = "sort_".$self->order_by_count;
    if ($column->link_parent)
    {
        push @{$self->plus_select}, {
            concat => [
                "$s_table.".$column->value_field,
                $self->_table_name_linked($column->link_parent).".".$column->value_field,
            ],
            -as    => $sort_name,
        };
    }
    else {
        push @{$self->plus_select}, {
            # XXX Not sure how to do this without concat
            concat => "$s_table.".$column->value_field,
            -as    => $sort_name,
        }
    }
    push @{$self->order_by}, {
        $type => $sort_name,
    };
}

# $ignore_perms means to ignore any permissions on the column being
# processed. For example, if the current user is updating a record,
# we want to process columns that the user doesn't have access to
# for things like alerts, but not for their normal viewing.
sub _search_construct
{   my ($self, $filter, $layout, $ignore_perms) = @_;

    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        my @final;
        foreach my $rule (@$rules)
        {
            my @res = $self->_search_construct($rule, $layout, $ignore_perms);
            push @final, @res if @res;
        }
        my $condition = $filter->{condition} eq 'OR' ? '-or' : '-and';
        return @final ? [$condition => \@final] : [];
    }

    my %ops = (
        equal            => '=',
        greater          => '>',
        greater_or_equal => '>=',
        less             => '<',
        less_or_equal    => '<=',
        contains         => '-like',
        begins_with      => '-like',
        not_equal        => '!=',
        is_empty         => '=',
        is_not_empty     => '!=',
    );

    my %permission = $ignore_perms ? () : (permission => 'read');
    my $column   = $layout->column($filter->{id}, %permission)
        or return;
    my $operator = $ops{$filter->{operator}}
        or error __x"Invalid operator {filter}", filter => $filter->{operator};

    my $vprefix = $filter->{operator} eq 'contains' ? '' : '';
    my $vsuffix = $filter->{operator} =~ /contains|begins_with/ ? '%' : '';
    
    my $s_table = $self->_table_name($column);

    my $value;
    if ($filter->{operator} eq 'is_empty' || $filter->{operator} eq 'is_not_empty')
    {
        my $comb = $filter->{operator} eq 'is_empty' ? '-or' : '-and';
        $value = $column->type eq 'calc' || $column->type eq 'string'
            ? [ $comb => undef, "" ]
            : undef;
    }
    else {
        $value = $vprefix.$filter->{value}.$vsuffix;
    }

    my $s_field;
    if ($column->type eq "daterange")
    {
        $value = DateTime->now if $filter->{value} eq "CURDATE";
        
        # If it's a daterange, we have to be intelligent about the way the
        # search is constructed. Greater than, less than, equals all require
        # different values of the date range to be searched
        if ($operator eq "=")
        {
            $s_field = "value";
        }
        elsif ($operator eq ">" || $operator eq ">=")
        {
            $s_field = "to";
        }
        elsif ($operator eq "<" || $operator eq "<=")
        {
            $s_field = "from";
        }
        elsif ($operator eq "-like")
        {
            # Requires 2 searches ANDed together
            return ('-and' => ["$s_table.from" => { '<=', $value}, "$s_table.to" => { '>=', $value}]);
        }
        else {
            error __x"Invalid operator {operator} for date range", operator => $operator;
        }
    }
    elsif ($column->type eq "file")
    {
        $s_field = "name";
    }
    else {
        $s_field = "value";
    }

    if ($column->type eq "person")
    {
        my $curuser = $self->user && $self->user->{value}
            or warning "FIXME: user not set for filter";
        $curuser ||= "";
        $value =~ s/\[CURUSER\]/$curuser/g;
    }

    $value =~ s/\_/\\\_/g if $operator eq '-like';
    my $sq = {$operator => $value};
    # By default SQL will not include NULL values for not equals.
    # Let's include them
    $sq = [ $sq, undef ] if $filter->{operator} eq 'not_equal';
    if (!$column->link_parent)
    {
        ("$s_table.$s_field" => $sq);
    }
    else {
        (
            -or => [
                "$s_table.$s_field" => $sq,
                $self->_table_name_linked($column->link_parent).".$s_field" => $sq,
            ],
        );
    }
}

sub csv
{   my $self = shift;
    my $csv  = Text::CSV::Encoded->new({ encoding  => undef });

    # Column names
    my @columns = $self->view
        ? $self->layout->view($self->view->id, user_can_read => 1)
        : $self->layout->all(user_can_read => 1);
    my @colnames = ("Serial");
    push @colnames, map { $_->name } @columns;
    $csv->combine(@colnames)
        or error __x"An error occurred producing the CSV headings: {err}", err => $csv->error_input;
    my $csvout = $csv->string."\n";

    # All the data values
    foreach my $line (@{$self->results})
    {
        my @items = ($line->current_id);
        push @items, map { $line->fields->{$_->id} } @columns;
        $csv->combine(@items)
            or error __x"An error occurred producing a line of CSV: {err} {items}",
                err => "".$csv->error_diag, items => "@items";
        $csvout .= $csv->string."\n";
    }
    $csvout;
}

sub data
{
    my $self = shift;

    my $columns = $self->layout->all;

    my @output;
    foreach my $record (@{$self->results})
    {
        my $serial = $record->current_id;
        my @rec = ($record->record_id, $serial);

        foreach my $column (@$columns)
        {
            my $field = $column->field;
            my $value = $record->values->{$field};
            push @rec, $value;
        }
        push @output, \@rec;
    }
    @output;
}

# Base function for calendar and timeline
sub data_time
{   my ($self, $type, %options) = @_;

    my @colors = qw/event-important event-success event-warning event-info event-inverse event-special/;
    my @result;
    my %datecolors;
    my %timeline_groups;
    my $group_count;

    # Need a Graph::Data instance to get relevant colors
    my $graph = GADS::Graph::Data->new(
        schema  => $self->schema,
        records => undef,
    );

    # All the data values
    foreach my $record (@{$self->results})
    {
        my @dates; my @titles;
        foreach my $column (@{$self->columns_retrieved})
        {
            if ($column->type eq "daterange" || ($column->return_type && $column->return_type eq "date"))
            {
                next unless $column->user_can('read');

                if (@dates)
                {
                    trace __x"Record ID {id} already exists in timeline. Not going to add again.",
                        id => $record->current_id;
                    next;
                }

                # Create colour if need be
                $datecolors{$column->id} = shift @colors unless $datecolors{$column->id};

                # Set colour
                my $color = $datecolors{$column->id};

                # Get item value
                my $d = $record->fields->{$column->id};

                # Push value onto stack
                if ($column->type eq "daterange")
                {
                    $d->from_dt && $d->to_dt or next;
                    # It's possible that values from other columns not within
                    # the required range will have been retrieved. Don't bother
                    # adding them
                    push @dates, {
                        from  => $d->from_dt,
                        to    => $d->to_dt,
                        color => $color,
                    } if (!$self->to || DateTime->compare($self->to, $d->from_dt) >= 0)
                      && (!$self->from || DateTime->compare($d->to_dt, $self->from) >= 0);
                }
                else {
                    $d->value or next;
                    push @dates, {
                        from  => $d->value,
                        to    => $d->value,
                        color => $color,
                    } if (!$self->from || DateTime->compare($d->value, $self->from) >= 0)
                      && (!$self->to || DateTime->compare($self->to, $d->value) >= 0);
                }
            }
            else {
                next if $column->type eq "rag";
                # Check if the user has selected only one label
                next if $options{label} && $options{label} != $column->id;
                # Not a date value, push onto title
                # Don't want full HTML, which includes hyperlinks etc
                my $v = encode_entities($record->fields->{$column->id}->as_string);
                push @titles, $v if $v;
            }
        }
        if (my $label = $options{label})
        {
            @titles = (encode_entities $record->fields->{$label}->as_string)
                if $record->fields->{$label};
        }
        my $item_color;
        if (my $color = $options{color})
        {
            if ($record->fields->{$color})
            {
                my $val = $record->fields->{$color}->as_string;
                $item_color = $graph->get_color($val);
            }
        }
        my $item_group;
        if (my $group = $options{group})
        {
            if ($record->fields->{$group})
            {
                my $val = $record->fields->{$group}->as_string;
                unless ($item_group = $timeline_groups{$val})
                {
                    $item_group = ++$group_count;
                    $timeline_groups{$val} = $item_group;
                }
            }
        }

        # Create title label
        my $title = join ' - ', @titles;
        if ($type eq 'calendar' && length $title > 90)
        {
            $title = substr($title, 0, 86).'...';
        }

        foreach my $d (@dates)
        {
            next unless $d->{from} && $d->{to};
            if ($type eq 'calendar')
            {
                my $item = {
                    "url"   => "/record/" . $record->current_id,
                    "class" => $d->{color},
                    "title" => $title,
                    "id"    => $record->current_id,
                    "start" => $d->{from}->epoch*1000,
                    "end"   => $d->{to}->epoch*1000,
                };
                push @result, $item;
            }
            else {
                my $item = {
                    "content" => $title,
                    "id"      => $record->current_id,
                    "start"   => $d->{from}->ymd,
                    "group"   => $item_group,
                };
                $item->{style} = qq(background-color: $item_color)
                    if $item_color;
                $item->{end} = $d->{to}->ymd
                    if $d->{from}->epoch != $d->{to}->epoch;
                push @result, $item;
            }
        }
    }

    my @groups = map {
        {
            id      => $timeline_groups{$_},
            content => $_,
        }
    } keys %timeline_groups;

    wantarray ? (\@result, \@groups) : \@result;
}

sub data_calendar
{   my $self = shift;
    $self->data_time('calendar');
}

sub data_timeline
{   my $self = shift;
    $self->data_time('timeline', @_);
}

1;


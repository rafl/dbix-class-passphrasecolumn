use strict;
use warnings;

package DBIx::Class::PassphraseColumn;

use Class::Load 'load_class';
use namespace::clean;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw(InflateColumn::Authen::Passphrase));

__PACKAGE__->mk_classdata('_passphrase_columns');

sub register_column {
    my ($self, $column, $info, @rest) = @_;

    if (my $encoding = $info->{passphrase}) {
        $info->{inflate_passphrase} = $encoding;

        $self->throw_exception(q['passphrase_class' is a required argument])
            unless exists $info->{passphrase_class}
                && defined $info->{passphrase_class};

        my $class = 'Authen::Passphrase::' . $info->{passphrase_class};
        load_class $class;

        my $args = $info->{passphrase_args} || {};
        $self->throw_exception(q['passphrase_args' must be a hash reference])
            unless ref $args eq 'HASH';

        my $encoder = sub {
            my ($val) = @_;
            $class->new(%{ $args }, passphrase => $val)->${\"as_${encoding}"};
        };

        $self->_passphrase_columns({
            %{ $self->_passphrase_columns || {} },
            $column => $encoder,
        });
    }

    $self->next::method($column, $info, @rest);
}

sub set_column {
    my ($self, $col, $val, @rest) = @_;

    my $ppr_cols = $self->_passphrase_columns;
    $self->next::method($col, $ppr_cols->{$col}->($val), @rest)
        if exists $ppr_cols->{$col};

    return $self->next::method($col, $val, @rest);
}

sub new {
    my ($self, $attr, @rest) = @_;

    my $ppr_cols = $self->_passphrase_columns;
    for my $col (keys %{ $ppr_cols }) {
        next unless exists $attr->{$col} && !ref $attr->{$col};
        $attr->{$col} = $ppr_cols->{$col}->( $attr->{$col} );
    }

    return $self->next::method($attr, @rest);
}

1;

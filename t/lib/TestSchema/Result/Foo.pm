use strict;
use warnings;

package TestSchema::Result::Foo;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(PassphraseColumn));
__PACKAGE__->table('foo');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    passphrase_rfc2307 => {
        data_type        => 'text',
        passphrase       => 'rfc2307',
        passphrase_class => 'SaltedDigest',
        passphrase_args  => {
            algorithm   => 'SHA-1',
            salt_random => 20,
        },
        passphrase_check_method => 'check_passphrase_rfc2307',
    },
    passphrase_crypt => {
        data_type        => 'text',
        passphrase       => 'crypt',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 8,
            salt_random => 1,
        },
        passphrase_check_method => 'check_passphrase_crypt',
    },
    passphrase_crypt2 => {
        data_type        => 'text',
        passphrase       => 'crypt',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 1,
            salt_random => 1,
        },
        passphrase_check_method => 'check_passphrase_crypt_2',
        is_nullable     => 1,
    },
);

__PACKAGE__->set_primary_key('id');

sub update {
   my ($self, $args, @rest) = @_;

   if (delete $args->{t}) {
      $args->{passphrase_crypt2} = Authen::Passphrase::RejectAll->new
   }

   use Devel::Dwarn;
   my $ret = $self->next::method($args->$Dwarn, @rest);

   return $ret
}

1;

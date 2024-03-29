use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::Define',
    license             => 'perl',
    dist_author         => 'Yuki Kimoto <kimoto.yuki@gmail.com>',
    dist_version_from   => 'lib/Class/Define.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Class-Define-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

use strict;
use warnings;
use Test::More 'no_plan';

use Class::Define;

{
    my $first = Class::Define->define('Module1', {
        methods => {
            module1_m1 => sub { return 'module1_m1' },
            module1_m2 => sub { return 'module1_m2' }
        }
    });
    ok(Module1->can('isa'), 'define class');
    ok($first);
    can_ok('Module1', qw/new module1_m1 module1_m2/);
    
    my $m = Module1->new;
    is($m->module1_m1, 'module1_m1', 'define method module1_m1');
    is($m->module1_m2, 'module1_m2', 'define method module1_m2');

    my $again = Class::Define->define('Module1', {
        methods => {
            module1_m3 => sub { return 'module1_m1' },
        }
    });
    ok(!$again);
    ok(!Module1->can('module1_m3'), 'seconde define');
}

{
    Class::Define->define('Module2', {
        base => 'Module1',
        methods => {
            module2_m1 => sub { return 'module2_m1' },
            module2_m2 => sub { return 'module2_m2' }
        }
    });
    
    ok(Module2->can('isa'), 'extend class');
    my $m = Module2->new;
    
    ok($m->isa('Module1'), 'extend class');
    is($m->module2_m1, 'module2_m1', 'base define method module2_m1');
    is($m->module2_m2, 'module2_m2', 'base define method module2_m2');
}

{
    Class::Define->define('Module3', {
        mixins => ['Module1', 'Module2']
    });
    
    my $m = Module3->new;
    is($m->module1_m1, 'module1_m1', 'mixins define method module1_m1');
    is($m->module1_m2, 'module1_m2', 'mixins define method module1_m2');
    is($m->module2_m1, 'module2_m1', 'mixins define method module2_m1');
    is($m->module2_m2, 'module2_m2', 'mixins define method module2_m2');
}

{
    Class::Define->define('Module4', {
        base => 'Module1',
        mixins => ['Module2']
    });
    
    my $m = Module4->new;
    is($m->module1_m1, 'module1_m1', 'mixins define method module1_m1');
    is($m->module1_m2, 'module1_m2', 'mixins define method module1_m2');
    is($m->module2_m1, 'module2_m1', 'mixins define method module2_m1');
    is($m->module2_m2, 'module2_m2', 'mixins define method module2_m2');
}

{
    my $val;
    Class::Define->define('Module5::MM::MM', {
        methods => {
            module5_m1 => sub { return 'module5_m1' }
        },
        initialize => sub {
            my $class = shift;
            $val = $class->module5_m1
        }
    });
    
    is($val, 'module5_m1', 'initialize');
}

{
    eval {
        Class::Define->define(undef);
    };
    like($@, qr/is bad name/, 'class is undef');
    
    eval {
        Class::Define->define('=');
    };
    like($@, qr/= is bad name/, 'class is bad name');
    
    eval {
        Class::Define->define('Module6', {
            base => '='
        });
    };
    like($@, qr/= is bad name/, 'base class is bad name');
    
    eval {
        Class::Define->define('Module7', {
            mixins => 'a'
        });
    };
    like($@, qr/mixins must be array ref/, 'mixin must be array ref');
    
    eval {
        Class::Define->define('Module8', {
            mixins => ['=']
        });
    };
    like($@, qr/= is bad name/, 'mixins class is bad name');
    
    eval {
        Class::Define->define('Module8', {
            initialize => 'a'
        });
    };
    like($@, qr/initialize must be code ref/, 'initialize must be code ref');
}

{
    Class::Define->define('Module9', {
        methods => {
            m1    => ['Attr', {default => 1}],
            m1_to => ['Output', sub{target => 'm1'}]
        }
    });

    Module9
      ->new
      ->m1_to(\my $m1_result);
    
    is($m1_result, 1, 'define attribute');
}

{
    eval {
        Class::Define->define('Module9', {
            no_exist => {}
        });
    };
    like($@, qr/'no_exist' is invalid option/, 'invalid option');
}

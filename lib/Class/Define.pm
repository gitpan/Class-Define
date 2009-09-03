package Class::Define;

our $VERSION = '0.0201';

use warnings;
use strict;

use Carp;

# Valid option names for define method
my %VALID_DEFINE_OPTIONS = map {$_ => 1} qw/base mixins methods initialize/;

# Define class
sub define {
    shift;
    my $class = shift || '';
    my $options = shift || {};
    
    # Check options
    foreach my $key (keys %$options) {
        Carp::croak("'$key' is invalid option")
            unless $VALID_DEFINE_OPTIONS{$key};
    }
    
    # Assign each variable
    my $base_class = $options->{base};
    my $mixin_classes = $options->{mixins} || [];
    my $methods = $options->{methods} || {};
    my $initialize = $options->{initialize};
    
    # Class is valid name?
    Carp::croak("$class is bad name")
      unless __PACKAGE__->_is_valid_class_name($class);
    
    # In case the class is already defined
    return if $class->can('isa');
    
    # Base class is valid name?
    Carp::croak("$base_class is bad name")
      if $base_class && ! __PACKAGE__->_is_valid_class_name($base_class);
    
    # Mixins must be array ref
    Carp::croak("mixins must be array ref")
      if $mixin_classes && ref $mixin_classes ne 'ARRAY';
    
    # Mixin classes are valid name?
    foreach my $mixin_class (@$mixin_classes) {
        Carp::croak("$mixin_class is bad name")
          unless __PACKAGE__->_is_valid_class_name($mixin_class);
    }
    
    # Initialize must be code ref
    Carp::croak("initialize must be code ref")
      if $initialize && ref $initialize ne 'CODE';
    
    # Rearrange mixins class to string
    foreach my $mixin_class (@$mixin_classes) {
        $mixin_class = "'$mixin_class'";
    }
    my $mixin_classes_expression = @$mixin_classes ? join(', ', @$mixin_classes) : '';
    
    # Source code to define class
    my $code = '';
    $code .=
          qq/package $class;\n/;
    
    if ($base_class && $mixin_classes_expression) {
       $code .=
          qq/use Object::Simple(base => '$base_class', mixins => [$mixin_classes_expression]);\n/;
    }
    elsif ($base_class) {
        $code .=
          qq/use Object::Simple(base => '$base_class');\n/;
    }
    elsif ($mixin_classes_expression) {
        $code .=
          qq/use Object::Simple(mixins => [$mixin_classes_expression]);\n/;
    }
    else {
        $code .=
          qq/use Object::Simple;\n/;
    }
    
    # Execute code to define class
    eval $code;
    Carp::croak("fail eval $code: $@") if $@; # never ocuured
    
    # Define methods
    foreach my $name (keys %$methods) {
        
        # Define acessor to Object::Simple functions
        if (ref $methods->{$name} eq 'ARRAY') {
            my ($code_attribute_type, $code_ref) = @{$methods->{$name}};
            Object::Simple->resist_attribute_info($class, $name, $code_ref, $code_attribute_type);
        }
        
        # Define method using normarl way
        else {
            no strict 'refs';
            *{"${class}::$name"} = $methods->{$name};
        }
    }
    
    # Build class
    Object::Simple->build_class($class);
    
    # Execute initialize process
    $initialize->($class) if $initialize;
    
    return 1;
}

# Class name is valid?
sub _is_valid_class_name {
    my ($self, $class_name) = @_;
    $class_name ||= '';
    return $class_name =~ /^(\w+::)*\w+$/ ? 1 : 0;
}

=head1 NAME

Class::Define - define class easily and anywhere

=head1 VERSION

Version 0.0201

=head1 SYNOPSIS

    use Class::Define;
    
    Class::Define->define('Magazine', {
        base => 'Book',
        mixins => ['Cloneable'],
        methods => {
            price => sub { }
        },
        initialize => sub {
            # some code to 
        }
    });
    
    my $magazine = Magazine->new;

=head1 METHODS

=head2 define

You can define class easily and anywhere.

Class::Define->define('Book', {
    methods => {
        title => sub { # some accessor code }
    }
});

this is equal to

    package Book;
    sub title { # some code }

You can aslo define class which extend other class or mixin other classes to use Object::Simple abilities.

    Class::Define->define('Magazine', {
        base => 'Book',
        mixins => ['Cloneable'],
        methods => {
            price => sub { # some accessor code }
        },
        initialize => sub {
            # some initialize when class is required
            pritn "aaa";
        }
    });

this is equal to
    
    package Magazine;
    use Object::Simple(base => 'Book', mixins => ['Cloneable']);
    
    sub price { #some accessor code }
    
    Object::Simple->build_class;
    
    # do initialize
    print "aaa";

You can define attribute by using Object::Simple

    Class::Define->define('Book', {
        methods => {
            title => ['Attr', {default => 'AAA'}],
            price => ['Attr', {default => 1000}]
        }
    }

This is equal to

    package Book;
    use Object::Simple;
    
    sub title : Attr { default => 'AAA' }
    sub price : Attr { default => 1000 }
    
    Object::Simple->build_class;

=head1 SEE ALSO

L<Object::Simple>, L<Class::MOP>

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::Define

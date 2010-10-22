package Class::Define;

use warnings;
use strict;

use Carp 'croak';

# Valid option names for define method
my %VALID_DEFINE_OPTIONS = map {$_ => 1} qw/base methods initialize/;

# Define class
sub define {
    my $self = shift;
    
    # Define anonymous class
    if (ref $_[0]) {
        return $self->define_anonymous_class(@_);
    }
    # Define named class
    else {
        return $self->define_class(@_);
    }
}

# Define named class
sub define_class {
    my $self = shift;
    
    # Class name
    my $class;
    
    # Anonymous class
    if (ref $_[0]) {
        
        # ID for anonymous class
        my $id;
        foreach my $info ((caller 0)[0 .. 2]) {
            $id .= $info || '';
        }
        
        croak "Cannot create anoymouse class id"
          unless $id; # maybe never ocuured.
        
        # Create anonymous class name
        $class = __PACKAGE__->create_anonymous_class_name($id);
    }
    
    # Named class
    else {
        $class = shift || '';
    }
    
    my $options = shift || {};
    
    # Check options
    foreach my $key (keys %$options) {
        croak "'$key' is invalid option"
          unless $VALID_DEFINE_OPTIONS{$key};
    }
    
    # Assign each variable
    my $base_class = $options->{base};
    my $methods    = $options->{methods} || {};
    my $initialize = $options->{initialize};
    
    # Class is valid name?
    croak "$class is bad name"
      unless $self->is_valid_class_name($class);
    
    # In case the class is already defined
    return $class if $class->can('isa');
    
    # Base class is valid name?
    croak "$base_class is bad name"
      if $base_class && ! $self->is_valid_class_name($base_class);
    
    # Initialize must be code ref
    croak "initialize must be code ref"
      if $initialize && ref $initialize ne 'CODE';
    
    # Source code to define class
    my $code = '';
    $code .=
          qq/package $class;\n/;
    
    if ($base_class) {
       $code .=
          qq/use base '$base_class';\n/
    }
    
    # Execute code to define class
    eval $code;
    croak "fail eval $code: $@" if $@; # never ocuured
    
    # Define methods
    foreach my $name (keys %$methods) {
        
        # Define method
        no strict 'refs';
        *{"${class}::$name"} = $methods->{$name};
    }
    
    # Execute initialize process
    $initialize->($class) if $initialize;
    
    return $class;
}

# Define anonymous class
sub define_anonymous_class {
    my ($self, $options) = @_;
    my $class = Class::Define::AnonymousClass->create({options => $options});
    return $class;
}

# Class name is valid?
sub is_valid_class_name {
    my ($self, $class_name) = @_;
    $class_name ||= '';
    return $class_name =~ /^(\w+::)*\w+$/ ? 1 : 0;
}

package Class::Define::AnonymousClass;

use strict;
use warnings;

our $ANONYMOUS_CLASS_PREFIX = 'Class::Define::AnonymousClass::';

# Constructor
sub create {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    
    my $args = shift;
    my $options = $args->{options} || {};
    
    my $class_name = $self->create_anonymous_class_name;
    Class::Define->define($class_name, $options);
    $self->name($class_name);
    return $self;
}

# Class Builder
sub new {
    my $self = shift;
    my $class = $self->name;
    return $class->new(@_);
}


# Create anonymous class name by random
sub create_anonymous_class_name {
    my $self = shift;
    
    while (1) {
        # Create ID
        my $id = time . int(rand 10000000);
        
        # Create class name
        my $class_name = "${ANONYMOUS_CLASS_PREFIX}$id";
        
        return $class_name unless $class_name->can('isa');
    }
}

# Class name
sub name {
    my $self = shift;
    if (@_) {
        $self->{name} = $_[0];
    }
    return $self->{name};
}

# Destructor
sub DESTROY {
    my $self = shift;
    
    # Unload anonymous class
    $self->unload_anonymous_class;
}

sub unload_anonymous_class {
    my $self = shift;
    
    # Get class name
    my $class = $self->name;
    
    # Get ID
    my ($id) = $class =~ /^$ANONYMOUS_CLASS_PREFIX(\d+)/;
    
    # delete infomations to unload class
    no strict 'refs';
    @{$class . '::ISA'} = ();
    %{$class . '::'} = ();
    delete ${$ANONYMOUS_CLASS_PREFIX}{$id . '::'};
}

package Class::Define;

1;

=head1 NAME

Class::Define - define class easily and anywhere

=head1 CAUTION

B<This module will be removed in nearly feature because I think this is buggy and not useful>

=head1 VERSION

Version 0.0402

=cut

our $VERSION = 0.0402;

=head1 SYNOPSIS

    use Class::Define;
    
    # Define class
    Class::Define->define('Magazine', {
        base => 'Book',
        methods => {
            price => sub { }
        },
        initialize => sub {
            # some code to 
        }
    });
    
    my $magazine = Magazine->new;
    
    # Create anonimouse class
    my $Magazine =  Class::Define->define({
        base => 'Book',
        methods => {
            price => sub { }
        },
        initialize => sub {
            # some code to 
        }
    });
    
    my $magazine = $Magazine->new;
    
=head1 METHODS

=head2 define

You can define class easily and anywhere.

Class::Define->define('Book', {
    methods => {
        new   => sub {
            my $class = shift;
            return bless {@_}, $class;
        }
        title => sub { # some accessor code }
    }
});

this is equal to

    package Book;
    sub new {
        my $class = shift;
        return bless {@_}, $class;
    }
    
    sub title { # some code }

You can aslo define class which extend other class.

    Class::Define->define('Magazine', {
        base => 'Book',
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
    use base 'Book';
    
    sub price { #some accessor code }
   
    # do initialize
    print "aaa";

You can also define anonymous class if you do not write class name.

    my $anonymous_class = Class::Define->define({
        base => 'Book',
        methods => {
            price => sub { };
        }
    });
    
    my $obj = $anonymous_class->new;
    
=head1 SEE ALSO

L<Class::MOP>

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


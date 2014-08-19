package Zazzle::API;
use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '1.40';

# dependencies
use Digest::MD5 qw(md5_hex);
use IPC::Open2 qw(open2);
use URI::Escape qw(uri_escape);
use XML::Simple qw(xml_in);
use File::Which;

sub new {
	my ($package, $id, $key) = @_;
	my $curl = which('curl');
	unless ($curl) {
	    print "cURL not found. Please install:\n";
	    print "http://curl.haxx.se/download.html\n";
	    die;
	}
	my $session = {
	    'baseurl' => 'https://vendor.zazzle.com/v100/api.aspx?',
	    'url'     => undef,
	    'id'      => $id,
	    'secret'  => $key,
	    'curl'    => $curl . q( -k -H 'Content-Type: text/xml'),
	    'data'    => [],
	    'href'    => {},
	};
	bless $session, $package;
	return $session;
}

sub fetch {
	my $self = shift;
	unless ($self->{'url'}) {
	    # this typically happens because fetch was called directly
	    die q($self->{'url'} undefined);
	}
	$self->{'data'} = [];
	$self->{'href'} = {};
	my $pid = open2(\*READ,
	    undef,
	    "$self->{'curl'} '$self->{'url'}' 2>/dev/null");
	my @resp = <READ>;
	close READ;
	waitpid($pid, 0);
	$self->{'data'} = \@resp;
	$self->xmltoh();
	unless ($self->validate()) {
	    warn q(ERROR: dumping contents of $self->{'data'});
	    warn q($self->{'url'}: ) . $self->{'url'};
	    use Data::Dumper;
	    print Dumper($self->{'data'});
	    die "invalid data";
	}
	$self->{'url'} = undef;
}

sub validate {
	my $self = shift;
	my @ary = @{$self->{'data'}};
	# fail right away if this list is empty
	return 0 if ($#ary == -1);
	my $test = 0;
	# returned data should contain SUCCESS code
	foreach (@ary) {
	    if ($_ =~ m:<Code>SUCCESS</Code>:) {
		$test = 1;
		last;
	    }
	}
	# returned data should end with closing Response tag
	if ($ary[-1] =~ m:</Response>$:) {
	    $test = 1;
	}
	return $test;
}

sub listneworders {
	my $self = shift;
        my $hash = md5_hex($self->{'id'}, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=listneworders";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&hash=$hash";
	$self->fetch();
}

sub getshippinglabel {
	my ($self, $orderid, $weight, $format) = @_;
	die "no orderid specified" unless ($orderid);
	die "no order weight specified" unless ($weight);
	$format = 'PDF' unless ($format);
	unless ($format eq 'PDF'
	    || $format eq 'ZPL'
	    || $format eq 'PNG') {
		warn "invalid label format: $format - using PDF";
		$format = 'PDF';
	}
	my $hash = md5_hex($self->{'id'}, $orderid, $weight,
	    $format, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=getshippinglabel";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&orderid=$orderid";
	$self->{'url'} .= "\&weight=$weight\&format=$format";
	$self->{'url'} .= "\&hash=$hash";
	$self->fetch();
}

sub ackorder {
	my ($self, $orderid, $type, $action) = @_;
	# die if ackorder was called directly without wrapper
	die "no orderid specified" unless ($orderid);
	die "no ack type specified" unless ($type);
	die "no ack action specified" unless ($action);
	unless ($type eq 'new'
	    || $type eq 'update'
	    || $type eq 'message') {
		die "invalid ack type: $type";
	}
	unless ($action eq 'accept' || $action eq 'reject') {
	    die "invalid ack action: $action";
	}
	my $hash = md5_hex($self->{'id'}, $orderid,
			   $type, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=ackorder";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&orderid=$orderid";
	$self->{'url'} .= "\&type=$type\&action=$action\&hash=$hash";
	$self->fetch();
}

sub ackorder_new_accept {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ackorder($orderid, 'new', 'accept');
}

sub ackorder_new_reject {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ackorder($orderid, 'new', 'reject');
}

sub ackorder_update_accept {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ackorder($orderid, 'update', 'accept');
}

sub ackorder_update_reject {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ackorder($orderid, 'update', 'reject');
}

sub ackorder_message_accept {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ackorder($orderid, 'message', 'accept');
}

sub ackorder_message_reject {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ackorder($orderid, 'message', 'reject');
}

sub listupdatedorders {
	my $self = shift;
	my $hash = md5_hex($self->{'id'}, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=listupdatedorders";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&hash=$hash";
	$self->fetch();
}

sub listordermessages {
	my $self = shift;
	my $hash = md5_hex($self->{'id'}, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=listordermessages";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&hash=$hash";
	$self->fetch();
}

sub addorderactivity {
	my ($self, $orderid, $activity) = @_;
	die "no orderid specified" unless ($orderid);
	die "no activity listed" unless ($activity);
	my $uri_msg = uri_escape($activity);
	my $hash = md5_hex($self->{'id'}, $orderid,
		$activity, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=addorderactivity";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&orderid=$orderid";
	$self->{'url'} .= "\&activity=$uri_msg\&hash=$hash";
	$self->fetch();
}

sub getorder {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	my $hash = md5_hex($self->{'id'}, $orderid, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=getorder";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&orderid=$orderid";
	$self->{'url'} .= "\&hash=$hash";
	$self->fetch();
}

sub xmltoh {
	# parse xml data to hash ref and store in href element
	my $self = shift;
	$self->{'href'} = xml_in(join('', @{$self->{'data'}}),
	    SuppressEmpty => undef,
	    ForceArray => ['Order', 'LineItem', 'Product',
		'Message', 'ShippingDocument'],
	    GroupTags => {'Products' => 'Product', 'Orders' => 'Order',
		'LineItems' => 'LineItem', 'Result' => 'Orders',
		'Messages' => 'Message', 'PackingSheet' => 'Page',
		'ShippingDocuments' => 'ShippingDocument'});
}

sub license {
my $lic = q|
#########################################################################
# Copyright (c) 2014, Ted Roby (ted at sranet dot com)                  #
# All rights reserved.                                                  #
#                                                                       #
# Redistribution and use in source and binary forms, with or without    #
#       modification, are permitted provided that the following         #
#       conditions are met:                                             #
#     * Redistributions of source code must retain the above copyright  #
#       notice, this list of conditions and the following disclaimer.   #
#     * Redistributions in binary form must reproduce the above         #
#       copyright notice, this list of conditions and the following     #
#       disclaimer in the documentation and/or other materials provided #
#       with the distribution.                                          #
#     * The name of Ted Roby and the names of its contributors may not  #
#       be used to endorse or promote products derived from this        #
#       software without specific prior written permission.             #
#                                                                       #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS   #
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT     #
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR #
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TED ROBY BE    #
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR   #
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF  #
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       #
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, #
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE  #
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,     #
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                    #
#########################################################################
|;
return $lic;
}

1;

__END__

=pod

=head1 NAME

Zazzle REST API Order Integration

=head1 SYNOPSIS

=over 4

=item use Zazzle::API

=item my $zaz = Zazzle::API->new($id, $key)

Initialize new object with VendorID, and Secret Key.

=item $zaz->{'data'}

This element will always contain an array reference, or it will
be undefined. When new() is called, this object is undefined.
It will be subsequently undefined each time before a REST call is
made to Zazzle. Whatever xml data is returned by the Zazzle API
will be stored in this object. It will not be cleared again until
another call is made. You may inspect this element for debugging,
and order data retrieval concerning all methods documented below.

Commonly, you will reference this element as: @{$zaz->{'data'}}
where you can then parse the xml data within line by line.

=item $zaz->{'href'}

When xml data returned from Zazzle is stored, it is also parsed
into a hash reference using XML::Simple. This hash reference is
then stored here. The ForceArray option is used for a few, select
tags like <Orders>, which should be treated as a list.

=item $zaz->listneworders()

Requests ListNewOrders method from Zazzle. All requests currently
die if the returned data fails validation.

=item $zaz->getshippinglabel($orderid, $weight, $format)

Request a shipping label with specified orderid and weight. Format
must be one of: PDF, ZPL or PNG. PDF is used as the default, but a
warning will be produced if an invalid string is specified.

=item $zaz->ackorder_new_accept($orderid)
$zaz->ackorder_update_accept($orderid)
$zaz->ackorder_message_accept($orderid)

Acknowledge receipt of new orders, updates and messages from Zazzle.

=item $zaz->ackorder_new_reject($orderid)
$zaz->ackorder_update_reject($orderid)
$zaz->ackorder_message_reject($orderid)

Zazzle documentation states that the 'reject' methods will
probably never be used, but if there is such a need, here they are.

=item $zaz->listupdatedorders()

Return updated order information from Zazzle customer support. This
should be called regularly, and before labels are printed for shipment.
Use ackorder_update_accept() or ackorder_update_reject() to answer
these updates.

=item $zaz->listordermessages()

Fetch outstanding messages. Zazzle says these messages are rarely used,
but this is how their customer support delivers handling instructions.
This should probably be checked whenever listupdateorders() is called.
Use ackorder_messages_accept() or ackorder_messages_reject() to answer
these updates.

=item $zaz->addorderactivity($orderid, $activity)

Submit a message to Zazzle concerning this order. This message will be
available to their customer support staff when they lookup an order.

=item $zaz=>getorder($orderid)

Fetch order data for the specified orderID.

=back

=head1 AUTHOR

    Ted Roby, (ted at sranet dot com)

=head1 COPYRIGHT

    All rights reserved. Released under BSD-Style license.
    See Zazzle::API->license() for more information.

=cut


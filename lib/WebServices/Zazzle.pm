package WebServices::Zazzle;
use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '1.49';

# dependencies
use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;
use URI::Escape qw(uri_escape);
use XML::Simple qw(xml_in);

sub new {
	my ($package, $id, $key) = @_;
	my $session = {
	    'baseurl' => 'https://vendor.zazzle.com/v100/api.aspx?',
	    'url'     => undef,
	    'id'      => $id,
	    'secret'  => $key,
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
	my $ua = LWP::UserAgent->new();
	$ua->protocols_allowed(['https']);
	my $response = $ua->get($self->{'url'});
	my $h = $response->{'_headers'};
	if ($h->header('client-warning')) {
	    die "$response->{'_msg'}";
	}
	unless (_validate($response->{'_content'})) {
	    die "invalid data";
	}
	$self->{'url'} = undef;
	return _xmltoh($response);
}

sub _validate {
	my $data = shift;
	my $test = 0;
	# fail right away if undefined
	return $test unless ($data);
	# returned data should contain SUCCESS code
	if ($data =~ m:<Code>SUCCESS</Code>: &&
	    $data =~ m:</Response>$:) {
		$test = 1;
	}
	return $test;
}

sub list_new_orders {
	my $self = shift;
        my $hash = md5_hex($self->{'id'}, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=listneworders";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&hash=$hash";
	return $self->fetch();
}

sub get_shipping_label {
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
	return $self->fetch();
}

sub ack_order {
	my ($self, $orderid, $type, $action) = @_;
	# die if ack_order was called directly without wrapper
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
	return $self->fetch();
}

sub ack_order_new_accept {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ack_order($orderid, 'new', 'accept');
}

sub ack_order_new_reject {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ack_order($orderid, 'new', 'reject');
}

sub ack_order_update_accept {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ack_order($orderid, 'update', 'accept');
}

sub ack_order_update_reject {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ack_order($orderid, 'update', 'reject');
}

sub ack_order_message_accept {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ack_order($orderid, 'message', 'accept');
}

sub ack_order_message_reject {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	$self->ack_order($orderid, 'message', 'reject');
}

sub list_updated_orders {
	my $self = shift;
	my $hash = md5_hex($self->{'id'}, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=listupdatedorders";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&hash=$hash";
	return $self->fetch();
}

sub list_order_messages {
	my $self = shift;
	my $hash = md5_hex($self->{'id'}, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=listordermessages";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&hash=$hash";
	return $self->fetch();
}

sub add_order_activity {
	my ($self, $orderid, $activity) = @_;
	die "no orderid specified" unless ($orderid);
	die "no activity listed" unless ($activity);
	my $uri_msg = uri_escape($activity);
	my $hash = md5_hex($self->{'id'}, $orderid,
		$activity, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=addorderactivity";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&orderid=$orderid";
	$self->{'url'} .= "\&activity=$uri_msg\&hash=$hash";
	return $self->fetch();
}

sub get_order {
	my ($self, $orderid) = @_;
	die "no orderid specified" unless ($orderid);
	my $hash = md5_hex($self->{'id'}, $orderid, $self->{'secret'});
	$self->{'url'}  = "$self->{'baseurl'}method=getorder";
	$self->{'url'} .= "\&vendorid=$self->{'id'}\&orderid=$orderid";
	$self->{'url'} .= "\&hash=$hash";
	return $self->fetch();
}

sub _xmltoh {
	# parse xml content to hash ref and return
	my $response = shift;
	return xml_in($response->{'_content'},
	    SuppressEmpty => undef,
	    ForceArray => ['Order', 'LineItem', 'Product', 'Message',
		'ShippingDocument', 'PrintFile', 'PreviewFile', 'Page'],
	    GroupTags => {'Products' => 'Product', 'PackingSheet' => 'Page',
		 'Orders' => 'Order', 'LineItems' => 'LineItem', 'Result' => 'Orders',
		'Messages' => 'Message', 'ShippingDocuments' => 'ShippingDocument',
		'PrintFiles' => 'PrintFile', 'Previews' => 'PreviewFile'});
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

All methods except for new() return a hash reference formatted by XML::Simple.
Nested elements are converted by ForceArray, and probably use GroupTags as well
to eliminate extraneous layers of indirection.

=over 4

=item use WebServices::Zazzle

=item my $zaz = WebServices::Zazzle->new($id, $key)

Initialize new object with VendorID, and Secret Key.

=item $zaz->list_new_orders()

Requests ListNewOrders method from Zazzle. All requests currently
die if the returned data fails validation.

=item $zaz->get_shipping_label($orderid, $weight, $format)

Request a shipping label with specified orderid and weight. Format
must be one of: PDF, ZPL or PNG. PDF is used as the default, but a
warning will be produced if an invalid string is specified.

=item $zaz->ack_order_new_accept($orderid)
$zaz->ack_order_update_accept($orderid)
$zaz->ack_order_message_accept($orderid)

Acknowledge receipt of new orders, updates and messages from Zazzle.

=item $zaz->ack_order_new_reject($orderid)
$zaz->ack_order_update_reject($orderid)
$zaz->ack_order_message_reject($orderid)

Zazzle documentation states that the 'reject' methods will
probably never be used, but if there is such a need, here they are.

=item $zaz->list_updated_orders()

Return updated order information from Zazzle customer support. This
should be called regularly, and before labels are printed for shipment.
Use ack_order_update_accept() or ack_order_update_reject() to answer
these updates.

=item $zaz->list_order_messages()

Fetch outstanding messages. Zazzle says these messages are rarely used,
but this is how their customer support delivers handling instructions.
This should probably be checked whenever listupdateorders() is called.
Use ack_order_messages_accept() or ack_order_messages_reject() to answer
these updates.

=item $zaz->add_order_activity($orderid, $activity)

Submit a message to Zazzle concerning this order. This message will be
available to their customer support staff when they lookup an order.

=item $zaz=>get_order($orderid)

Fetch order data for the specified orderID.

=back

=head1 AUTHOR

    Ted Roby, (ted at sranet dot com)

=head1 COPYRIGHT

    All rights reserved. Released under BSD-Style license.
    See WebServices::Zazzle->license() for more information.

=cut


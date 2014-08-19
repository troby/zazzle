package Zazzle::DB;
use warnings;
use strict;
use DBI;

sub add {
	my $data = shift;
	my $count = 0;
	# this should never be encountered because we tested in Zazzle.pm
	unless ($data->{'Status'}->{'Code'} eq 'SUCCESS') {
	    die "Invalid API Response";
	}
	# empty Result will look like HASH instead of ARRAY
	unless ($data->{'Result'}) {
	    return 0;
	}
	foreach my $order (@{$data->{'Result'}}) {
	    next if (order_exists($order->{'OrderId'}));
	    # set count to -1 if add_order responds with error
	    $count = -1 if (add_order($order));
	    last if ($count == -1);
	    ++$count;
	}
	# return order count results
	return $count;
}

sub add_order {
	my $order = shift;
	my $err = 0;
	my $packing_sheet_url = $order->{'PackingSheet'}->{'Front'}->{'Url'};
	$packing_sheet_url =~ s:&amp\;:&:g;
	my $shipto = $order->{'ShippingAddress'};
	my $dbh = db_connect();
	my $sth = $dbh->prepare(
	    "INSERT INTO zazzle_orders SET orderid=?, order_date=?, method=?,
	    priority=?, status=?, packing_sheet=?, shipto_address1=?,
	    shipto_address2=?, shipto_address3=?, shipto_name=?,
	    shipto_name2=?, shipto_city=?, shipto_state=?, shipto_country=?,
	    shipto_country_code=?, shipto_zip=?, shipto_phone=?,
	    shipto_email=?, shipto_type=?");
	$sth->execute($order->{'OrderId'}, $order->{'OrderDate'},
	    $order->{'DeliveryMethod'}, $order->{'Priority'},
	    $order->{'Status'}, $order->{'PackingSheet'}->{'Front'}->{'Url'},
	    $shipto->{'Address1'}, $shipto->{'Address2'},
	    $shipto->{'Address3'}, $shipto->{'Name'}, $shipto->{'Name2'},
	    $shipto->{'City'}, $shipto->{'State'}, $shipto->{'Country'},
	    $shipto->{'CountryCode'}, $shipto->{'Zip'}, $shipto->{'Phone'},
	    $shipto->{'Email'}, $shipto->{'Type'});
	$sth->finish();
	add_items($dbh, $order);
	add_messages($dbh, $order) if ($order->{'Messages'});
	if ($dbh->err) {
	    $err = 1;
	    $dbh->rollback();
	} else {
	    $dbh->commit();
	}
	$dbh->disconnect();
	return $err;
}

sub order_exists {
	my $orderid = shift;
	my $dbh = db_connect();
	my $sth = $dbh->prepare(
	    "SELECT orderid FROM zazzle_orders WHERE orderid=?");
	$sth->execute($orderid);
	my $rh = $sth->fetchrow_hashref();
	$sth->finish();
	$dbh->disconnect();
	if ($rh) {
	    print "$rh->{'orderid'} already exists.\n";
	    return 1;
	} else {
	    return 0;
	}
}

sub add_items {
	my ($dbh, $order) = @_;
	my $items = $order->{'LineItems'}; # array of hash refs
	my $sth = $dbh->prepare(
	    "INSERT INTO zazzle_items SET orderid=?, line_item_id=?,
	    line_item_type=?, quantity=?, description=?, attributes_string=?");
	foreach my $item (@$items) {
	    $sth->execute($order->{'OrderId'}, $item->{'LineItemId'},
		$item->{'LineItemType'}, $item->{'Quantity'},
		$item->{'Description'}, $item->{'Attributes'});
	}
	$sth->finish();
}

sub add_messages {
	my ($dbh, $order) = @_;
	my $messages = $order->{'Messages'}; # array of hash refs
	my $sth = $dbh->prepare(
	    "INSERT INTO zazzle_messages SET orderid=?,
	    text=? message_date=?");
	foreach my $msg (@$messages) {
	    $sth->execute($order->{'OrderId'},
		$msg->{'text'}, $msg->{'message_date'});
	}
	$sth->finish();
}

sub db_connect {
	my $dbh = DBI->connect(
	    "DBI:mysql:mitercraft:localhost", 'miterdb', '4b126e50cc50669a',
		{ RaiseError => 0, AutoCommit => 0 });
	return $dbh;
}
1;

__END__

=pod

=head1 NAME

Zazzle DBI Integration

=head1 SYNOPSIS

=over 4

=item use Zazzle::DB

=item Zazzle::DB::add($zaz->{'href'});

Parse data in $zaz->{'href'} and insert into mysql database.
Return -1 if mysql INSERT fails, or return number of times
INSERT was successful. Skip any pre-existing orderid.

=back

=head1 AUTHOR

    Ted Roby, (ted at sranet dot com)

=head1 COPYRIGHT

    All rights reserved. Released under BSD-Style license.
    See Zazzle::API->license() for more information.

=cut


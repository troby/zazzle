use WebServices::Zazzle;
use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;
use URI::Escape qw(uri_escape);
use XML::Simple qw(xml_in);

# Test 1: object initialization
my $obj = WebServices::Zazzle->new('user', 'secret');
print "ok 1\n";

# Test 2: test md5_hex
my $good_sum = 'd67673f506f955d7c61821867a3a41dc';
my $test_sum = Digest::MD5::md5_hex('user', 'secret');
if ($test_sum eq $good_sum) {
	print "ok 2\n";
} else {
	print "fail 2\n";
}

# Test 3: test uri_escape
my $plain = 'string with symbols: !@#$%^&*()_-+=';
my $coded = 'string%20with%20symbols%3A%20%21%40';
$coded   .= '%23%24%25%5E%26%2A%28%29_-%2B%3D';
if (uri_escape($plain, "^A-Za-z0-9\-\._~") eq $coded) {
	print "ok 3\n";
} else {
	print "fail 3\n";
}

# Test 4: test xml_in
my $xml = '<xml><cat><status>Success</status></cat></xml>';
my $hr = xml_in($xml, ForceArray => ['cat']);
if ($hr->{'cat'}->[0]->{'status'} eq 'Success') {
	print "ok 4\n";
} else {
	print "fail 4\n";
}

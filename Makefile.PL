use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'    => 'WebServices::Zazzle',
	'VERSION_FROM' => 'lib/WebServices/Zazzle.pm',
	'PREREQ_PM' => {
	    "Digest::MD5"=>0,
	    "LWP::UserAgent"=>0,
	    "URI::Escape"=>0,
	    "XML::Simple"=>0,
	},
);

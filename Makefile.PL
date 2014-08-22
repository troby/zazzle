use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'    => 'WebServices::Zazzle',
	'VERSION_FROM' => 'lib/WebServices/Zazzle.pm',
	'PREREQ_PM' => {
	    "Digest::MD5"=>0,
	    "IPC::Open2"=>0,
	    "File::Which"=>0,
	    "URI::Escape"=>0,
	    "XML::Simple"=>0,
	},
);

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'    => 'Zazzle',
	'VERSION_FROM' => 'Zazzle.pm',
	'PREREQ_PM' => {
	    "Digest::MD5"=>0,
	    "IPC::Open2"=>0,
	    "File::Which"=>0,
	    "URI::Escape"=>0,
	},
);

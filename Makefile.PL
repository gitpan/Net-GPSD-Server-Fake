use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Net::GPSD::Server::Fake},
  VERSION_FROM => q{lib/Net/GPSD/Server/Fake.pm},
  PREREQ_PM => {
                 strict               => 0,
                 vars                 => 0,
                 IO::Socket::INET     => 0,
                 Time::HiRes          => 0,
                 Geo::Functions       => 0.03,
                 Geo::Forward         => 0.09,
                 Net::GPSD::Point     => 0.30,
                 Net::GPSD::Satellite => 0.30,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Net/GPSD/Server/Fake.pm',
                 ) : ()
               ),
             );

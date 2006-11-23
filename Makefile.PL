use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Net::GPSD::Server::Fake},
  VERSION_FROM => q{lib/Net/GPSD/Server/Fake.pm},
  PREREQ_PM => {
                 strict             => 0,
                 vars               => 0,
                 IO::Socket::INET   => 0,
                 Geo::Forward       => 0.06,
                 Time::HiRes        => 0,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Net/GPSD/Server/Fake.pm',
                 ) : ()
               ),
             );

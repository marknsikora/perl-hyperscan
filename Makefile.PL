use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

%pkg_info = ExtUtils::PkgConfig->find('libhs');

WriteMakefile(
    NAME            => 'Hyperscan',
    VERSION_FROM    => 'lib/Hyperscan.pm',
    INC             => '-I.',
    CCFLAGS         => $pkg_info{cflags},
    LIBS            => $pkg_info{libs},
);

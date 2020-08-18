use ExtUtils::MakeMaker;
use ExtUtils::Constant qw(WriteConstants);
use ExtUtils::PkgConfig;

%pkg_info = ExtUtils::PkgConfig->find('libhs');

WriteMakefile(
    NAME            => 'Hyperscan',
    VERSION_FROM    => 'lib/Hyperscan.pm',
    INC             => '-I.',
    CCFLAGS         => "$pkg_info{cflags} -Wall",
    LIBS            => $pkg_info{libs},
);

@names = (
    qw(
      HS_HS_HS_MAJOR MINOR PATCH

      HS_EXT_FLAG_MIN_OFFSET
      HS_EXT_FLAG_MAX_OFFSET
      HS_EXT_FLAG_MIN_LENGTH
      HS_EXT_FLAG_EDIT_DISTANCE
      HS_EXT_FLAG_HAMMING_DISTANCE

      HS_FLAG_CASELESS
      HS_FLAG_DOTALL
      HS_FLAG_MULTILINE
      HS_FLAG_SINGLEMATCH
      HS_FLAG_ALLOWEMPTY
      HS_FLAG_UTF8
      HS_FLAG_UCP
      HS_FLAG_PREFILTER
      HS_FLAG_SOM_LEFTMOST
      HS_FLAG_COMBINATION
      HS_FLAG_QUIET

      HS_MODE_BLOCK
      HS_MODE_NOSTREAM
      HS_MODE_STREAM
      HS_MODE_VECTORED

      HS_MODE_SOM_HORIZON_LARGE
      HS_MODE_SOM_HORIZON_MEDIUM
      HS_MODE_SOM_HORIZON_SMALL
    ),
);

WriteConstants(
    PROXYSUBS => {autoload => 1},
    NAME => 'Hyperscan',
    NAMES => \@names,
);

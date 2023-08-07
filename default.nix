{ stdenv
, lib
, fetchurl
, autoconf
, automake
, texinfo
, which
, pkg-config
, hidapi
, jimtcl
, libjaylink
, libusb1
, libgpiod
, libtool

, enableFtdi ? true, libftdi1

# Allow selection the hardware targets (SBCs, JTAG Programmers, JTAG Adapters)
, extraHardwareSupport ? []
}:

stdenv.mkDerivation rec {
  pname = "wch-openocd";
  version = "0.11.0";
  src = ./.;

  nativeBuildInputs = [ autoconf automake pkg-config libtool texinfo which ];

  buildInputs = [ hidapi jimtcl libftdi1  libusb1 ]
    ++ lib.optionals stdenv.isLinux [ libgpiod libjaylink ];

  preConfigure = ''
    mkdir -p jimtcl src/jtag/drivers/libjaylink
    ./bootstrap nosubmodule
  '';

  configureFlags = [
    "--program-prefix=wch-"
    "--disable-werror"
    "--disable-internal-jimtcl"
    "--disable-internal-libjaylink"
    "--enable-jtag_vpi"
    "--enable-buspirate"
    "--enable-remote-bitbang"
    "--enable-wlinke"
    "--disable-ch347"
    (lib.enableFeature enableFtdi "ftdi")
    (lib.enableFeature stdenv.isLinux "linuxgpiod")
    (lib.enableFeature stdenv.isLinux "sysfsgpio")
  ] ++
    map (hardware: "--enable-${hardware}") extraHardwareSupport
  ;

  enableParallelBuilding = true;

  NIX_CFLAGS_COMPILE = lib.optionals stdenv.cc.isGNU [
    "-Wno-error=cpp"
    "-Wno-error=strict-prototypes" # fixes build failure with hidapi 0.10.0
  ];

  postInstall = lib.optionalString stdenv.isLinux ''
    mkdir -p "$out/etc/udev/rules.d"
    rules="$out/share/openocd/contrib/60-openocd.rules"
    if [ ! -f "$rules" ]; then
        echo "$rules is missing, must update the Nix file."
        exit 1
    fi
    ln -s "$rules" "$out/etc/udev/rules.d/"
  '';
}

{
  pkgs,
  ...
}:

{
  packages.rpki-client = {
    version = "9.8-unstable-2026-06-16";
    description = "Port of OpenBSD's rpki-client RPKI relying party validator to other operating systems.";
    homePage = "https://www.rpki-client.org";
    mainProgram = "rpki-client";
    license = "isc";

    source = {
      git = "github:rpki-client/rpki-client-portable/3693bb927cb68f6975ef3fc50418bf00efd54dac";
      hash = "sha256-BIBXm1aAbQKAgfNZgI7DkMwSXt3RZBi+Zvh6LbpwLD0=";
    };

    build = {
      extraAttrs = {
        openbsdSrc = pkgs.fetchFromGitHub {
          owner = "rpki-client";
          repo = "rpki-client-openbsd";
          rev = "027566b8e6827a9e280a0ef067464fc2336f0179";
          hash = "sha256-lmyECC4uhBLJb89Gm+oqO4ClkkhFGqGm+cD7GivDqok=";
        };
        configureFlags = [
          "--with-base-dir=/var/cache/rpki-client"
          "--with-output-dir=/var/db/rpki-client"
        ];
        preConfigure = ''
          cp -r $openbsdSrc openbsd
          chmod -R +w openbsd
          ./autogen.sh
        '';
      };
      standardBuilder = {
        enable = true;
        packages.build = [
          pkgs.pkg-config
          pkgs.automake
          pkgs.autoconf
          pkgs.libtool
        ];
        packages.run = [
          pkgs.expat
          pkgs.libressl
          pkgs.rsync
          pkgs.zlib
        ];
      };
    };

    test.script = ''
      rpki-client -V
      rpki-client -n -d /tmp -o /tmp
    '';
  };
}

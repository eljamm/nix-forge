{
  lib,
  pkgs,
  ...
}:

{
  packages.kepler-formal = {
    version = "0-unstable-2026-06-16";
    description = "Formal Verification tool for Verilog and Naja interchange format.";
    homePage = "https://github.com/keplertech/kepler-formal";
    mainProgram = "kepler-formal";
    license = lib.licenses.gpl3Only;

    source = {
      git = "github:keplertech/kepler-formal/0bc2a79c3897a6093aa44bcececcdca75c329d63";
      submodules = true;
      hash = "sha256-LdiUOIOij5mCHpi4ptdDyqv31hKb0odREsE6wjIxV4c=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = [
        pkgs.bison
        pkgs.boost
        pkgs.capnproto
        pkgs.cmake
        pkgs.flex
        pkgs.onetbb
        pkgs.pkg-config
        pkgs.python3
        pkgs.spdlog
        pkgs.zlib
      ];
      packages.run = [
        pkgs.capnproto
        pkgs.onetbb
        pkgs.python3
        pkgs.zlib
      ];
      packages.check = [
        pkgs.ctestCheckHook
      ];
    };

    build.extraAttrs = {
      # Tests use shared tmpDir paths and are not safe to run in parallel
      doCheck = true;
      ctestFlags = [ "-j1" ];
    };

    test.script = ''
      kepler-formal --help | grep "Usage: kepler-formal"
    '';
  };
}

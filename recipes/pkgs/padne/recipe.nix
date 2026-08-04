{
  pkgs,
  ...
}:
{
  pkgs.padne.build.identityBuilder = {
    enable = true;
    # TODO: replace with Nixpkgs derivation when it's merged:
    # https://github.com/NixOS/nixpkgs/pull/549111
    derivation = with pkgs.python3Packages; toPythonApplication (callPackage ./_padne.nix { });
  };
}

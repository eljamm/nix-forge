{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "python-web-app";

  services.runtimes.nixos.extraConfig = {
    environment.systemPackages = [
      pkgs.postgresql
    ];
  };
}

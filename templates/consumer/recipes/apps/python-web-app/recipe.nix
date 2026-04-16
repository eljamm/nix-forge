{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "python-web-app";

  links.docs.text = lib.mkForce "yes!";

  services.runtimes.nixos.extraConfig = {
    environment.systemPackages = [
      pkgs.postgresql
    ];
  };
}

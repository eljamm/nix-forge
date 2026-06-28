{
  lib,
  ...
}:
{
  options.nixosConfig = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
    description = ''
      Runtime independent configuration of the resource.

      See the list of available
      [NixOS options](https://search.nixos.org/options) .
    '';
    example = lib.literalExpression "{ services.postgresql.enable = true; }";
  };
  options.ports = lib.mkOption {
    type = lib.types.listOf (lib.types.strMatching "^[0-9]+:[0-9]+$");
    default = [ ];
    description = ''
      List of ports exposed by the resource.

      Format:
        _HOST_PORT:RESOURCE_PORT_
    '';
    example = lib.literalExpression ''[ "5432:5432" ]'';
    apply = self: lib.unique self;
  };
}

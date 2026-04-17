{ provider }:

{
  lib,
  ...
}:

{
  config.perSystem =
    {
      system,
      lib,
      ...
    }:

    let
      appSuffix = "-app";

      flakePackages = provider.packages.${system};

      # Get app and package derivations from provider
      apps = lib.pipe flakePackages [
        (lib.filterAttrs (name: app: lib.hasSuffix appSuffix name))
        (lib.attrValues)
      ];

      packages = lib.pipe flakePackages [
        (lib.filterAttrs (name: pkg: (!lib.hasSuffix appSuffix name) && (pkg ? config)))
        (lib.attrValues)
      ];

      loadConfig = attrs: map (drv: drv.config or { }) attrs;

      providerAppConfigs = loadConfig apps;
      providerPackageConfigs = loadConfig packages;
    in

    {
      forge.provider.packages = providerPackageConfigs;
      forge.provider.apps = providerAppConfigs;
    };
}

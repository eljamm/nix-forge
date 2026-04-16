{ provider }:

{
  lib,
  self,
  ...
}:

{
  config = {
    perSystem =
      {
        system,
        config,
        lib,
        ...
      }:

      let
        apps = lib.attrValues (
          lib.filterAttrs (name: app: lib.hasSuffix "-app" name) provider.packages.${system}
        );

        packages = lib.attrValues (
          lib.filterAttrs (
            name: pacakge: (!lib.hasSuffix "-app" name) && (pacakge ? config)
          ) provider.packages.${system}
        );

        # load package and app recipes from forge provider
        appRecipes = lib.traceValSeq (map (app: provider + "/" + app.config.recipePath) apps);
        packageRecipes = lib.traceValSeq (
          map (package: provider + "/" + package.config.recipePath) packages
        );
      in

      {
        forge.packages = packageRecipes;
        forge.apps = appRecipes;
      };
  };
}

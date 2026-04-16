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

        appRecipes = lib.traceValSeq (map (app: provider + app.config.recipePath) apps);

        # load package and app recipes from forge provider
        # packageRecipes = lib.traceValSeq (loadRecipes config.forge.recipeDirs.packages);
        # appRecipes = lib.traceValSeq (loadRecipes config.forge.recipeDirs.apps);
      in

      {
        # forge.packages = packageRecipes;
        forge.apps = appRecipes;
      };
  };
}

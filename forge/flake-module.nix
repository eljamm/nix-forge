{ inputs }: # nix-forge's inputs (import-tree, nix-utils)

{
  lib,
  self,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;

  rootPath = self.outPath;
in

{
  # core forge modules
  imports = [
    ./modules/forge.nix
    ./modules/apps
    ./modules/packages.nix
    ./packages.nix # Generates _forge-config, _forge-options, _forge-ui
  ];

  options.perSystem = mkPerSystemOption (
    { options, ... }:
    {
      options.forge.consumer.packages = lib.mkOption {
        internal = true;
        type = options.forge.packages.type;
        default = [ ];
        description = "";
      };

      options.forge.consumer.apps = lib.mkOption {
        internal = true;
        type = options.forge.apps.type;
        default = [ ];
        description = "";
      };

      options.forge.provider.packages = lib.mkOption {
        internal = true;
        type = options.forge.packages.type;
        default = [ ];
        description = "";
      };

      options.forge.provider.apps = lib.mkOption {
        internal = true;
        type = options.forge.apps.type;
        default = [ ];
        description = "";
      };
    }
  );

  config = {
    # Override the inputs argument for submodules with nix-forge's inputs
    # This ensures modules have access to nix-utils and import-tree
    _module.args.inputs = lib.mkForce inputs;

    perSystem =
      {
        config,
        lib,
        ...
      }:

      let
        # Merge provider and consumer recipes
        mergeRecipes =
          type:
          map (
            providerItem:
            let
              matchedRecipe = lib.findFirst (
                recipe: recipe.name == providerItem.name
              ) null config.forge.consumer."${type}";
            in
            if matchedRecipe != null then
              {
                imports = [
                  (rootPath + "/" + matchedRecipe.recipePath)
                  providerItem
                ];
              }
            else
              providerItem
          ) config.forge.provider."${type}";

        mergedApps = mergeRecipes "apps";
        mergedPackages = mergeRecipes "packages";
      in

      {
        forge.apps = mergedApps;
        forge.packages = mergedPackages;
      };
  };
}

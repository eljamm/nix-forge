{
  lib,
  self,
  ...
}:

let
  rootDir = self.outPath;
in

{
  # core forge modules
  imports = [
    (rootDir + "/forge/modules/forge.nix")
    (rootDir + "/forge/modules/apps")
    (rootDir + "/forge/modules/packages.nix")
    (rootDir + "/forge/packages.nix") # Generates _forge-config, _forge-options, _forge-ui
  ];

  config = {
    # Override the inputs argument for submodules with nix-forge's inputs
    # This ensures modules have access to nix-utils and import-tree
    _module.args.inputs = lib.mkForce self.inputs;

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
              # TODO: remove result from providerItem
              {
                imports = [
                  (rootDir + "/" + matchedRecipe.recipePath)
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

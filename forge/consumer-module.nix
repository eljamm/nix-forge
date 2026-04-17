{ provider }:

{
  lib,
  self,
  ...
}:

let
  rootPath = self.outPath;
in

{
  config.perSystem =
    {
      config,
      lib,
      ...
    }:

    let
      # Load recipe files from a directory using import-tree
      # Returns a list of modules, each containing a recipe config and file path
      loadRecipesFromDir =
        dir:
        if dir == null then
          [ ]
        else
          let
            # Convert string path to actual path relative to flake root
            # self.outPath gives us the flake root directory
            dirPath = rootPath + "/${dir}";

            recipeFiles = lib.pipe dirPath [
              # Use bundled import-tree from nix-forge inputs
              (provider.inputs.import-tree.withLib lib).leafs
              # Exclude non-recipe files
              (lib.filter (file: lib.hasSuffix "/recipe.nix" file))
            ];
          in
          map (
            file:
            (_: {
              imports = [ file ];
              recipePath = lib.removePrefix (rootPath + "/") file;
            })
          ) recipeFiles;

      # Load package and app recipes from configured directories
      consumerPackageRecipes = loadRecipesFromDir config.forge.recipeDirs.packages;
      consumerAppRecipes = loadRecipesFromDir config.forge.recipeDirs.apps;
    in

    {
      forge.consumer.packages = consumerPackageRecipes;
      forge.consumer.apps = consumerAppRecipes;
    };
}

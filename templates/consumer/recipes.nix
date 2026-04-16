{ provider }:

{
  lib,
  self,
  ...
}:

{
  # Import the core forge modules
  imports = [
    (provider + "/forge/modules/forge.nix")
    (provider + "/forge/modules/apps")
    (provider + "/forge/modules/packages.nix")
    (provider + "/forge/packages.nix") # Generates _forge-config, _forge-options, _forge-ui
  ];

  config = {
    # Override the inputs argument for submodules with nix-forge's inputs
    # This ensures modules have access to nix-utils and import-tree
    _module.args.inputs = lib.mkForce provider.inputs;

    perSystem =
      {
        system,
        config,
        lib,
        ...
      }:

      let
        # Helper to load recipes from a directory using import-tree
        loadRecipesO =
          dir:
          if dir == null then
            [ ]
          else
            let
              # Convert string path to actual path relative to flake root
              # self.outPath gives us the flake root directory
              dirPath = self.outPath + "/${dir}";

              recipeFiles = lib.pipe dirPath [
                # Use bundled import-tree from nix-forge inputs
                (provider.inputs.import-tree.withLib lib).leafs
                # Exclude non-recipe files
                (lib.filter (file: lib.hasSuffix "/recipe.nix" file))
                (lib.traceValSeq)
              ];
            in
            map (
              file:
              (_: {
                imports = [ file ];
                recipePath = lib.removePrefix (self.outPath + "/") file;
              })
            ) recipeFiles;

        # Load package and app recipes from configured directories
        packageRecipesO = loadRecipesO config.forge.recipeDirs.packages;
        appRecipesO = loadRecipesO config.forge.recipeDirs.apps;

        appRecipesAttrsO = lib.listToAttrs (
          lib.map (value: {
            name = value.name;
            value = value;
          }) appRecipesO
        );

        apps = lib.attrValues (
          lib.filterAttrs (name: app: lib.hasSuffix "-app" name) provider.packages.${system}
        );

        packages = lib.attrValues (
          lib.filterAttrs (
            name: pacakge: (!lib.hasSuffix "-app" name) && (pacakge ? config)
          ) provider.packages.${system}
        );

        loadRecipes =
          recipes:
          map (
            drv:
            if lib.hasAttr "${drv.name}" appRecipesAttrsO then
              (drv.extendRecipe appRecipesAttrsO.${drv.name}.config)
            else
              drv
          ) recipes;

        # load package and app recipes from forge provider
        appRecipes = lib.traceVal (appRecipesO ++ (loadRecipes apps));
        packageRecipes = packageRecipesO ++ (loadRecipes packages);
      in

      {
        forge.packages = packageRecipes;
        forge.apps = appRecipes;
      };
  };
}

{ provider }:

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
in

{
  # Import the core forge modules
  imports = [
    (provider + "/forge/modules/forge.nix")
    (provider + "/forge/modules/apps")
    (provider + "/forge/modules/packages.nix")
    (provider + "/forge/packages.nix") # Generates _forge-config, _forge-options, _forge-ui
  ];

  options.perSystem = mkPerSystemOption (
    { options, ... }:
    {
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
    }
  );

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
            let
              drvOriginal = lib.findFirst (
                x: x ? config.recipePath && x.config.recipePath == drv.config.recipePath
              ) drv appRecipesO;
            in
            if drv != drvOriginal then
              lib.trace "extended ${drv.name}" (drv.extendRecipe drvOriginal.config)
            else
              drv.extendRecipe { }
          ) recipes;

        # load package and app recipes from forge provider
        # appRecipes = loadRecipes apps;
        # packageRecipes = loadRecipes packages;

        appRecipes = apps;
        packageRecipes = packages;

        finalApps = map (
          app:
          let
            drvOriginal = lib.findFirst (x: x.name == app.name) app apps;
          in
          lib.trace "extended ${app.name}" (app.extendRecipe drvOriginal.config)
        ) apps;
      in

      {
        forge.provider.packages = packageRecipes;
        forge.provider.apps = appRecipes;

        forge.consumer.packages = packageRecipesO;
        forge.consumer.apps = appRecipesO;

        forge.apps = finalApps;
        forge.packages = packages;
      };
  };
}

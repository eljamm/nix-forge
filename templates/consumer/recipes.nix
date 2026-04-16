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
        # Constant for identifying app packages
        appSuffix = "-app";

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
        consumerPackageRecipes = loadRecipesFromDir config.forge.recipeDirs.packages;
        consumerAppRecipes = loadRecipesFromDir config.forge.recipeDirs.apps;

        # Get app and package derivations from provider
        apps = lib.pipe provider.packages.${system} [
          (lib.filterAttrs (name: app: lib.hasSuffix appSuffix name))
          (lib.attrValues)
        ];
        packages = lib.pipe provider.packages.${system} [
          (lib.filterAttrs (name: pkg: (!lib.hasSuffix appSuffix name) && (pkg ? config)))
          (lib.attrValues)
        ];

        loadConfig = attrs: map (drv: drv.config or { }) attrs;

        providerAppConfigs = loadConfig apps;
        providerPackageConfigs = loadConfig packages;

        # Merge consumer app recipes with provider apps
        finalApps = map (
          providerApp:
          let
            matchedConsumerApp = lib.findFirst (
              consumerApp: consumerApp.name == providerApp.name
            ) null config.forge.consumer.apps;
          in
          if matchedConsumerApp != null then
            {
              imports = [
                (self.outPath + "/" + matchedConsumerApp.recipePath)
                providerApp
              ];
            }
          else
            providerApp
        ) config.forge.provider.apps;
      in

      {
        forge.provider.packages = providerPackageConfigs;
        forge.provider.apps = providerAppConfigs;

        forge.consumer.packages = consumerPackageRecipes;
        forge.consumer.apps = consumerAppRecipes;

        forge.apps = finalApps;
        forge.packages = packages;
      };
  };
}

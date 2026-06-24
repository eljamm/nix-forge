{
  lib,
  pkgs,
  packages,
  ...
}:

{
  packages.fiduswriter-frontend = {
    inherit (packages.fiduswriter)
      version
      source
      description
      homePage
      license
      ;

    build.pnpmPackageBuilder = {
      enable = true;
      sourceRoot = "";
      pnpm = pkgs.pnpm_11;
      fetcherVersion = 4;
      pnpmDepsHash = "";

      packages.build = with pkgs; [
        gettext
        nodejs
        pnpmConfigHook
        pnpm_11
        python3
        rsync
      ];
    };

    build.extraAttrs = {
      env.PYTHONPATH = "${packages.fiduswriter.build.extraAttrs.passthru.pythonPath}";

      postPatch = pkgs.fiduswriter.postPatch + ''
        mkdir -p fiduswriter/.transpile
        cp --no-preserve=mode ${./pnpm-lock.yaml} fiduswriter/.transpile/pnpm-lock.yaml
        cp --no-preserve=mode ${./package.json} fiduswriter/.transpile/package.json
        cp fiduswriter/.transpile/* .
      '';

      outputs = [
        "out"
        "node_modules"
      ];

      pnpmRoot = "fiduswriter/.transpile";

      preBuild = ''
        pushd fiduswriter || true
        cp configuration-default.py configuration.py
        python manage.py setup
        python manage.py collectstatic
        popd
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r fiduswriter/static-* $out

        mkdir -p $node_modules
        cp -r fiduswriter/.transpile/node_modules $node_modules

        runHook postInstall
      '';
    };

    test.script = "";
  };
}

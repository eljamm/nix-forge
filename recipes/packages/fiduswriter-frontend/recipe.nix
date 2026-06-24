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
      inherit (packages.fiduswriter-frontend.build.extraAttrs.pnpmDeps)
        pnpm
        fetcherVersion
        ;
      pnpmDepsHash = packages.fiduswriter-frontend.build.extraAttrs.pnpmDeps.hash;

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
      pnpmRoot = "fiduswriter/.transpile";
      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (pkgs.fiduswriter)
          pname
          version
          src
          postPatch
          ;
        pnpm = pkgs.pnpm_11;
        fetcherVersion = 4;
        hash = "sha256-8JqolPCb9HtfCIgRfM5a3BGozh4alYmEWuWSBUykAZg=";
      };

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

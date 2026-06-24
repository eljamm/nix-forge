{
  lib,
  pkgs,
  packages,
  config,
  ...
}:

let
  modulesPath = ../../../nixpkgs/pkgs/development/python-modules;

  django-avatar = pkgs.python3Packages.callPackage (modulesPath + "/django-avatar") { };
  django-js-error-hook = pkgs.python3Packages.callPackage (modulesPath + "/django-js-error-hook") { };
  django-loginas = pkgs.python3Packages.callPackage (modulesPath + "/django-loginas") { };
  django-npm-mjs = pkgs.python3Packages.callPackage (modulesPath + "/django-npm-mjs") { };
  servestatic = pkgs.python3Packages.callPackage (modulesPath + "/servestatic") { };
in

{
  packages.fiduswriter = {
    version = "4.1.10";
    description = "Online collaborative editor for academics.";
    homePage = "https://github.com/fiduswriter/fiduswriter";
    mainProgram = "fiduswriter-start";
    license = lib.licenses.agpl3Only;

    source.git = "github:fiduswriter/fiduswriter/v4.1.10";
    source.hash = "sha256-NkFJehSgwYwYUZaznZW63KEXR1wTf+Hpa+8ZM71aZ84=";

    build.pythonAppBuilder = {
      enable = true;
      packages.build-system = with pkgs.python3Packages; [
        babel
        setuptools
      ];
      packages.build = [
        pkgs.gettext
        pkgs.makeWrapper
      ];
      packages.dependencies =
        with pkgs.python3Packages;
        [
          autobahn
          bleach
          channels
          django
          django-allauth
          django-axes
          django-otp
          granian
          httpx
          httpx-ws
          pillow
          prosemirror
          pyotp
          python-magic
          qrcode
          uvloop
          watchdog
        ]
        ++ [
          servestatic
          django-avatar
          django-npm-mjs
          django-js-error-hook
          django-loginas
        ];
      importsCheck = [ "fiduswriter" ];
      relaxDeps = [
        "django"
        "granian"
        "httpx-ws"
        "pyotp"
      ];
    };

    build.extraAttrs = {
      passthru = {
        pythonPath = pkgs.python3Packages.makePythonPath packages.fiduswriter.build.pythonAppBuilder.packages.dependencies;
      };

      __structuredAttrs = true;

      dontCheckRuntimeDeps = true;

      postPatch = ''
        substituteInPlace pyproject.toml \
          --replace-fail "setuptools>=82.0.1" "setuptools"
      '';

      env.FIDUS_OUT_DIR = "${placeholder "out"}/${pkgs.python3.sitePackages}";
      env.PYTHONPATH = config.packages.fiduswriter.build.extraAttrs.passthru.pythonPath;

      makeWrapperArgs = [
        "--chdir"
        "${placeholder "out"}/${pkgs.python3.sitePackages}/fiduswriter"

        "--set"
        "STATIC_ROOT"
        "${packages.fiduswriter-frontend}/static-collected"

        "--prefix"
        "PYTHONPATH"
        ":"
        "${config.packages.fiduswriter.build.extraAttrs.passthru.pythonPath}:${placeholder "out"}/${pkgs.python3.sitePackages}"
      ];

      postFixup = ''
        mkdir -p $out/bin

        cp -r ${packages.fiduswriter-frontend}/static-* "$FIDUS_OUT_DIR/fiduswriter"

        makeWrapper ${lib.getExe pkgs.python3Packages.granian} $out/bin/granian \
          "''${makeWrapperArgs[@]}"

        makeWrapper ${lib.getExe pkgs.python3Packages.granian} $out/bin/fiduswriter-start \
          --add-flags '\
            --interface asgi \
            --host ''${GRANIAN_HOST:-0.0.0.0} \
            --port ''${GRANIAN_PORT:-8000} \
            --access-log \
            fiduswriter.asgi:application \
          ' \
          "''${makeWrapperArgs[@]}"
      '';
    };

    test.script = ''
      python -c "import fiduswriter; print('import ok')"
    '';
  };
}

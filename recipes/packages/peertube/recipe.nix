{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "peertube";
  version = "8.1.5";
  description = "Free software to take back control of your videos.";
  homePage = "https://joinpeertube.org/";
  license = lib.licenses.agpl3Plus;

  source = {
    git = "github:Chocobozzz/PeerTube/v8.1.5";
    hash = "sha256-vLKjTn8tdHb/DUHj/w3ovXmRNzD8CMSKCaPleW+i7Tc=";
  };

  build.standardBuilder = {
    enable = true;
    packages = {
      build = [
        pkgs.brotli
        pkgs.fd
        pkgs.jq
        pkgs.dart-sass
        pkgs.which
        pkgs.pnpmConfigHook
        pkgs.pnpm_10
      ];
      run = [
        pkgs.nodejs_24
      ];
    };
  };

  build.extraAttrs =
    let
      finalAttrs.pname = "peertube";
      finalAttrs.version = "8.1.5";
      finalAttrs.src = pkgs.fetchFromGitHub {
        owner = "Chocobozzz";
        repo = "PeerTube";
        tag = "v${finalAttrs.version}";
        hash = "sha256-vLKjTn8tdHb/DUHj/w3ovXmRNzD8CMSKCaPleW+i7Tc=";
      };
    in
    {
      outputs = [
        "out"
        "cli"
        "runner"
      ];

      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs) pname version src;
        pnpm = pkgs.pnpm_10;
        fetcherVersion = 3;
        hash = "sha256-gvjk4OmKR6W/nllUCSaiX/lVXJSac9r04xr7fNiBftI=";
      };

      preBuild = ''
        # force sass-embedded to use our own sass instead of the bundled one
        for dep in node_modules/.pnpm/sass-embedded@*; do
          substituteInPlace $dep/node_modules/sass-embedded/dist/lib/src/compiler-path.js \
            --replace-fail \
              'compilerCommand = (() => {' \
              'compilerCommand = (() => { return ["${lib.getExe pkgs.dart-sass}"];'
        done
      '';

      buildPhase = ''
        runHook preBuild

        export HOME=$PWD

        # Build PeerTube server
        npm run build:server

        # Build PeerTube client
        npm run build:client

        # Build PeerTube cli
        npm run build:peertube-cli
        patchShebangs ~/apps/peertube-cli/dist/peertube.mjs

        # Build PeerTube runner
        npm run build:peertube-runner
        patchShebangs ~/apps/peertube-runner/dist/peertube-runner.mjs

        # Clean up declaration files
        find \
          ~/dist/ \
          ~/packages/core-utils/dist/ \
          ~/packages/ffmpeg/dist/ \
          ~/packages/models/dist/ \
          ~/packages/node-utils/dist/ \
          ~/packages/server-commands/dist/ \
          ~/packages/transcription/dist/ \
          ~/packages/typescript-utils/dist/ \
          \( -name '*.d.ts' -o -name '*.d.ts.map' \) -type f -delete

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/dist
        mv ~/dist $out
        mv ~/node_modules $out/node_modules

        mkdir $out/client
        mv ~/client/{dist,node_modules,package.json} $out/client

        mkdir -p $out/packages/{core-utils,ffmpeg,models,node-utils,server-commands,transcription,typescript-utils}
        mv ~/packages/core-utils/{dist,package.json} $out/packages/core-utils
        mv ~/packages/ffmpeg/{dist,package.json} $out/packages/ffmpeg
        mv ~/packages/models/{dist,package.json} $out/packages/models
        mv ~/packages/node-utils/{dist,package.json} $out/packages/node-utils
        mv ~/packages/server-commands/{dist,package.json} $out/packages/server-commands
        mv ~/packages/transcription/{dist,package.json} $out/packages/transcription
        mv ~/packages/typescript-utils/{dist,package.json} $out/packages/typescript-utils
        mv ~/{config,support,CREDITS.md,FAQ.md,LICENSE,README.md,package.json,pnpm-lock.yaml} $out

        # Remove broken symlinks in node_modules from workspace packages that aren't needed
        rm $out/node_modules/.pnpm/node_modules/@peertube/{peertube-cli,peertube-runner,peertube-server,peertube-transcription-devtools,peertube-types-generator,tests,player}
        rm $out/client/node_modules/@peertube/player

        mkdir -p $cli/bin
        mv ~/apps/peertube-cli/{dist,node_modules,package.json} $cli
        ln -s $cli/dist/peertube.mjs $cli/bin/peertube-cli

        mkdir -p $runner/bin
        mv ~/apps/peertube-runner/{dist,node_modules,package.json} $runner
        ln -s $runner/dist/peertube-runner.mjs $runner/bin/peertube-runner

        # Create static gzip and brotli files
        fd -e css -e eot -e html -e js -e json -e svg -e webmanifest -e xlf \
          --type file --search-path $out/client/dist --threads $NIX_BUILD_CORES \
          --exec gzip -9 -n -c {} > {}.gz \;\
          --exec brotli --best -f {} -o {}.br

        runHook postInstall
      '';
    };

  test.script = ''
    peertube --help 2>&1 | grep -i "peertube"
  '';
}

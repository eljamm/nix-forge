{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "peertube-app";
  displayName = "PeerTube";
  description = "Decentralized video hosting platform.";
  usage = ''
    PeerTube is a free, decentralized video hosting platform.

    **Access the web interface:**
    - Open http://localhost:9000 in your browser

    **Create an administrator account:**
    ```bash
    nix shell .#peertube-app
    peertube create-admin-account --host localhost:9000 --username root --password <password>
    ```

    _Available in: container, nixos._
  '';

  links = {
    website = "https://joinpeertube.org/";
    source = "https://github.com/Chocobozzz/PeerTube";
  };

  services = {
    components.peertube = {
      command = pkgs.mypkgs.peertube;
      environment = {
        NODE_ENV = "production";
        NODE_CONFIG = builtins.toJSON {
          listen = {
            hostname = "0.0.0.0";
            port = 9000;
          };
          database = {
            hostname = "localhost";
            port = 5432;
            suffix = "peertube";
            username = "peertube";
            password = "peertube";
          };
          storage = {
            tmp = "/var/lib/peertube/tmp";
            avatars = "/var/lib/peertube/avatars";
            videos = "/var/lib/peertube/videos";
            streaming_playlists = "/var/lib/peertube/streaming-playlists";
            redundancy = "/var/lib/peertube/redundancy";
            logs = "/var/lib/peertube/logs";
            previews = "/var/lib/peertube/previews";
            thumbnails = "/var/lib/peertube/thumbnails";
            torrents = "/var/lib/peertube/torrents";
            captions = "/var/lib/peertube/captions";
            cache = "/var/lib/peertube/cache";
          };
        };
      };
      preStart = ''
        mkdir -p /var/lib/peertube/{tmp,avatars,videos,streaming-playlists,redundancy,logs,previews,thumbnails,torrents,captions,cache}
      '';
    };

    runtimes = {
      container = {
        enable = true;
        setup =
          # bash
          ''
            # Create storage directories
            mkdir -p /var/lib/peertube/{tmp,avatars,videos,streaming-playlists,redundancy,logs,previews,thumbnails,torrents,captions,cache}
          '';
        packages = with pkgs; [
          bash
          coreutils
          mypkgs.peertube
        ];
        extraConfig = {
          Cmd = [ "peertube" ];
          Env = [
            "NODE_ENV=production"
            "PORT=9000"
          ];
          ExposedPorts = {
            "9000/tcp" = { };
          };
          WorkingDir = "/var/lib/peertube";
        };
      };

      nixos = {
        enable = true;
        packages = with pkgs; [
          mypkgs.peertube
        ];
        extraConfig = {
          services.postgresql = {
            enable = true;
            enableTCPIP = true;
            ensureDatabases = [ "peertube" ];
            ensureUsers = [
              {
                name = "peertube";
                ensureDBOwnership = true;
              }
            ];
            authentication = ''
              local all all trust
              host all all 127.0.0.1/32 trust
            '';
          };
        };
        vm.forwardPorts = [
          "9000:9000"
        ];
      };
    };
  };

  programs = {
    packages = with pkgs; [
      mypkgs.peertube
      curl
    ];

    runtimes.shell = {
      enable = true;
    };
  };

  test = {
    packages = with pkgs; [
      curl
    ];

    script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

      # Web UI accessible
      $curl -s localhost:9000 | grep -i "peertube"
    '';
  };
}

{
  pkgs,
  ...
}:

{
  apps.tau = {
    displayName = "Tau";
    description = "Web radio streaming system.";

    usage = ''
      This app provides both the _tau-tower_ server and the _tau-radio_ client.

      #### Tau Tower
      Service for broadcasting audio to clients.

      Ports
      - Listen: 3001
      - Broadcast: 3002


      #### Tau Radio
      Client CLI for capturing audio from your device and streaming it to _tau-tower_.

      Usage:

      ```
      tau-radio --username <user> --password <pass> --ip <server-ip> --port <server-port>
      ```

    '';

    links = {
      source = "https://github.com/tau-org";
    };

    ngi.grants = {
      Core = [
        "Tau"
      ];
    };

    programs = {
      packages = [
        pkgs.tau-radio
        pkgs.tau-tower
      ];
      runtimes.shell = {
        enable = true;
      };
    };

    services = {
      components.tau-tower = {
        command = pkgs.tau-tower;
        configData = {
          "tau/tower.toml" = {
            source = ./config-tower.toml;
            path = "tau/tower.toml";
          };
          "tau/config.toml" = {
            source = ./config-radio.toml;
            path = "tau/config.toml";
          };
        };
        ports = [
          "3001:3001"
          "3002:3002"
        ];
        preStart = ''
          echo "Installing configuration files ..."
          install -D ''$XDG_CONFIG_HOME/tau/config.toml /etc/tau/config.toml
        '';
      };

      runtimes = {
        container = {
          enable = true;
          components.tau-tower.packages = [
            pkgs.tau-tower
            pkgs.tau-radio
          ];
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.tau-tower
            pkgs.tau-radio
          ];
          nixosConfig = {
            boot.initrd.availableKernelModules = [ "virtio_snd" ];
            boot.kernelModules = [
              "virtio_snd"
              "snd_hda_intel"
            ];

            users.users.pipewire = {
              extraGroups = [ "audio" ];
            };

            environment.systemPackages = with pkgs; [
              sox
            ];

            security.rtkit.enable = true;
            services.pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
              jack.enable = true;

              # not recommended in a normal setup, but is required for pipewire to work in the test
              systemWide = true;

              wireplumber.enable = true;
            };

            virtualisation.qemu.options = [
              # enable dummy audio
              "-audiodev none,id=my_audiodev"
              "-device intel-hda -device hda-duplex,audiodev=my_audiodev"
            ];
          };
        };
      };
    };

    test.services.script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

      $curl localhost:3002 | grep "Audio Stream"
    '';
  };
}

{
  pkgs,
  ...
}:

{
  apps.padne = {
    displayName = "Padne";
    description = "KiCad-focused Power Delivery Network Simulator";
    usage = ''
      Padne is a KiCad-native power delivery network analysis tool.

      It uses the finite element method in order to simulate the voltage drop
      induced by DC currents on printed circuit boards.

      This allows easy identification of resistive bottlenecks, design of high
      current distribution networks or implementing complex heating elements.

      #### Basic Usage

      ```bash
      ```
    '';

    links = {
      website = "https://padne.atx.name/master/index.html";
      source = "https://github.com/atx/padne";
      docs = "https://padne.atx.name/master/index.html";
    };

    ngi.grants = {
      Commons = [
        "Padne"
      ];
    };

    programs = {
      mainPackage = pkgs.padne;
      packages = with pkgs; [
        padne
        (python3.withPackages (ps: [
          pkgs.padne
        ]))
      ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };
  };
}

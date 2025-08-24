{
  config,
  lib,
  pkgs,
  ...
}: {
  home.shellAliases = {
    lg = "lazygit";
  };
  programs.lazygit = {
    enable = true;
    settings = {
      gui = fromYAML (pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "lazygit";
          rev = "d3c95a67ea3f778f7705d8ef814f87ac5213436d";
          sha256 = "01vhir6243k9wfvlgadv7wsc2s9yb92l67piqsl1dm6kwlhshr3g";
        }
        + "/themes/mocha/blue.yml");
      # gui = fromYAML (
      #   pkgs.catppuccin + "/lazygit/themes/blue.yml"
      # );
      git = {
        overrideGpg = true;
      };
    };
  };
}

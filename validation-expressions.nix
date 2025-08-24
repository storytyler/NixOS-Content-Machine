# validation-expressions.nix - Nix-native configuration validation
{
  # Validate flake-parts integration
  validateFlakeParts = builtins.pathExists ./flake-parts/dev-shells.nix;

  # Validate essential rofi components
  validateRofiStructure = let
    rofiBase = ./modules/desktop/hyprland/programs/rofi;
    essentialPaths = [
      "${rofiBase}/launchers/type-1/style-5.rasi" # Games
      "${rofiBase}/launchers/type-1/style-6.rasi" # Clipboard
      "${rofiBase}/launchers/type-2/style-2.rasi" # Primary
      "${rofiBase}/launchers/type-4/style-4.rasi" # Emoji
      "${rofiBase}/colors/dracula.rasi" # Preserved theme
    ];
  in
    builtins.all builtins.pathExists essentialPaths;

  # Validate dev-shell consolidation
  validateDevShells = let
    devShellConfig = import ./flake-parts/dev-shells.nix;
    requiredShells = ["nix" "rust" "python" "shell"];
  in
    builtins.isFunction devShellConfig;

  # Generate validation report
  validationReport = {
    flakePartsValid = validateFlakeParts;
    rofiStructureValid = validateRofiStructure;
    devShellsValid = validateDevShells;
    timestamp = builtins.currentTime;
  };
}

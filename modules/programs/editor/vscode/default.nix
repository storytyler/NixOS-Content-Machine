# /home/player00/NixOS/modules/programs/editor/vscode.nix
{
  lib,
  pkgs,
  ...
}: let
  # Import Dracula theme/settings relative to this module
  themeSettings = import ./settings-dracula.nix {inherit lib pkgs;}
    .programs.vscode.profiles.default.userSettings;
in {
  programs.vscode = {
    enable = true;
    mutable = true; # allows VSCode to write settings directly
    package = pkgs.vscode;

    profiles.default = {
      # Extensions
      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        eamodio.gitlens
        github.vscode-github-actions
        yzhang.markdown-all-in-one
        tamasfe.even-better-toml
        rust-lang.rust-analyzer
        ms-vscode.cpptools
        ms-vscode.cmake-tools
        ms-vscode.makefile-tools
        ziglang.vscode-zig
        ms-python.python
        dracula-theme.theme-dracula
      ];

      # Keybindings
      keybindings = [
        {
          key = "ctrl+q";
          command = "editor.action.commentLine";
          when = "editorTextFocus && !editorReadonly";
        }
        {
          key = "ctrl+s";
          command = "workbench.action.files.saveFiles";
        }
      ];

      # Merge theme settings with any extra non-overlapping settings
      userSettings = lib.recursiveUpdate themeSettings {
        # extra settings from your previous main module
        "editor.formatOnType" = false;
        "editor.renderControlCharacters" = false;
        "editor.scrollbar.horizontalScrollbarSize" = 2;
        "editor.scrollbar.verticalScrollbarSize" = 2;
        "editor.minimap.enabled" = false;
        # add any additional non-overlapping keys here
      };

      # Optional: keep commented-out settings for reference
      disabledSettings = {
        # "extensions.autoUpdate" = false;
        # "workbench.activityBar.location" = "hidden";
        # "workbench.editor.showTabs" = "single";
        # "workbench.statusBar.visible" = false;
        # "ms-dotnettools.csharp" = true;
        # "pkief.material-icon-theme" = true;
        # "equinusocio.vsc-material-theme" = true;
        # "asvetliakov.vscode-neovim" = true;
        # "vscodevim.vim" = true;
        # "jnoortheen.nix-ide" = true;
        # "redhat.vscode-yaml" = true;
        # "vadimcn.vscode-lldb" = true;
        # "catppuccin.catppuccin-vsc" = true;
        # "catppuccin.catppuccin-vsc-icons" = true;
      };
    };
  };
}

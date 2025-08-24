{
  lib,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    extensions = with pkgs.vscode-extensions; [
      ms-vscode.cpptools
      rust-lang.rust-analyzer
    ];
  };
}

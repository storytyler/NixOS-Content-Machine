rec {
  default = {
    path = ./empty;
    description = "Empty development environment";
  };
  c-cpp = {
    path = ./c-cpp;
    description = "C/C++ development environment";
  };
  empty = {
    path = ./empty;
    description = "Empty dev template that you can customize at will";
  };
  go = {
    path = ./go;
    description = "Go (Golang) development environment";
  };
  haskell = {
    path = ./haskell;
    description = "Haskell development environment";
  };
  jupyter = {
    path = ./jupyter;
    description = "Jupyter development environment";
  };
  nix = {
    path = ./nix;
    description = "Nix development environment";
  };
  node = {
    path = ./node;
    description = "Node.js development environment";
  };
  odin = {
    path = ./odin;
    description = "Odin development environment";
  };
  python = {
    path = ./python;
    description = "Python development environment";
  };
  rust = {
    path = ./rust;
    description = "Rust development environment";
  };
  rust-toolchain = {
    path = ./rust-toolchain;
    description = "Rust development environment with Rust version defined by a rust-toolchain.toml file";
  };
  shell = {
    path = ./shell;
    description = "Shell script development environment";
  };

  # Aliases
  c = c-cpp;
  cpp = c-cpp;
  rt = rust-toolchain;
}

{
  description = "Pufferpanel 3.0.9 for nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    packages."${system}".default = nixpkgs.lib.customisation.callPackageWith pkgs ./default.nix {};
  };
}

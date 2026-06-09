{
  description = "Pufferpanel 3 for nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
  in
  {
    packages.x86_64-linux.default = nixpkgs.lib.customisation.callPackageWith pkgs ./pufferpanel.nix {};
  };
}

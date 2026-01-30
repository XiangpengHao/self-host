{
  description = "Declarative self-hosted infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    related-work.url = "github:XiangpengHao/related-work";

    nix-moltbot = {
      url = "github:moltbot/nix-moltbot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, ... }@inputs:
    let
      # Helper to generate NixOS configurations
      mkHost = { hostname, system ? "x86_64-linux" }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs hostname; };
          modules = [
            sops-nix.nixosModules.sops
            ./hosts/${hostname}/configuration.nix
            ./modules/common.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        nixnas = mkHost { hostname = "nixnas"; };
        # Add more hosts here:
        # hostB = mkHost { hostname = "hostB"; };
      };
    };
}

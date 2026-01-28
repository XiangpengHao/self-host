{
  description = "Declarative self-hosted infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-clawdbot.url = "github:clawdbot/nix-clawdbot";

    related-work.url = "github:XiangpengHao/related-work";
  };

  outputs = { self, nixpkgs, sops-nix, home-manager, nix-clawdbot, ... }@inputs:
    let
      # Helper to generate NixOS configurations
      mkHost = { hostname, system ? "x86_64-linux" }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs hostname; };
          modules = [
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              nixpkgs.overlays = [ nix-clawdbot.overlays.default ];
            }
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

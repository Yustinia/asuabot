{
  description = "Asuabot";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      glua-api-snippets = pkgs.fetchzip {
        url = "https://github.com/luttje/glua-api-snippets/releases/download/2026-09-28_17-43-07/2026-09-28_17-43-07.lua.zip";
        stripRoot = false;
        hash = "sha256-pthQos21tOyGptZy+cG3cidhH4Wcfte3JOVD2zMM4kA=";
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          lua
          stylua # fmt
          lua-language-server # lsp
        ];

        shellHook = ''
          ln -sfn "${glua-api-snippets}" ./.glua-api
        '';
      };
    };
}

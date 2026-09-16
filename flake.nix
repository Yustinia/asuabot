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
        url = "https://github.com/luttje/glua-api-snippets/releases/download/2026-08-31_17-51-30/2026-08-31_17-51-30.lua.zip";
        stripRoot = false;
        hash = "sha256-YSI0dq57x22v8CYLV0ZJ/IPIN2A158DmtKPb/6WMm1M=";
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

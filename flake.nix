{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    freckle.url = "github:freckle/flakes?dir=main";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      nixpkgsArgs = { inherit system; config = { }; };
      nixpkgs = import inputs.nixpkgs nixpkgsArgs;
      freckle = inputs.freckle.packages.${system};
      freckleLib = inputs.freckle.lib.${system};
    in
    rec {
      packages = {
        cabal = nixpkgs.cabal-install;

        fourmolu = freckle.fourmolu-0-13-x;

        ghc = freckleLib.haskellBundle {
          ghcVersion = "ghc-9-6-3";
          enableHLS = true;
          packageSelection = p: [
            p.aeson
            p.base64-bytestring
            p.blaze-builder
            p.bytestring
            p.case-insensitive
            p.cryptonite
            p.exceptions
            p.http-client
            p.http-types
            p.memory
            p.mtl
            p.time
            p.text
            p.transformers
            p.network-uri
            p.network
          ];
        };

        hlint =
          nixpkgs.haskell.lib.justStaticExecutables
            nixpkgs.hlint;

        hiedb =
          nixpkgs.haskell.lib.justStaticExecutables
            nixpkgs.haskell.haskellPackages.hiedb;

        stack = nixpkgs.writeShellApplication {
          name = "stack";
          text = ''
            ${nixpkgs.stack}/bin/stack --system-ghc --no-nix "$@"
          '';
        }
        ;
      };

      devShells.default = nixpkgs.mkShell {
        buildInputs = with (nixpkgs); [
          pcre
          pcre.dev
          zlib
          zlib.dev
        ];

        nativeBuildInputs = with (packages); [
          cabal
          fourmolu
          ghc
          hlint
          stack
        ];

        shellHook = ''
          export STACK_YAML=stack.yaml
        '';
      };
    });
}

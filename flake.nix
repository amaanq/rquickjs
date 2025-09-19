{
  description = "rquickjs - high level bindings for the QuickJS-NG JavaScript engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      eachSystem = lib.genAttrs systems;
      pkgsFor = inputs.nixpkgs.legacyPackages;
      fenixFor = inputs.fenix.packages;
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "rquickjs";
            version = "0.6.3";
            src = pkgs.lib.cleanSource ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            buildInputs = with pkgs; [
              pkg-config
              openssl
            ];

            nativeBuildInputs = with pkgs; [
              pkg-config
              clang
              libclang
            ];

            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

            meta = {
              description = "High level bindings for the QuickJS-NG JavaScript engine";
              license = pkgs.lib.licenses.mit;
              maintainers = [ ];
              platforms = pkgs.lib.platforms.all;
            };
          };
        }
      );

      devShells = eachSystem (
        system:
        let
          pkgs = pkgsFor.${system};
          fenix = fenixFor.${system};

          rust-toolchain = fenix.combine [
            (fenix.complete.withComponents [
              "cargo"
              "clippy"
              "rust-src"
              "rustc"
              "rustfmt"
            ])
            fenix.targets.armv7-unknown-linux-gnueabihf.latest.rust-std
            fenix.targets.i686-unknown-linux-gnu.latest.rust-std
            fenix.targets.powerpc64-unknown-linux-gnu.latest.rust-std
            fenix.targets.aarch64-pc-windows-gnullvm.latest.rust-std
            fenix.targets.i686-pc-windows-gnu.latest.rust-std
          ];
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              rust-toolchain
              pkgs.cargo-zigbuild

              pkgs.pkg-config
              pkgs.openssl

              pkgs.stdenv.cc.cc.lib
              pkgs.clang
              pkgs.libclang
            ];

            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            BINDGEN_EXTRA_CLANG_ARGS = "-I${pkgs.glibc.dev}/include";
          };
        }
      );
    };
}

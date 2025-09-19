{
  description = "rquickjs - high level bindings for the QuickJS-NG JavaScript engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickjs = {
      url = "github:quickjs-ng/quickjs/2d680a96c12dda24bc82d213850dd5a1b03feb2d";
      flake = false;
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
          cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        in
        {
          default =
            let
              srcWithSubmodule = pkgs.runCommand "rquickjs-src" { } ''
                cp -r ${./.} $out
                chmod -R +w $out
                mkdir -p $out/sys/quickjs
                cp -r ${inputs.quickjs}/* $out/sys/quickjs/
              '';
            in
            pkgs.rustPlatform.buildRustPackage {
              pname = "rquickjs";
              version = cargoToml.package.version;
              src = srcWithSubmodule;

              cargoLock.lockFile = ./Cargo.lock;

              nativeBuildInputs = [
                pkgs.rustPlatform.bindgenHook
                pkgs.clang
              ];

              doCheck = true;
              checkPhase = ''
                runHook preCheck
                cargo test --workspace --features full-async,bindgen
                runHook postCheck
              '';

              env.LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

              meta = {
                description = "High level bindings for the QuickJS-NG JavaScript engine";
                license = lib.licenses.mit;
                maintainers = [ lib.maintainers.amaanq ];
                platforms = lib.platforms.all;
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

            env.LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          };
        }
      );
    };
}

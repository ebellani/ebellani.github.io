{
  description = "eduardo's website";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      devenv,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

          inherit (pkgs)
            emacs-nox
            emacsPackagesFor
            gnumake
            hugo
            stdenv
            mkShell
            ;

          customEmacs = (emacsPackagesFor emacs-nox).emacsWithPackages
            (epkgs: with epkgs.melpaPackages; [
              ox-hugo
              citeproc
            ]
            ++ (with epkgs.elpaPackages; [
              org
            ]));

          pgPort = 54321;
          pgHostname = "127.0.0.1";
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
          };

          packages = {
            default = stdenv.mkDerivation {
              name = "website";
              src = ./.;
              buildInputs = [ customEmacs hugo ];

              buildPhase = ''
                make public
              '';

              installPhase = ''
                mkdir -p $out
                cp -r public/* $out
              '';
            };

            devenv-up = self.devShells.${system}.postgres.config.procfileScript;
            devenv-test = self.devShells.${system}.postgres.config.test;
          };

          devShells = {
            default = mkShell {
              buildInputs = [
                customEmacs
                gnumake
                hugo
              ];
            };

            postgres = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                (
                  { pkgs, lib, ... }:
                  {
                    packages = with pkgs; [
                      bash
                      gnumake
                      postgresql_18
                      postgresql18Packages.pg_partman
                      postgresql18Packages.pg_cron
                      postgresql18Packages.temporal_tables
                      postgresql18Packages.pg_ivm                      
                    ];

                    enterShell = ''
                      echo "Starting Development Environment with PostgreSQL..."
                    '';

                    enterTest = ''
                      echo "Starting Test Environment..."
                      pg_isready -h ${pgHostname} -p ${toString pgPort}
                    '';

                    services.postgres = {
                      enable = true;
                      package = pkgs.postgresql_18;
                      port = pgPort;
                      extensions = ext: [
                        ext.pgtap
                        ext.temporal_tables
                        ext.pg_partman
                        ext.pg_cron
                        ext.pg_ivm
                      ];
                      initdbArgs = [
                        "--locale=C"
                        "--encoding=UTF8"
                      ];
                      settings = {
                        shared_preload_libraries = lib.concatStringsSep "," [
                          "pg_stat_statements"
                          "auto_explain"
                          "temporal_tables"
                          "pg_cron"                          
                          "pg_ivm"
                        ];
                        "auto_explain.log_min_duration" = 150;
                        "auto_explain.log_analyze" = true;
                        log_min_duration_statement = 0;
                        log_statement = "all";
                        compute_query_id = "on";
                        "pg_stat_statements.max" = 10000;
                        "pg_stat_statements.track" = "all";
                      };
                      initialDatabases = [
                        {
                          name = "blog";
                          user = "admin";
                          pass = "admin";
                        }
                      ];
                      listen_addresses = pgHostname;
                      initialScript = ''
                        ALTER USER admin CREATEROLE SUPERUSER;
                      '';
                    };
                  }
                )
              ];
            };
          };

          formatter = treefmtEval.config.build.wrapper;
        };

      flake = { };
    };
}




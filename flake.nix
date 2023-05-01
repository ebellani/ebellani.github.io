{
  description = "eduardo's website";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
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
            org-roam
          ]
          ++ (with epkgs.elpaPackages; [
            org
          ]));
      in
      {
        packages.default = stdenv.mkDerivation {
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

        devShells.default = mkShell {
          buildInputs = [
            customEmacs
            gnumake
            hugo
          ];
        };
      });
}

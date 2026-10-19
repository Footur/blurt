{
  description = "Blurt GNOME Shell extension and development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        extensionUuid = "blurt@quantiusbenignus.local";

        blurtExtension = pkgs.stdenv.mkDerivation rec {
          pname = "blurt";
          version = "9";
          src = ./.;

          nativeBuildInputs = [ pkgs.glib ];

          buildPhase = ''
            runHook preBuild
            if [ -d schemas ]; then
              glib-compile-schemas --strict schemas
            fi
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/share/gnome-shell/extensions/${extensionUuid}"
            cp -a ./. "$out/share/gnome-shell/extensions/${extensionUuid}/"
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Input speech to text into any GNOME window with a text input field";
            homepage = "https://github.com/QuantiusBenignus/blurt";
            license = licenses.gpl3Only;
            platforms = platforms.linux;
            maintainers = [ ];
          };
        };
      in
      {
        packages.default = blurtExtension;

        devShells.default = pkgs.mkShell {
          name = "blurt-dev";

          packages = with pkgs; [
            bash
            coreutils
            curl
            git
            glib
            jq
            sox
            wl-clipboard
          ];

          shellHook = ''
            echo "Blurt development shell ready."
            echo "To install the extension manually:"
            echo "  mkdir -p ~/.local/share/gnome-shell/extensions/${extensionUuid}"
            echo "  cp -a ${blurtExtension}/share/gnome-shell/extensions/${extensionUuid}/ ~/.local/share/gnome-shell/extensions/"
            echo "  gnome-extensions enable ${extensionUuid}"
          '';
        };
      })
    // {
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.blurt;
        in
        {
          options.programs.blurt = {
            enable = lib.mkEnableOption "Enable the Blurt GNOME shell extension";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              description = "Package to install for Blurt.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
          };
        };
    };
}

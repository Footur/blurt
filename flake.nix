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
        pname = "blurt";
        version = "9";

        blurtPackage = pkgs.stdenvNoCC.mkDerivation {
          inherit pname version;
          src = ./.;

          dontBuild = true;

          installPhase = ''
            mkdir -p "$out/share/gnome-shell/extensions/blurt@quantiusbenignus.local"
            cp -a ./. "$out/share/gnome-shell/extensions/blurt@quantiusbenignus.local/"
            chmod -R u+rwX "$out/share/gnome-shell/extensions/blurt@quantiusbenignus.local"
          '';

          meta = with pkgs.lib; {
            description = "Speech-to-text GNOME Shell extension for Linux";
            homepage = "https://github.com/QuantiusBenignus/blurt";
            license = licenses.gpl3Only;
            platforms = platforms.linux;
            mainProgram = "wsi";
            maintainers = [ ];
          };
        };
      in
      {
        packages.default = blurtPackage;

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
            xsel
          ];

          shellHook = ''
            echo "Blurt development shell ready."
            echo "For a manual GNOME install: gnome-extensions install --force ${blurtPackage}/share/gnome-shell/extensions/blurt@quantiusbenignus.local"
            echo "Then enable it with: gnome-extensions enable blurt@quantiusbenignus.local"
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
            enable = lib.mkEnableOption "Install the Blurt GNOME Shell extension package";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              description = "The Blurt package to install on the system.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
          };
        };
    };
}

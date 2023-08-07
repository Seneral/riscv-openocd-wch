{
  description = "Fork of OpenOCD with support for WCH parts.";

  inputs.nixpkgs.url = "nixpkgs/release-23.05";

  outputs = { self, nixpkgs }:
    let
      # System types to support.
      supportedSystems =
      [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in
    {
      # A Nixpkgs overlay.
      overlay = self: super: {
        wch-openocd = super.callPackage ./default.nix { };
      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) wch-openocd;
        });

      # Add the wrapper to apps for nix run.
      apps = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          wch-openocd = {
            type = "app";
            program = "${pkgs.wch-openocd}/bin/wch-openocd";
          };
        });
    };
}

{
  description = "今日休みか教えてくれる君 — Discord school/holiday notifier";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          # Haddock is useful for libraries, but adds a very large closure to this
          # small executable.  Keep the first build focused on compiling the bot.
          default = pkgs.haskell.lib.dontHaddock (
            pkgs.haskellPackages.callCabal2nix "yasumi" ./. { }
          );
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          project = self.packages.${system}.default;
        in
        {
          default = pkgs.haskellPackages.shellFor {
            packages = _: [ project ];
            buildInputs = with pkgs; [
              awscli2
              cabal-install
            ];
          };
        });
    };
}

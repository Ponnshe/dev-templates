{
  description = "Entorno de desarrollo Java + JDTLS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # El wrapper de JDTLS que tenías en configuration.nix
        jdtls-wrapped = pkgs.stdenv.mkDerivation {
          name = "jdtls-wrapped";
          buildInputs = [ pkgs.makeWrapper ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            makeWrapper ${pkgs.jdt-language-server}/bin/jdtls $out/bin/jdtls \
              --set JAVA_OPTS "-Dosgi.configuration.area=$HOME/.cache/jdtls/config_linux" \
              --set XDG_CONFIG_HOME "$HOME/.cache/jdtls" \
              --set XDG_DATA_HOME "$HOME/.cache/jdtls"
          '';
        };

        javaVersion = pkgs.jdk21;

      in {
        devShells.default = pkgs.mkShell {
          name = "java-dev-shell";

          packages = with pkgs; [
            javaVersion
            maven
            gradle
            jdtls-wrapped
          ];

          env = {
            JAVA_HOME = "${javaVersion}/lib/openjdk";
            JDTLS_HOME = "${pkgs.jdt-language-server}/share/java/jdtls/";
          };

          shellHook = ''
            echo "☕ Java Environment Loaded (JDK 21)"
          '';
        };
      });
}

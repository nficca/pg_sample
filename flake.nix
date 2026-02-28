{
  description = "pg_sample - extract sample dataset from PostgreSQL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        perlWithDeps = pkgs.perl.withPackages (ps: [
          ps.DBI
          ps.DBDPg
        ]);

        pg_sample = pkgs.stdenv.mkDerivation {
          pname = "pg_sample";
          version = "1.17";

          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          buildInputs = [ perlWithDeps ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp pg_sample $out/bin/pg_sample
            chmod +x $out/bin/pg_sample

            wrapProgram $out/bin/pg_sample \
              --set PERL5LIB "${perlWithDeps}/lib/perl5/site_perl" \
              --prefix PATH : "${pkgs.postgresql}/bin"

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Extract a small sample dataset from a larger PostgreSQL database";
            homepage = "https://github.com/mla/pg_sample";
            license = licenses.artistic1;
            maintainers = [ ];
            platforms = platforms.unix;
            mainProgram = "pg_sample";
          };
        };

        devShell = pkgs.mkShell {
          buildInputs = [
            perlWithDeps
            pkgs.postgresql
          ];
        };

      in {
        packages.default = pg_sample;
        packages.pg_sample = pg_sample;

        devShells.default = devShell;
      }
    ) // {
      overlays.default = final: prev: {
        pg_sample = self.packages.${prev.system}.default;
      };
    };
}

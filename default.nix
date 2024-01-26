{pkgs}:
pkgs.buildNimPackage {
  pname = "nimble2nix";
  version = "0.1";
  src = ./.;

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  postInstall = ''
    wrapProgram $out/bin/nimble2nix --prefix PATH : ${
      pkgs.lib.makeBinPath (with pkgs; [
        nix-prefetch-scripts
      ])
    }
  '';
}

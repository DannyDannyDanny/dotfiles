# Local bump of nixpkgs navidrome (0.61.2) to 0.62.0, ahead of the
# nixpkgs PR landing. Tracks NixOS/nixpkgs#529720 (tebriel) - identical
# patch (3 lines: version + src hash + vendorHash).
#
# Why bumped: 0.62.0 ships PR navidrome/navidrome#5411, which "Relax
# playlist visibility in inPlaylist/notInPlaylist rules" - lets a smart
# playlist owner reference their own PRIVATE playlists. Without it the
# operator silently matches no tracks for private references, which
# made `Unrated (de-duped)` retain all the dupe-losers members.
#
# REMOVE this file (and the services.navidrome.package line in
# sunken-ship.nix) once nixpkgs-unstable has 0.62.x. Check:
#   nix-instantiate --eval -E '(import <nixpkgs> {}).navidrome.version'
{
  buildGoModule,
  buildPackages,
  fetchFromGitHub,
  fetchNpmDeps,
  fetchpatch,
  lib,
  nodejs_24,
  npmHooks,
  pkg-config,
  stdenv,
  ffmpeg-headless,
  taglib,
  zlib,
  nixosTests,
  nix-update-script,
  ffmpegSupport ? true,
  versionCheckHook,
  plugins ? [ ],
}:

buildGoModule (finalAttrs: {
  pname = "navidrome";
  version = "0.62.0";

  src = fetchFromGitHub {
    owner = "navidrome";
    repo = "navidrome";
    rev = "v${finalAttrs.version}";
    hash = "sha256-pLhb2x3dGLsCk405rBVdMwazhf0EQd72VLKtlzGoJDA=";
  };

  vendorHash = "sha256-3ciCzFhJi4YTIjGbPJ2UP8mPzQe3vBgZ+Pc7Nto1LEw=";

  npmRoot = "ui";

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    sourceRoot = "${finalAttrs.src.name}/ui";
    hash = "sha256-7hy2vLCEicKzjORpJZ0mrRS8PT3GsJ8DWdvj/7SrB70=";
  };

  nativeBuildInputs = [
    buildPackages.makeWrapper
    nodejs_24
    npmHooks.npmConfigHook
    pkg-config
  ];

  runtimeInputs = plugins;

  overrideModAttrs = oldAttrs: {
    nativeBuildInputs = lib.filter (drv: drv != npmHooks.npmConfigHook) oldAttrs.nativeBuildInputs;
    preBuild = null;
  };

  buildInputs = [
    taglib
    zlib
  ];

  excludedPackages = [
    "plugins"
  ];

  ldflags = [
    "-X github.com/navidrome/navidrome/consts.gitSha=${finalAttrs.src.rev}"
    "-X github.com/navidrome/navidrome/consts.gitTag=v${finalAttrs.version}"
  ];

  env = lib.optionalAttrs stdenv.cc.isGNU {
    CGO_CFLAGS = toString [ "-Wno-return-local-addr" ];
  };

  postPatch = ''
    patchShebangs ui/bin/update-workbox.sh
  '';

  preBuild = ''
    make buildjs
  '';

  postInstall = ''
    mkdir -p $out/share/plugins/
    ${lib.concatMapStringsSep "\n" (plugin: ''
      ln -s ${plugin}/share/${plugin.pname}.ndp $out/share/plugins/
    '') plugins}
  '';

  tags = [
    "netgo"
    "sqlite_fts5"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  postFixup = lib.optionalString ffmpegSupport ''
    wrapProgram $out/bin/navidrome \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg-headless ]}
  '';

  passthru = {
    inherit plugins;
    tests.navidrome = nixosTests.navidrome;
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Music Server and Streamer compatible with Subsonic/Airsonic";
    mainProgram = "navidrome";
    homepage = "https://www.navidrome.org/";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    maintainers = with lib.maintainers; [
      aciceri
      tebriel
    ];
    broken = stdenv.hostPlatform.isDarwin;
  };
})

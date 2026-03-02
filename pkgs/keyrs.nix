{
  lib,
  rustPlatform,
  pkg-config,
  wayland,
  libxkbcommon,
  systemd,
  src,
}:

rustPlatform.buildRustPackage rec {
  pname = "keyrs";
  version = "0.2.1";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = [ pkg-config ];
  # libudev-sys expects libudev.pc; on NixOS this comes from systemd.
  buildInputs = [
    wayland
    libxkbcommon
    systemd
  ];

  cargoBuildFlags = [
    "--features"
    "pure-rust"
    "--bins"
  ];
  cargoTestFlags = [
    "--features"
    "pure-rust"
  ];

  # Install the keyrs-service shell script and companion data directories so
  # `keyrs-service` is available in PATH for service/profile management.
  # The script uses REPO_ROOT (its grandparent dir) to locate profiles/ and dist/.
  postInstall = ''
    install -Dm755 scripts/keyrs-service.sh $out/bin/keyrs-service
    cp -r profiles $out/profiles
    cp -r config.d.example $out/config.d.example
    cp -r dist $out/dist
  '';

  meta = with lib; {
    description = "Pure Rust Wayland key remapper";
    homepage = "https://github.com/higorprado/keyrs";
    license = licenses.mit;
    mainProgram = "keyrs";
    platforms = platforms.linux;
  };
}

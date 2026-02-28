{ stdenv, kernel, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "linuwu-sense";
  version = "main";

  src = fetchFromGitHub {
    owner = "higorprado";
    repo = "Linuwu-Sense";
    rev = "main";
    sha256 = "0nq5ri98h2j8ylqrwmqhdvvj9kkhjxv638qibhkhzrfx5ilwsaxx";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
    find . -name "*.ko" -exec cp {} $out/lib/modules/${kernel.modDirVersion}/extra/ \;
    runHook postInstall
  '';
}

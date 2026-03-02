{ ... }:
{
  programs.ssh = {
    enable = true;
    # Home Manager will stop injecting OpenSSH defaults automatically.
    enableDefaultConfig = false;

    # Include external SSH config files (for keys and host-specific configs)
    # This allows keeping sensitive data outside the repo
    includes = [
      # Include user's local SSH config if it exists
      "~/.ssh/config.local"
      "~/.ssh/config.d/*"
    ];

    # Explicit base defaults for all hosts.
    matchBlocks."*" = {
      compression = false;
      forwardAgent = false;
      forwardX11 = false;
      hashKnownHosts = true;
      controlMaster = "auto";
      controlPath = "~/.ssh/controlmasters/%r@%h:%p";
      controlPersist = "10m";
      extraOptions = {
        ServerAliveInterval = "60";
        ServerAliveCountMax = "3";
        KexAlgorithms = "curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256";
        MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256";
        HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519,ecdsa-sha2-nistp521-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp256";
      };
    };

  };
}

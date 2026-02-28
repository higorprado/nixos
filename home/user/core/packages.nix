# Essential CLI utilities
# wget, curl, git, unzip, file, htop, rsync, restic, openssh, ripgrep, fzf
# Note: neovim is managed by programs.neovim, vim/nano can be added here if needed
{ pkgs, ... }:
{
  programs.fzf.enable = true;

  home.packages = with pkgs; [
    # Text editors (vim and nano - neovim is managed by programs.neovim)
    vim
    nano

    # HTTP downloaders
    wget
    curl

    # Version control
    git

    # Archive extraction
    unzip

    # File type detection
    file

    # Process viewer
    htop

    # File sync/transfer
    rsync

    # Backup
    restic

    # SSH
    openssh

    # Search
    ripgrep
  ];

  imports = [
    ./monitoring.nix
  ];
}

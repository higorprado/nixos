{
  config,
  lib,
  pkgs,
  customPkgs,
  osConfig,
  ...
}:
let
  desktopProfileEnabled =
    osConfig.custom.desktop.profile == "dms"
    || osConfig.custom.desktop.profile == "dms-hyprland"
    || osConfig.custom.desktop.profile == "caelestia-hyprland"
    || osConfig.custom.desktop.profile == "noctalia";

  capitalize =
    s:
    "${lib.toUpper (builtins.substring 0 1 s)}${
      builtins.substring 1 ((builtins.stringLength s) - 1) s
    }";

  flavor = config.catppuccin.flavor;
  accent = config.catppuccin.accent;
  flavorDir = capitalize flavor;
  accentDir = capitalize accent;
  themeDir = "${customPkgs.catppuccin-zen-browser}/themes/${flavorDir}/${accentDir}";
  logoFile = "${themeDir}/zen-logo-${flavor}.svg";
in
lib.mkIf (desktopProfileEnabled && config.custom.theme.zen.enable) {
  # Official Zen Browser theme flow:
  # 1) Copy userChrome/userContent/logo from catppuccin/zen-browser
  # 2) Enable toolkit.legacyUserProfileCustomizations.stylesheets
  home.activation.syncZenCatppuccinTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zen_profiles_ini="$HOME/.config/zen/profiles.ini"
    theme_dir="${themeDir}"
    pref_line='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

    if [ ! -f "$zen_profiles_ini" ] || [ ! -d "$theme_dir" ]; then
      exit 0
    fi

    zen_profile_path="$(${pkgs.gawk}/bin/awk -F= '
      /^\[Profile/ { p=1; path=""; def=0; next }
      p && $1=="Path" { path=$2; next }
      p && $1=="Default" && $2=="1" { def=1; if (path != "") { print path; exit } }
      /^$/ { p=0 }
    ' "$zen_profiles_ini")"

    if [ -z "$zen_profile_path" ]; then
      zen_profile_path="$(${pkgs.gawk}/bin/awk -F= '/^Path=/{print $2; exit}' "$zen_profiles_ini")"
    fi

    if [ -z "$zen_profile_path" ]; then
      exit 0
    fi

    zen_profile_dir="$HOME/.config/zen/$zen_profile_path"
    zen_chrome_dir="$zen_profile_dir/chrome"
    zen_user_js="$zen_profile_dir/user.js"

    if [ ! -f "$theme_dir/userChrome.css" ] || [ ! -f "$theme_dir/userContent.css" ] || [ ! -f "${logoFile}" ]; then
      echo "warning: syncZenCatppuccinTheme: missing files in $theme_dir" >&2
      exit 0
    fi

    $DRY_RUN_CMD mkdir -p "$zen_chrome_dir"
    if ! $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "$theme_dir/userChrome.css" "$zen_chrome_dir/userChrome.css"; then
      echo "warning: syncZenCatppuccinTheme: failed to write userChrome.css" >&2
    fi
    if ! $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "$theme_dir/userContent.css" "$zen_chrome_dir/userContent.css"; then
      echo "warning: syncZenCatppuccinTheme: failed to write userContent.css" >&2
    fi
    if ! $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "${logoFile}" "$zen_chrome_dir/zen-logo.svg"; then
      echo "warning: syncZenCatppuccinTheme: failed to write zen-logo.svg" >&2
    fi

    if [ -f "$zen_user_js" ]; then
      if ${pkgs.gnugrep}/bin/grep -q '^user_pref("toolkit\.legacyUserProfileCustomizations\.stylesheets",' "$zen_user_js"; then
        if ! $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's#^user_pref("toolkit\.legacyUserProfileCustomizations\.stylesheets".*#user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);#' "$zen_user_js"; then
          echo "warning: syncZenCatppuccinTheme: failed to patch toolkit pref in user.js" >&2
        fi
      else
        if ! $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf '\n%s\n' "$pref_line" >> "$zen_user_js"; then
          echo "warning: syncZenCatppuccinTheme: failed to append toolkit pref to user.js" >&2
        fi
      fi
    else
      if ! $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf '%s\n' "$pref_line" > "$zen_user_js"; then
        echo "warning: syncZenCatppuccinTheme: failed to create user.js toolkit pref" >&2
      fi
    fi
  '';
}

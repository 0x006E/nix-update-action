#!/usr/bin/env bash
set -euo pipefail

enterFlakeFolder() {
  if [[ -n "$PATH_TO_FLAKE_DIR" ]]; then
    cd "$PATH_TO_FLAKE_DIR"
  fi
}

sanitizeInputs() {
  # remove all whitespace
  PACKAGES="${PACKAGES// /}"
  BLACKLIST="${BLACKLIST// /}"
}

determinePackages() {
  # determine packages to update
  if [[ -z "$PACKAGES" ]]; then
    PACKAGES=$(nix flake show --json | jq -r '[.packages[] | keys[]] | sort | unique |  join(",")')
  fi
}

updatePackages() {
  # update packages
  for PACKAGE in ${PACKAGES//,/ }; do
    if [[ ",$BLACKLIST," == *",$PACKAGE,"* ]]; then
        echo "Package '$PACKAGE' is blacklisted, skipping."
        continue
    fi
    echo "Updating package '$PACKAGE'."
    if nix-update --flake --commit "$PACKAGE" 1>/dev/null; then 
      echo "Package '$PACKAGE' updated successfully."
    else
      echo "Trying to use unstable updator for '$PACKAGE'."
      if nix-update --version=branch --flake --commit "$PACKAGE" 1>/dev/null; then
        echo "Package '$PACKAGE' updated successfully."
      else
        echo "Failed to update package '$PACKAGE'."
      fi 
    fi
  done
}

enterFlakeFolder
sanitizeInputs
determinePackages
updatePackages

#!/bin/sh
set -eu

# Enable unattended Swift package plugin/macro execution in Xcode Cloud.
# SwiftLint documents the misspelled key below; set both spellings for compatibility.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

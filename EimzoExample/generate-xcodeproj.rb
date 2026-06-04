#!/usr/bin/env ruby
# Generates `EimzoExample.xcodeproj` — a minimal iOS app that links the
# **published** EimzoSDK binary via Swift Package Manager.
#
# Integrators usually don't need to run this — the generated xcodeproj is
# committed to the repo and works out of the box. Re-run only when changing
# the project structure (e.g. adding a new source file).
#
#   ruby EimzoExample/generate-xcodeproj.rb
#
# After regenerating: open `EimzoExample.xcodeproj` in Xcode, pick a
# development team in Signing & Capabilities, hit Run.

require 'xcodeproj'
require 'fileutils'

REPO_ROOT   = File.expand_path('..', __dir__)
EXAMPLE_DIR = File.join(REPO_ROOT, 'EimzoExample')
# xcodeproj sits at repo root so source paths in build settings stay
# readable (Info.plist, EimzoExample.entitlements, EimzoExample/*.swift).
PROJ_PATH   = File.join(REPO_ROOT, 'EimzoExample.xcodeproj')

SDK_PACKAGE_URL = 'https://github.com/peachdev-uz/eimzo-ios-sdk'
# Minimum SDK version the example targets (used for `.upToNextMajorVersion`).
# Stays at 1.0.0 — SPM auto-resolves to whatever the highest 1.x tag is.
SDK_MIN_VERSION = '1.0.0'
# Example app's own version. Bump this in lockstep with the SDK on every
# release so the displayed CFBundleShortVersionString matches the tag a
# consumer is looking at.
EXAMPLE_VERSION = '1.0.3'

FileUtils.rm_rf(PROJ_PATH)
project = Xcodeproj::Project.new(PROJ_PATH)
project.root_object.attributes['LastUpgradeCheck'] = '1600'

# ── App target ──────────────────────────────────────────────────────────────
target = project.new_target(:application, 'EimzoExample', :ios, '16.0')
target.build_configurations.each do |config|
  config.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER'    => 'uz.peachdev.eimzoexample',
    'PRODUCT_NAME'                 => '$(TARGET_NAME)',
    'CODE_SIGN_STYLE'              => 'Automatic',
    'DEVELOPMENT_TEAM'             => '',  # Xcode will prompt
    'CODE_SIGN_ENTITLEMENTS'       => 'EimzoExample/EimzoExample.entitlements',
    'INFOPLIST_FILE'               => 'EimzoExample/Info.plist',
    'TARGETED_DEVICE_FAMILY'       => '1',  # iPhone only
    'IPHONEOS_DEPLOYMENT_TARGET'   => '16.0',
    'SWIFT_VERSION'                => '5.9',
    'ENABLE_PREVIEWS'              => 'YES',
    'GENERATE_INFOPLIST_FILE'      => 'NO',
    'CURRENT_PROJECT_VERSION'      => '1',
    'MARKETING_VERSION'            => EXAMPLE_VERSION,
  })
end

# ── Sources ─────────────────────────────────────────────────────────────────
# Group's `path` is "EimzoExample", so file refs are relative to that —
# DON'T re-prefix the file names with "EimzoExample/" or you'll end up
# with "EimzoExample/EimzoExample/Foo.swift" on disk.
src_group = project.new_group('EimzoExample', 'EimzoExample')
%w[EimzoExampleApp.swift ContentView.swift].each do |fname|
  file_ref = src_group.new_file(fname)
  target.add_file_references([file_ref])
end
# Show Info.plist + entitlements in the Project Navigator. Both are wired up
# via INFOPLIST_FILE / CODE_SIGN_ENTITLEMENTS — adding them here is purely
# for navigation; they're not part of any build phase.
src_group.new_file('Info.plist')
src_group.new_file('EimzoExample.entitlements')

# ── Swift Package Manager: depend on the published EimzoSDK binary ─────────
# Pulls EimzoSDK.xcframework from this same repo's GitHub Releases. The
# integrator doesn't need to download anything manually — Xcode resolves
# the binary on first open.
pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
pkg.repositoryURL = SDK_PACKAGE_URL
pkg.requirement   = { 'kind' => 'upToNextMajorVersion',
                      'minimumVersion' => SDK_MIN_VERSION }
project.root_object.package_references << pkg

product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product.package      = pkg
product.product_name = 'EimzoSDK'
target.package_product_dependencies << product

# Link the product into the Frameworks build phase.
build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build_file.product_ref = product
target.frameworks_build_phase.files << build_file

# ── Save ────────────────────────────────────────────────────────────────────
project.save
puts "✔ Generated #{PROJ_PATH}"
puts "  Open in Xcode: open #{PROJ_PATH}"

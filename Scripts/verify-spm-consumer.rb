#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "tmpdir"
require "xcodeproj"

root = Pathname.new(__dir__).parent.realpath

Dir.mktmpdir("kingfisher-spm-consumer-", root) do |temporary_directory|
  project_path = File.join(temporary_directory, "KingfisherConsumer.xcodeproj")
  source_path = File.join(temporary_directory, "KingfisherConsumerApp.swift")
  derived_data_path = File.join(temporary_directory, "DerivedData")

  File.write(source_path, <<~SWIFT)
        import UIKit
        import Kingfisher

        @main
        final class AppDelegate: UIResponder, UIApplicationDelegate {
            func application(
                _ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
            ) -> Bool {
                _ = KingfisherManager.shared
                return true
            }
        }
    SWIFT

  project = Xcodeproj::Project.new(project_path)
  target = project.new_target(:application, "KingfisherConsumer", :ios, "15.0")
  target.build_configurations.each do |configuration|
    configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.onevcat.KingfisherConsumer"
    configuration.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
    configuration.build_settings["CODE_SIGNING_ALLOWED"] = "NO"
    configuration.build_settings["SWIFT_VERSION"] = "5.0"
  end

  source_reference = project.main_group.new_file(source_path)
  target.add_file_references([source_reference])

  package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  package.relative_path = ".."
  project.root_object.package_references << package

  product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product.package = package
  product.product_name = "Kingfisher"
  target.package_product_dependencies << product
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product
  target.frameworks_build_phase.files << build_file

  project.save

  command = [
    "xcodebuild",
    "-project", project_path,
    "-scheme", "KingfisherConsumer",
    "-sdk", "iphonesimulator",
    "-destination", "generic/platform=iOS Simulator",
    "-derivedDataPath", derived_data_path,
    "build"
  ]
  abort "Consumer app build failed" unless system(*command)

  app_path = File.join(
    derived_data_path,
    "Build/Products/Debug-iphonesimulator/KingfisherConsumer.app"
  )
  manifests = Dir.glob(File.join(app_path, "**", "PrivacyInfo.xcprivacy"))
  abort "No privacy manifest was embedded in #{app_path}" if manifests.empty?

  kingfisher_manifest = manifests.find do |manifest|
    content = File.binread(manifest)
    content.include?("NSPrivacyAccessedAPICategoryFileTimestamp") && content.include?("C617.1")
  end
  abort "Kingfisher privacy manifest was not embedded with its required-reason declaration" unless kingfisher_manifest

  puts "Verified Kingfisher privacy manifest: #{kingfisher_manifest}"
end

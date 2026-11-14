require "json"

# Resolves an `xcodebuild` simulator destination to the ID of an available device.
#
# The simulator runtimes and devices on hosted CI runners are not stable, even for the same image version. A destination
# that names a device and an OS fails with "Unable to find a device matching the provided destination specifier" when
# that pair is not installed on the runner. This picks the closest available device instead, in this order:
#
# 1. The device with the requested name and OS.
# 2. The device with the requested name, on the newest OS that has it.
# 3. Any device on the requested OS.
# 4. Any device on the newest OS of the platform.
module SimulatorDestination
  RUNTIME_PREFIX = "com.apple.CoreSimulator.SimRuntime."

  # Runtime identifiers use these names, which are not always the platform names of a destination.
  RUNTIME_NAMES = { "visionOS" => ["visionOS", "xrOS"] }.freeze

  Resolution = Struct.new(:destination, :device_name, :os, :exact, keyword_init: true)

  module_function

  # - Parameters:
  #   - destination: An `xcodebuild` destination, such as "platform=tvOS Simulator,name=Apple TV,OS=27.0".
  #   - devices: The "devices" value of `xcrun simctl list devices available --json`.
  # - Returns: A `Resolution`, or `nil` if the destination does not name a simulator device. In that case, use the
  #   destination as it is.
  def resolve(destination, devices)
    fields = destination.to_s.split(",").to_h { |pair| pair.split("=", 2).map(&:strip) }
    platform = fields["platform"].to_s
    name = fields["name"]
    return nil unless platform.end_with?(" Simulator") && name

    os_name = platform.delete_suffix(" Simulator")
    candidates = candidates(os_name, devices)
    raise ArgumentError, "No available device for #{platform}." if candidates.empty?

    wanted_os = fields["OS"] && fields["OS"] != "latest" ? Gem::Version.new(fields["OS"]) : nil
    on_wanted_os = ->(device) { wanted_os.nil? || device[:os] == wanted_os }
    named = candidates.select { |device| device[:name] == name }

    device = preferred(named.select(&on_wanted_os)) ||
      preferred(named) ||
      preferred(candidates.select(&on_wanted_os)) ||
      preferred(candidates)

    Resolution.new(
      destination: "platform=#{platform},id=#{device[:udid]}",
      device_name: device[:name],
      os: device[:os].to_s,
      exact: device[:name] == name && on_wanted_os.(device)
    )
  end

  # The available devices of a platform, with the OS version parsed from their runtime identifier.
  def candidates(os_name, devices)
    prefixes = RUNTIME_NAMES.fetch(os_name, [os_name]).map { |runtime_name| "#{RUNTIME_PREFIX}#{runtime_name}-" }
    devices.flat_map do |runtime, runtime_devices|
      prefix = prefixes.find { |p| runtime.start_with?(p) }
      # A runtime identifier can have a suffix after the version, such as "iOS-27-2-iPhone19-4".
      version = prefix && runtime.delete_prefix(prefix)[/\A\d+(-\d+)*/]
      next [] unless version

      runtime_devices.map do |device|
        { name: device["name"], udid: device["udid"], booted: device["state"] == "Booted",
          os: Gem::Version.new(version.tr("-", ".")) }
      end
    end
  end

  # The device on the newest OS. Among devices on the same OS, a booted one is preferred, since it starts faster.
  def preferred(devices)
    devices.max_by { |device| [device[:os], device[:booted] ? 1 : 0] }
  end
end

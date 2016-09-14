module Fastlane
  module Actions
    class ExtractCurrentChangeLogAction < Action
      require 'yaml'
      def self.run(params)
        yaml = File.read(params[:file])
        data = YAML.load(yaml)
        version = data["version"]
        raise "The version should match in the input file".red unless (version and version == params[:version])

        title = "#{version}"
        title = title + " - #{data["name"]}" if (data["name"] and not data["name"].empty?)

        return {:title => title, :version => version, :add => data["add"], :fix => data["fix"], :remove => data["remove"]}
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Extract change log information for a specified version."
      end

      def self.details
        "This action will check input version and change log. If everything goes well, the change log info will be returned."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "KF_EXTRACT_CURRENT_CHANGE_LOG_VERSION",
                                       description: "The target version which is needed to be extract",
                                       verify_block: proc do |value|
                                          raise "No version number is given, pass using `version: 'version_number'`".red unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :file,
                                       env_name: "KF_EXTRACT_CURRENT_CHANGE_LOG_PRECHANGE_FILE",
                                       description: "Create a development certificate instead of a distribution one",
                                       default_value: "pre-change.yml")
        ]
      end

      def self.return_value
        "An object contains change log infomation. {version: }"
      end

      def self.is_supported?(platform)
        true
      end

      def self.authors
        ["onevcat"]
      end
    end
  end
end

module Fastlane
  module Actions
    class GitCommitAllAction < Action
      def self.run(params)
          Actions.sh "git commit -am \"#{params[:message]}\""
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Commit all unsaved changes to git."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_GIT_COMMIT_ALL",
                                       description: "The git message for the commit",
                                       is_string: true)
        ]
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["onevcat"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end

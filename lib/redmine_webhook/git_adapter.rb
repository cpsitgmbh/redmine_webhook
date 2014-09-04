module RedmineWebhook
  module RedmineWebhook
    class Git < Redmine::Scm::Adapters::GitAdapter

      GIT_BIN = Redmine::Configuration['scm_git_command'] || "git"

      class << self
        def client_command
          @@bin    ||= GIT_BIN
        end

        def sq_bin
          @@sq_bin ||= shell_quote_command
        end

        def client_version
          @@client_version ||= (scm_command_version || [])
        end

        def client_available
          !client_version.empty?
        end

        def scm_command_version
          scm_version = scm_version_from_command_line.dup
          if scm_version.respond_to?(:force_encoding)
            scm_version.force_encoding('ASCII-8BIT')
          end
          if m = scm_version.match(%r{\A(.*?)((\d+\.)+\d+)})
            m[2].scan(%r{\d+}).collect(&:to_i)
          end
        end

        def scm_version_from_command_line
          shellout("#{sq_bin} --version --no-color") { |io| io.read }.to_s
        end

        def logger
          Rails::logger
        end
      end

      def initialize(url, root_url)
        super
      end

      def exists?
        File.exist?(@root_url)
        end

      def clone
        cmd_args = %w|clone -q  --mirror|
        cmd_args << @url
        cmd_args << @root_url
        ret = git_cmd(cmd_args)
        rescue ScmCommandAborted
          nil
      end

      def fetch
        cmd_args = %w|fetch -q --all|
        ret = git_cmd(cmd_args)
        rescue ScmCommandAborted
          nil
      end

    end
  end
end
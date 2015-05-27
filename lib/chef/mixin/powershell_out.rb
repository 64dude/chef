#--
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Chef
  module Mixin
    module PowershellOut
      # Note that the architecture helper requires a #node method to
      # exist in the superclass so we do here as well.
      include Chef::Mixin::ShellOut
      include Chef::Mixin::WindowsArchitectureHelper

      def powershell_out(*command_args)
        script = command_args.first
        options = command_args.last.is_a?(Hash) ? command_args.last : nil

        run_command_with_wow64(script, options)
      end

      def powershell_out!(*command_args)
        cmd = powershell_out(*command_args)
        cmd.error!
        cmd
      end

      private

      def run_command_with_wow64(script, options = nil)
        architecture = node_windows_architecture(node)

        if options && options[:architecture]
          architecture = options[:architecture]
          options.delete(:architecture)
        end

        command = build_powershell_command(script)

        with_disabled_wow64_redirection(architecture) do
          cmd = shell_out(
            build_powershell_command(script),
            options
          )
        end
      end

      def with_disabled_wow64_redirection(architecture, &block)
        disable_redirection = wow64_architecture_override_required?(node, architecture)

        if disable_redirection
          original_redirection_state = disable_wow64_file_redirection(node)
          ret = block.call
          restore_wow64_file_redirection(node, original_redirection_state)
        else
          ret = block.call
        end

        ret
      end

      def build_powershell_command(script)
        flags = [
          # Hides the copyright banner at startup.
          "-NoLogo",
          # Does not present an interactive prompt to the user.
          "-NonInteractive",
          # Does not load the Windows PowerShell profile.
          "-NoProfile",
          # always set the ExecutionPolicy flag
          # see http://technet.microsoft.com/en-us/library/ee176961.aspx
          "-ExecutionPolicy RemoteSigned",
          # Powershell will hang if STDIN is redirected
          # http://connect.microsoft.com/PowerShell/feedback/details/572313/powershell-exe-can-hang-if-stdin-is-redirected
          "-InputFormat None"
        ]

        command = "powershell.exe #{flags.join(' ')} -Command \"#{script}\""
        command
      end
    end
  end
end

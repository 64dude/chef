#
# Author:: Steven Danna (<steve@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
#

require 'chef/knife'

class Chef
  class Knife
    class UserCreate < Knife

      deps do
        require 'chef/user'
        require 'chef/json_compat'
      end

      option :file,
        :short => "-f FILE",
        :long  => "--file FILE",
        :description => "Write the private key to a file"

      option :admin,
        :short => "-a",
        :long  => "--admin",
        :description => "Create the user as an admin",
        :boolean => true

      option :user_key,
        :long => "--user-key FILENAME",
        :description => "Public key for newly created user. The server will create a 'default' key for you, unless you passed --no-key."

      option :no_key,
        :long => "--no-key",
        :description => "Do not ask the server to generate a public key for you (requires server API version 1)."

      option :public_key,
        :long => "--public-key",
        :description => "Path to a public key you provide instead of having the server generate one (requires server API version 1)."

      banner "knife user create USERNAME DISPLAY_NAME FIRST_NAME LAST_NAME EMAIL PASSWORD (options)"

      def test_mandatory_field(field, fieldname)
        if field.nil?
          show_usage
          ui.fatal("You must specify a #{fieldname}")
          exit 1
        end
      end

      def run
        user = Chef::User.new

        test_mandatory_field(@name_args[0], "username")
        user.username @name_args[0]

        test_mandatory_field(@name_args[1], "display name")
        user.display_name @name_args[1]

        test_mandatory_field(@name_args[2], "first name")
        user.first_name @name_args[2]

        test_mandatory_field(@name_args[3], "last name")
        user.last_name @name_args[3]

        test_mandatory_field(@name_args[4], "email")
        user.email @name_args[4]

        test_mandatory_field(@name_args[5], "password")
        user.password @name_args[5]

        if config[:user_key] && config[:no_key]
          show_usage
          ui.fatal("You cannot pass --user-key and --no-key")
          exit 1
        end

        if config[:public_key] && config[:no_key]
          show_usage
          ui.fatal("You cannot pass --public-key and --no-key")
          exit 1
        end

        user.admin(config[:admin])

        unless config[:no_key]
          user.create_key(true)
        end

        if config[:public_key]
          user.public_key(File.read(File.expand_path(config[:public_key])))
        end

        user.password config[:user_password]

        if config[:user_key]
          user.public_key File.read(File.expand_path(config[:user_key]))
        end

        output = edit_data(user)
        user = Chef::User.from_hash(output).create

        ui.info("Created #{user}")
        if user.private_key
          if config[:file]
            File.open(config[:file], "w") do |f|
              f.print(user.private_key)
            end
          else
            ui.msg user.private_key
          end
        end
      end
    end
  end
end

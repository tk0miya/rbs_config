# frozen_string_literal: true

require "rails"

module RbsConfig
  class InstallGenerator < Rails::Generators::Base
    def create_raketask
      create_file "lib/tasks/rbs_config.rake", <<~RUBY
        begin
          require 'rbs_config/rake_task'
          RbsConfig::RakeTask.new do |task|
            # The class name of configuration object.
            # task.class_name = "Settings"

            # The files to be loaded.
            # task.files = [Pathname(Rails.root / "config/settings.yml")]
          end
        rescue LoadError
          # failed to load rbs_config. Skip to load rbs_config tasks.
        end
      RUBY
    end
  end
end

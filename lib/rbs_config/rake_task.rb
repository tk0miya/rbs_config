# frozen_string_literal: true

require "pathname"
require "rake/tasklib"

module RbsConfig
  class RakeTask < Rake::TaskLib
    attr_accessor :class_name, :files, :name, :signature_root_dir

    def initialize(name = :'rbs:config', &block)
      super()

      @name = name
      @class_name = "Settings"
      @files = [Pathname(Rails.root / "config/settings.yml"),
                Pathname(Rails.root / "config/settings.local.yml"),
                Pathname(Rails.root / "config/settings/production.yml")]
      @signature_root_dir = Pathname(Rails.root / "sig/config")

      block&.call(self)

      define_clean_task
      define_generate_task
      define_setup_task
    end

    def define_setup_task
      desc "Run all tasks of rbs_config"

      deps = [:"#{name}:clean", :"#{name}:generate"]
      task("#{name}:setup" => deps)
    end

    def define_generate_task
      desc "Generate RBS files for config gem"
      task "#{name}:generate" do
        signature_root_dir.mkpath

        signature_root_dir.join("#{class_name.underscore}.rbs").write(
          RbsConfig::Config.generate(files: files, class_name: class_name)
        )
      end
    end

    def define_clean_task
      desc "Clean RBS files for config gem"
      task "#{name}:clean" do
        signature_root_dir.rmtree if signature_root_dir.exist?
      end
    end
  end
end

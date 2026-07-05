# frozen_string_literal: true

require "pathname"
require "rake/tasklib"

module RbsConfig
  class RakeTask < Rake::TaskLib
    attr_accessor :type #: :config | :rails
    attr_accessor :class_name #: String
    attr_accessor :files #: Array[Pathname]
    attr_accessor :mapping #: Hash[untyped, Hash[untyped, untyped]]
    attr_accessor :name #: Symbol
    attr_accessor :signature_root_dir #: Pathname

    # @rbs name: Symbol
    # @rbs &block: ?(RbsConfig::RakeTask) -> void
    def initialize(name = :'rbs:config', &block) #: void
      super()

      @name = name
      @type = :config
      @class_name = "Settings"
      @files = [Pathname(Rails.root / "config/settings.yml"),
                Pathname(Rails.root / "config/settings.local.yml"),
                Pathname(Rails.root / "config/settings/production.yml")]
      @mapping = {}
      @signature_root_dir = Pathname(Rails.root / "sig/config")

      block&.call(self)

      define_clean_task
      define_generate_task
      define_setup_task
    end

    def define_setup_task #: void
      desc "Run all tasks of rbs_config"

      deps = [:"#{name}:clean", :"#{name}:generate"]
      task("#{name}:setup" => deps)
    end

    def define_generate_task #: void
      desc "Generate RBS files for config gem"
      task "#{name}:generate" do
        require "rbs_config" # load RbsConfig lazily

        signature_root_dir.mkpath

        rbs = if type == :config
                RbsConfig::Config.generate(files: files, class_name: class_name)
              else
                RbsConfig::RailsConfig.generate(mapping: mapping)
              end

        signature_root_dir.join("#{class_name.underscore}.rbs").write(rbs)
      end
    end

    def define_clean_task #: void
      desc "Clean RBS files for config gem"
      task "#{name}:clean" do
        signature_root_dir.rmtree if signature_root_dir.exist?
      end
    end
  end
end

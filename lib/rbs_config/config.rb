# frozen_string_literal: true

require "rbs"
require "active_support/core_ext/string/inflections"

module RbsConfig
  module Config
    # @rbs files: Array[Pathname]
    # @rbs class_name: String
    def self.generate(files:, class_name: "Settings") #: String
      Generator.new(class_name: class_name, files: files).generate
    end

    class Generator
      attr_reader :class_name #: String
      attr_reader :files #: Array[Pathname]

      # @rbs class_name: String
      # @rbs files: Array[Pathname]
      def initialize(class_name:, files:) #: void
        @class_name = class_name
        @files = files
      end

      def generate #: String
        config = load_config(files)
        classes = generate_classes(config)
        methods = generate_methods(config)

        format <<~RBS
          module Config
            module Generated
              class #{class_name} < ::Config::Options
                #{classes.join("\n")}
                #{methods.join("\n")}
              end
            end
          end

          #{class_name}: Config::Generated::#{class_name}
        RBS
      end

      private

      # @rbs rbs: String
      def format(rbs) #: String
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
        end.string
      end

      # @rbs config: Hash[untyped, untyped]
      def generate_classes(config) #: Array[String]
        config.filter_map do |key, value|
          case value
          when Array
            generate_classes({ key => value.first }).first if value.first.is_a?(Hash)
          when Hash
            classes = generate_classes(value)
            methods = generate_methods(value)

            <<~RBS
              class #{key.camelize} < ::Config::Options
                #{classes.join("\n")}
                #{methods.join("\n")}
              end
            RBS
          end
        end
      end

      # @rbs config: Hash[untyped, untyped]
      def generate_methods(config) #: Array[String]
        config.map do |key, value|
          "def #{key}: () -> #{stringify_type(key, value)}"
        end
      end

      # @rbs name: untyped
      # @rbs value: untyped
      def stringify_type(name, value) #: String
        case value
        when Hash
          name.camelize
        when Array
          types = value.map { |v| stringify_type(name, v) }.uniq
          "Array[#{types.join(" | ")}]"
        when NilClass
          "nil"
        when TrueClass, FalseClass
          "bool"
        else
          value.class.to_s
        end
      end

      # @rbs files: Array[Pathname]
      def load_config(files) #: Hash[untyped, untyped]
        configs = files.map do |f|
          content = ERB.new(f.read).result
          YAML.unsafe_load(content)
        end
        configs.inject { |a, b| a.deep_merge(b) }
      end
    end
  end
end

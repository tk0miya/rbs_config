# frozen_string_literal: true

require "rbs"
require "active_support/core_ext/string/inflections"

module RbsConfig
  module Config
    def self.generate(files:, class_name: "Settings")
      Generator.new(class_name: class_name, files: files).generate
    end

    class Generator
      attr_reader :class_name, :files

      def initialize(class_name:, files:)
        @class_name = class_name
        @files = files
      end

      def generate
        config = load_config(files)
        classes = generate_classes(config)
        methods = generate_methods(config)

        format <<~RBS
          class #{class_name}
            #{classes.join("\n")}
            #{methods.join("\n")}
          end
        RBS
      end

      private

      def format(rbs)
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
        end.string
      end

      def generate_classes(config)
        config.filter_map do |key, value|
          case value
          when Array
            generate_classes({ key => value.first }).first if value.first.is_a?(Hash)
          when Hash
            classes = generate_classes(value)
            methods = generate_methods(value)

            <<~RBS
              class #{key.camelize}
                #{classes.join("\n")}
                #{methods.join("\n")}
              end
            RBS
          end
        end
      end

      def generate_methods(config)
        config.map do |key, value|
          "def self.#{key}: () -> #{stringify_type(key, value)}"
        end
      end

      def stringify_type(name, value)
        case value
        when Hash
          "singleton(#{name.camelize})"
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

      def load_config(files)
        configs = files.map do |f|
          content = ERB.new(f.read).result
          if YAML.respond_to?(:unsafe_load)
            YAML.unsafe_load(content)
          else
            YAML.load(content) # rubocop:disable Security/YAMLLoad
          end
        end
        configs.inject { |a, b| a.deep_merge(b) }
      end
    end
  end
end

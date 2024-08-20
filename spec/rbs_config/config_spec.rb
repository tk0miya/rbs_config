# frozen_string_literal: true

require "rbs_config"
require "tempfile"

RSpec.describe RbsConfig::Config do
  describe ".generate" do
    subject { described_class.generate(files: files) }

    let(:files) { [Pathname.new(config_file.path)] }
    let(:config_file) do
      Tempfile.open("config.yml") do |f|
        f.write config
        f
      end
    end
    let(:config) do
      <<~YAML
        foo:
          bar: <%= 1 %>
          baz: true
        qux:
          - lorem
          - ipsum
        quux:
          - lorem: 1
            ipsum: 2
          - lorem: 3
            ipsum: 4
      YAML
    end
    let(:expected) do
      <<~RBS
        module Config
          module Generated
            class Settings < ::Config::Options
              class Foo < ::Config::Options
                def bar: () -> Integer
                def baz: () -> bool
              end

              class Quux < ::Config::Options
                def lorem: () -> Integer
                def ipsum: () -> Integer
              end

              def foo: () -> Foo
              def qux: () -> Array[String]
              def quux: () -> Array[Quux]
            end
          end
        end

        Settings: Config::Generated::Settings
      RBS
    end

    it { is_expected.to eq(expected) }
  end
end

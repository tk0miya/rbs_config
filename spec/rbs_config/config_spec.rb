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
        class Settings
          class Foo
            def self.bar: () -> Integer
            def self.baz: () -> bool
          end

          class Quux
            def self.lorem: () -> Integer
            def self.ipsum: () -> Integer
          end

          def self.foo: () -> singleton(Foo)
          def self.qux: () -> Array[String]
          def self.quux: () -> Array[singleton(Quux)]
        end
      RBS
    end

    it { is_expected.to eq(expected) }
  end
end

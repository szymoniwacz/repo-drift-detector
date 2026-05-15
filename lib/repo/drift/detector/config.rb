# frozen_string_literal: true

require 'yaml'

module Repo
  module Drift
    module Detector
      class ConfigError < StandardError; end

      class Config
        FILENAME = '.repo-drift-detector.yml'

        DEFAULT_MEDIUM_CHANGE = 20
        DEFAULT_HIGH_CHANGE = 100
        DEFAULT_UNSAFE_RATIO = 3.0

        attr_reader :medium_change_threshold, :high_change_threshold, :unsafe_change_ratio_threshold

        def self.load(cwd: Dir.pwd)
          path = File.join(File.expand_path(cwd), FILENAME)
          new(config_path: File.file?(path) ? path : nil)
        end

        def initialize(config_path:)
          @config_path = config_path
          @risk = config_path ? risk_from_file(config_path) : {}
          assign_thresholds!
        end

        private

        attr_reader :config_path, :risk

        def risk_from_file(path)
          stringify_keys(risk_section(path))
        end

        def risk_section(path)
          data = yaml_root_mapping(path)
          section = data['risk']
          return {} if section.nil?

          raise ConfigError, "#{path}: risk must be a mapping" unless section.is_a?(Hash)

          section
        end

        def yaml_root_mapping(path)
          raw = File.read(path)
          parse_yaml_document(path, raw)
        rescue Psych::SyntaxError => e
          raise ConfigError, "#{path}: invalid YAML (#{e.message})"
        end

        def parse_yaml_document(path, raw)
          data = YAML.safe_load(
            raw,
            permitted_classes: [],
            permitted_symbols: [],
            aliases: true
          )
          raise ConfigError, "#{path}: config root must be a mapping" if data && !data.is_a?(Hash)

          data || {}
        end

        def stringify_keys(hash)
          hash.transform_keys(&:to_s)
        end

        def assign_thresholds!
          label = config_path || '.repo-drift-detector.yml (defaults)'
          coerce_threshold_fields!(label)
          validate_threshold_order!(label)
        end

        def coerce_threshold_fields!(label)
          @medium_change_threshold = coerce_positive_integer(
            label, 'medium_change_threshold', risk['medium_change_threshold'], DEFAULT_MEDIUM_CHANGE
          )
          @high_change_threshold = coerce_positive_integer(
            label, 'high_change_threshold', risk['high_change_threshold'], DEFAULT_HIGH_CHANGE
          )
          @unsafe_change_ratio_threshold = coerce_positive_float(
            label, 'unsafe_change_ratio_threshold', risk['unsafe_change_ratio_threshold'], DEFAULT_UNSAFE_RATIO
          )
        end

        def validate_threshold_order!(label)
          return if @medium_change_threshold < @high_change_threshold

          raise ConfigError,
                "#{label}: high_change_threshold must be greater than medium_change_threshold " \
                "(got medium=#{@medium_change_threshold}, high=#{@high_change_threshold})"
        end

        def coerce_positive_integer(label, key, raw, default)
          return default if raw.nil?

          int = Integer(raw)
          raise ConfigError, "#{label}: #{key} must be a positive integer (got #{raw.inspect})" if int <= 0

          int
        rescue ArgumentError, TypeError
          raise ConfigError, "#{label}: #{key} must be a positive integer (got #{raw.inspect})"
        end

        def coerce_positive_float(label, key, raw, default)
          return default if raw.nil?

          float = Float(raw)
          raise ConfigError, "#{label}: #{key} must be a positive number (got #{raw.inspect})" if float <= 0

          float
        rescue ArgumentError, TypeError
          raise ConfigError, "#{label}: #{key} must be a positive number (got #{raw.inspect})"
        end
      end
    end
  end
end

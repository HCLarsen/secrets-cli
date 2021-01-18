require "option_parser"
require "secrets"

module Secrets::CLI
  VERSION = "0.1.0"

  def self.run(options = ARGV)
    path = "secrets.yml.enc"
    key_path = "secrets.key"
    key = nil
    value = nil

    paths_parser = OptionParser.new do |parser|
      parser.on("-y PATH", "--yaml-file PATH", "File path") { |_path| path = _path }
      parser.on("-f KEY_PATH", "--key-file KEY_PATH", "Key file path") { |_key_path| key_path = _key_path }
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
    end

    read_parser = OptionParser.new do |parser|
      parser.banner = "Usage: secrets read [arguments]"
      parser.on("-y PATH", "--yaml-file PATH", "File path") { |_path| path = _path }
      parser.on("-f KEY_PATH", "--key-file KEY_PATH", "Key file path") { |_key_path| key_path = _key_path }
      parser.on("-k KEY", "--key KEY ", "Key for value") { |_key| key = _key }
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
      parser.missing_option do |flag|
        puts parser
        exit
      end
    end

    edit_parser = OptionParser.new do |parser|
      parser.banner = "Usage: secrets edit [arguments]"
      parser.on("-y PATH", "--yaml-file PATH", "File path") { |_path| path = _path }
      parser.on("-f KEY_PATH", "--key-file KEY_PATH", "Key file path") { |_key_path| key_path = _key_path }
      parser.on("-k KEY", "--key KEY ", "Key for value") { |_key| key = _key }
      parser.on("-n VALUE", "--new-value VALUE", "New Value") { |_value| value = _value }
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
      parser.missing_option do |flag|
        puts parser
        exit
      end
    end

    parser = OptionParser.new do |parser|
      parser.banner = "Usage: secrets [arguments]"
      parser.on("generate", "Create new secrets and key files") do
        paths_parser.banner = "Usage: secrets generate [arguments]"
        paths_parser.parse
        Secrets.generate(path, key_path)
        exit
      end

      parser.on("read", "Read the contents of the encrypted file") do
        read_parser.parse
        secrets = Secrets.new
        paths = key
        if paths
          parts = paths.split('/')
          any = secrets[parts.shift]
          parts.each do |part|
            any = any[part]
          end
          puts any.to_yaml.gsub("--- ", "")
        else
          puts secrets.raw
        end
        exit
      end

      parser.on("edit", "Edit a value in the encrypted file") do
        edit_parser.parse
        if !key || !value
          puts edit_parser
          exit
        end
        secrets = Secrets.new
        paths = key
        new_value = value
        if paths && new_value
          parts = paths.split('/')
          first_key = parts.shift
          final_key = parts.pop
          unless secrets[first_key]?
            secrets[first_key] = {} of String => Secrets::Any
          end
          any = secrets[first_key]

          parts.each do |part|
            unless any[part]?
              any[part] = {} of String => Secrets::Any
            end
            any = any[part]
          end
          any[final_key] = new_value
          secrets.save
          exit
        end
        exit
      end

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end

      parser.on("-v", "--version", "Returns version") { puts "0.1.0" }

      if ARGV.empty?
        puts parser
        exit
      end
    end

    parser.parse
  end
end

Secrets::CLI.run

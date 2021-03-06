require "option_parser"
require "secrets"

class Secrets::CLI
  VERSION = "0.1.0"

  @key : String?
  @value : String?

  def self.run(options = ARGV)
    new(options).run
  end

  def initialize(@options : Array(String))
    @path = "secrets.yml.enc"
    @key_path = "secrets.key"
  end

  def run
    parser = OptionParser.new do |parser|
      parser.banner = "Usage: secrets [arguments]"
      parser.on("generate", "Create new secrets and key files") do
        generate
        exit
      end

      parser.on("read", "Read the contents of the encrypted file") do
        read
        exit
      end

      parser.on("edit", "Edit a value in the encrypted file") do
        edit
        exit
      end

      parser.on("reset", "Resets key and encrypts data with new key") do
        reset
        exit
      end

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end

      parser.on("-v", "--version", "Returns version") { puts VERSION }

      if ARGV.empty?
        puts parser
        exit
      end
    end

    parser.parse
  end

  def generate
    parse_paths("generate")
    Secrets.generate(@path, @key_path)
  end

  def read
    read_parser = OptionParser.parse do |parser|
      parser.banner = "Usage: secrets read [arguments]"
      parser.on("-y PATH", "--yaml-file PATH", "File path") { |_path| @path = _path }
      parser.on("-f KEY_PATH", "--key-file KEY_PATH", "Key file path") { |_key_path| @key_path = _key_path }
      parser.on("-k KEY", "--key KEY ", "Key for value") { |_key| @key = _key }
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
      parser.missing_option do |flag|
        puts parser
        exit
      end
    end

    paths = @key
    secrets = Secrets.new(@path, @key_path)
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
  end

  def edit
    edit_parser = OptionParser.parse do |parser|
      parser.banner = "Usage: secrets edit [arguments]"
      parser.on("-y PATH", "--yaml-file PATH", "File path") { |_path| @path = _path }
      parser.on("-f KEY_PATH", "--key-file KEY_PATH", "Key file path") { |_key_path| @key_path = _key_path }
      parser.on("-k KEY", "--key KEY ", "Key for value") { |_key| @key = _key }
      parser.on("-n VALUE", "--new-value VALUE", "New Value") { |_value| @value = _value }
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
      parser.missing_option do |flag|
        puts parser
        exit
      end
    end

    paths = @key
    new_value = @value
    if paths && new_value
      edit_value(paths, new_value)
    else
      puts edit_parser
    end
  end

  def edit_value(keys : String, value : String)
    secrets = Secrets.new(@path, @key_path)
    parts = keys.split('/')
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
    any[final_key] = value
    secrets.save
  end

  def reset
    parse_paths("reset")
    secrets = Secrets.new(@path, @key_path)
    secrets.reset
  end

  def parse_paths(name : String)
    paths_parser = OptionParser.parse do |parser|
      parser.banner = "Usage: secrets #{name} [arguments]"
      parser.on("-y PATH", "--yaml-file PATH", "File path") { |_path| @path = _path }
      parser.on("-f KEY_PATH", "--key-file KEY_PATH", "Key file path") { |_key_path| @key_path = _key_path }
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
    end
  end
end

Secrets::CLI.run

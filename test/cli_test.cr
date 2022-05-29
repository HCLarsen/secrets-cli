require "minitest/autorun"

require "secrets"
require "./../src/secrets-cli"

class CLITest < Minitest::Test
  @default_path = "secrets.yml.enc"
  @default_key_path = "secrets.key"

  def setup
    if File.exists?(".gitignore")
      File.copy(".gitignore", ".gitignore-main")
    end
  end

  def teardown
    File.delete(@default_path) if File.exists?(@default_path)
    File.delete(@default_key_path) if File.exists?(@default_key_path)

    if File.exists?(".gitignore-main")
      File.rename(".gitignore-main", ".gitignore")
    end
  end

  def generate_secrets
    Secrets.generate

    secrets = Secrets.new
    secrets["login"] = {"username" => Secrets::Any.new("warmachine68@starkindustries.com"), "password" => Secrets::Any.new("WARMACHINEROX")}
    secrets.save
  end

  def test_generates_default_files
    `crystal run src/secrets-cli.cr -- generate`
    assert File.exists?(@default_path)
    assert File.exists?(@default_key_path)
  end

  def test_doesnt_overwrite_files
    `crystal run src/secrets-cli.cr -- generate`

    message = `crystal run src/secrets-cli.cr -- generate`
    assert_equal message, "Error: Secrets file already exists\n"
  end

  def test_generates_with_custom_paths
    Dir.mkdir_p("config")

    `crystal run src/secrets-cli.cr -- generate -y "config/credentials.yml.enc" -f config/master.key`
    assert File.exists?("config/credentials.yml.enc")
    assert File.exists?("config/master.key")

    File.delete("config/credentials.yml.enc") if File.exists?("config/credentials.yml.enc")
    File.delete("config/master.key") if File.exists?("config/master.key")
    Dir.delete("config") if Dir.exists?("config")
  end

  def test_reads_file
    generate_secrets

    expected = "---\nlogin:\n  username: warmachine68@starkindustries.com\n  password: WARMACHINEROX\n"
    response = `crystal run src/secrets-cli.cr -- read`

    assert_equal expected, response

    expected = "---\nusername: warmachine68@starkindustries.com\npassword: WARMACHINEROX\n"
    response = `crystal run src/secrets-cli.cr -- read -k login`

    assert_equal expected, response

    response = `crystal run src/secrets-cli.cr -- read -k login/password`

    assert_equal "WARMACHINEROX\n", response
  end

  def test_outputs_error_reading_invalid_key
    generate_secrets

    expected = "Invalid key: log/password\nPlease verify key for value.\n"
    response = `crystal run src/secrets-cli.cr -- read -k log/password`

    assert_equal expected, response

    expected = "Invalid key: login/pass\nPlease verify key for value.\n"
    response = `crystal run src/secrets-cli.cr -- read -k login/pass`

    assert_equal expected, response
  end

  def test_edits_file
    generate_secrets

    `crystal run src/secrets-cli.cr -- edit -k name -n "James Rhodes"`

    response = `crystal run src/secrets-cli.cr -- read -k name`
    assert_equal "James Rhodes\n", response

    `crystal run src/secrets-cli.cr -- edit -k login/password -n TONYSTANK`

    response = `crystal run src/secrets-cli.cr -- read -k login/password`
    assert_equal "TONYSTANK\n", response

    `crystal run src/secrets-cli.cr -- edit -k a/b/c/d -n "Final Value"`

    response = `crystal run src/secrets-cli.cr -- read -k a/b/c/d`
    assert_equal "Final Value\n", response
  end

  def test_returns_version_number
    response = `crystal run src/secrets-cli.cr -- -v`
    assert_equal "#{Secrets::CLI::VERSION}\n", response
  end

  def test_resets_key
    generate_secrets

    old_key = File.read(@default_key_path)
    `crystal run src/secrets-cli.cr -- reset`
    new_key = File.read(@default_key_path)

    refute_equal old_key, new_key

    secrets = Secrets.new
    assert_equal "WARMACHINEROX", secrets["login"]["password"].as_s
  end

  def test_overall_help
    help = <<-HELP
    Usage: secrets [arguments]
        generate                         Create new secrets and key files
        read                             Read the contents of the encrypted file
        edit                             Edit a value in the encrypted file
        reset                            Resets key and encrypts data with new key
        -h, --help                       Show this help
        -v, --version                    Returns version\n
    HELP

    response = `crystal run src/secrets-cli.cr -- -h`
    assert_equal help, response

    response = `crystal run src/secrets-cli.cr`
    assert_equal help, response
  end

  def test_subcommand_help
    help = <<-HELP
    Usage: secrets generate [arguments]
        -y PATH, --yaml-file PATH        File path
        -f KEY_PATH, --key-file KEY_PATH Key file path
        -h, --help                       Show this help\n
    HELP

    response = `crystal run src/secrets-cli.cr -- generate -h`
    assert_equal help, response

    help = <<-HELP
    Usage: secrets read [arguments]
        -y PATH, --yaml-file PATH        File path
        -f KEY_PATH, --key-file KEY_PATH Key file path
        -k KEY, --key KEY                Key for value(use '/' for nested values)
        -h, --help                       Show this help\n
    HELP

    response = `crystal run src/secrets-cli.cr -- read -h`
    assert_equal help, response

    response = `crystal run src/secrets-cli.cr -- read -k`
    assert_equal help, response

    help = <<-HELP
    Usage: secrets edit [arguments]
        -y PATH, --yaml-file PATH        File path
        -f KEY_PATH, --key-file KEY_PATH Key file path
        -k KEY, --key KEY                Key for value(use '/' for nested values)
        -n VALUE, --new-value VALUE      New Value
        -h, --help                       Show this help\n
    HELP

    response = `crystal run src/secrets-cli.cr -- edit -h`
    assert_equal help, response

    response = `crystal run src/secrets-cli.cr -- edit -k`
    assert_equal help, response

    response = `crystal run src/secrets-cli.cr -- edit`
    assert_equal help, response

    help = <<-HELP
    Usage: secrets reset [arguments]
        -y PATH, --yaml-file PATH        File path
        -f KEY_PATH, --key-file KEY_PATH Key file path
        -h, --help                       Show this help\n
    HELP

    response = `crystal run src/secrets-cli.cr -- reset -h`
    assert_equal help, response
  end
end

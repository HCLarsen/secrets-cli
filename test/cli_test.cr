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
    Secrets::CLI.run(["generate"])

    assert File.exists?(@default_path)
    assert File.exists?(@default_key_path)
  end

  def test_doesnt_overwrite_files
    generate_secrets

    assert_output(stdout: "Error: Secrets file already exists\n") do
      Secrets::CLI.run(["generate"])
    end
  end

  def test_generates_with_custom_paths
    Dir.mkdir_p("config")

    Secrets::CLI.run(["generate", "-y", "config/credentials.yml.enc", "-f", "config/master.key"])
    assert File.exists?("config/credentials.yml.enc")
    assert File.exists?("config/master.key")

    File.delete("config/credentials.yml.enc") if File.exists?("config/credentials.yml.enc")
    File.delete("config/master.key") if File.exists?("config/master.key")
    Dir.delete("config") if Dir.exists?("config")
  end

  def test_reads_file
    generate_secrets

    assert_output(stdout: "---\nlogin:\n  username: warmachine68@starkindustries.com\n  password: WARMACHINEROX\n") do
      Secrets::CLI.run(["read"])
    end

    assert_output(stdout: "---\nusername: warmachine68@starkindustries.com\npassword: WARMACHINEROX\n") do
      Secrets::CLI.run(["read", "-k", "login"])
    end

    assert_output(stdout: "WARMACHINEROX\n") do
      Secrets::CLI.run(["read", "-k", "login/password"])
    end
  end

  def test_outputs_error_reading_invalid_key
    generate_secrets

    assert_output(stdout: "Invalid key: log/password\nPlease verify key for value.\n") do
      Secrets::CLI.run(["read", "-k", "log/password"])
    end

    assert_output(stdout: "Invalid key: login/pass\nPlease verify key for value.\n") do
      Secrets::CLI.run(["read", "-k", "login/pass"])
    end
  end

  def test_edits_file
    generate_secrets

    Secrets::CLI.run(["edit", "-k", "name", "-n", "James Rhodes"])

    assert_output(stdout: "James Rhodes\n") do
      Secrets::CLI.run(["read", "-k", "name"])
    end

    Secrets::CLI.run(["edit", "-k", "login/password", "-n", "TONYSTANK"])

    assert_output(stdout: "TONYSTANK\n") do
      Secrets::CLI.run(["read", "-k", "login/password"])
    end

    Secrets::CLI.run(["edit", "-k", "a/b/c/d", "-n", "Final Value"])

    assert_output(stdout: "Final Value\n") do
      Secrets::CLI.run(["read", "-k", "a/b/c/d"])
    end
  end

  def test_returns_version_number
    assert_output(stdout: "#{Secrets::CLI::VERSION}\n") do
      Secrets::CLI.run(["-v"])
    end
  end

  def test_resets_key
    generate_secrets

    old_key = File.read(@default_key_path)
    Secrets::CLI.run(["reset"])
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

    assert_output(stdout: help) do
      Secrets::CLI.run(["-h"])
    end

    assert_output(stdout: help) do
      Secrets::CLI.run([] of String)
    end
  end
end

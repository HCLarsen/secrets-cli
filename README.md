# Secrets cli

Command line interface for the [Crystal Secrets](https://github.com/HCLarsen/secrets) shard.

## Installation

1. Clone this repo:

```
git clone https://github.com/HCLarsen/secrets.git
```

2. Build:
```
make build-cli
```

3. Move `secrets` file to a location in your $PATH.

## Usage

The Secrets cli provides a way to create, edit, and read encrypted Secrets files.

The `secrets generate` command creates an empty encrypted Secrets file, and a key file. The default location is the folder that the command is run from, however the `-y` and `-f` flags can be used to set specific locations for the Secrets file and key file, respectively.

```
$ secrets generate -y production.yml.enc -f keyfile.key
```

`secrets read` will read the Secrets file and display the contents to the command line. If an optional `-k` value is provided, it will only display the value that corresponds to that key. As with the `generate` command, `-y` and `-f` flags can be used to specify locations for the files.

```
$ secrets read --key API_KEY
```

`secrets edit` requires a key value pair provided as arguments. If they key already exists in the file, it will edit the value with the one provided, otherwise, it will add the key value pair as new entries.

```
$ secrets edit -k API_KEY -n NOTAREALKEY
```

`secrets reset` generates a new key, and re-encrypts the file with the new key. As with the `generate` command, `-y` and `-f` flags can be used to specify locations for the files.

## Contributing

1. Fork it (<https://github.com/HCLarsen/secrets/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Larsen](https://github.com/HCLarsen) - creator and maintainer

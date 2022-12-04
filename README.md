# shared-composite-actions

Makefile and configuration files to facilitate developing Composite Actions

## Description

This repository is a collection of Makefile and configuration files to facilitate developing Composite Actions.
It's designed to work with the `Makefile` that your Composite Action's repository.
It manages the following files:

- [Makefile](/Makefile)
- [.yamllint.yml](/.yamllint.yml)

## Usage

At the top of your Makefile add, the following code:

```makefile
-include .shared/Makefile
.shared/Makefile:
	@git clone https://github.com/tmknom/shared-composite-actions.git .shared >/dev/null 2>&1
```

This will download the `Makefile` and include it at run time.
This automatically exposes new targets that you can leverage throughout your development process.

Run `make` for a list of available targets.
They are useful for developing Composite Action.

```shell
docs                 generate document
fmt                  format code
help                 show help
lint                 lint
release              release new version
```

We strongly recommend adding the `.shared` directory to your `.gitignore`.

```gitignore
# See details:
# https://github.com/tmknom/shared-composite-actions
.shared/
```

## FAQ

N/A

## License

Apache 2 Licensed. See [LICENSE](/LICENSE) for full details.

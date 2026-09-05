# Contributing

Thanks for helping improve AstroUtils.

## Development

Run the standard checks before opening a pull request:

```sh
mix format --check-formatted
mix test
mix credo --strict
```

Public functions should include `@spec` and clear documentation. Keep changes
focused, add or update tests for behavior changes, and avoid adding runtime
dependencies unless they are necessary for the library itself.

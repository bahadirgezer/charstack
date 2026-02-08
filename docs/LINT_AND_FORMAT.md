# Lint and Format

Use the following commands to lint and format the codebase:

```bash 
swift-format format \
  --recursive \
  --configuration .swift-format \
  .
```

```bash
swiftlint lint --strict
```


## If you want to auto-correct lint issues:

```bash
swiftlint lint --strict --autocorrect
```

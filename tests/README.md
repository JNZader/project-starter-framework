# Tests

## Requisitos

- [Bats](https://github.com/bats-core/bats-core) para tests bash
- [Pester](https://pester.dev/) para tests PowerShell (futuro)

## Ejecutar

```bash
# Instalar Bats
npm install -g bats

# Ejecutar tests
bats tests/framework.bats

# O desde el framework root
bats tests/
```

## Validar framework

```bash
./scripts/validate-framework.sh
```

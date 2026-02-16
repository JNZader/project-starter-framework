# Contributing to Project Starter Framework

Thank you for considering contributing to this project.

## How to Contribute

### Reporting Bugs

- Use GitHub Issues
- Include framework version
- Provide reproduction steps
- Share relevant logs/output

### Suggesting Enhancements

- Check existing issues first
- Explain the use case
- Provide examples if possible

### Code Contributions

#### Setup

```bash
git clone https://github.com/JNZader/project-starter-framework.git
cd project-starter-framework
```

#### Testing Your Changes

Test across:
- Multiple stacks (Java, Node, Python, Go, Rust)
- Both Windows (PowerShell) and Linux/Mac (Bash)
- Different project structures

#### Pull Request Process

1. Fork the repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Make changes
4. Test thoroughly
5. Commit using conventional commits:
   ```
   feat(ci-local): add Rust support
   fix(scripts): handle spaces in paths
   docs(readme): clarify installation steps
   ```
6. Push and create PR
7. Wait for review

### Adding New CI Templates

1. Add template to `templates/github/` or `templates/gitlab/`
2. Update `templates/README.md`
3. Test with a real project
4. Document parameters

### Adding New Agents/Skills

1. Follow template in `.ai-config/agents/_TEMPLATE.md` or `.ai-config/skills/_TEMPLATE.md`
2. Update `.ai-config/README.md`
3. Update `AUTO_INVOKE.md` if applicable
4. Test with target CLI (Claude Code, OpenCode, etc.)

### Proceso Completo para Agents/Skills

#### Paso 1: Elegir Template
```bash
# Para agentes
cp .ai-config/agents/_TEMPLATE.md .ai-config/agents/categoria/nuevo-agente.md

# Para skills
cp .ai-config/skills/_TEMPLATE.md .ai-config/skills/categoria/nuevo-skill.md
```

#### Paso 2: Definir Metadata (YAML frontmatter)
- **name**: identificador en kebab-case
- **description**: incluir "Trigger:" para auto-invoke
- **metadata**: author, version, tags

#### Paso 3: Escribir Contenido
- Seccion "When to Use" (requerido)
- Seccion "Critical Patterns" (requerido)
- Seccion "Related Skills" (para cross-references)

#### Paso 4: Validar y Testear
```bash
./scripts/sync-skills.sh validate
./scripts/sync-ai-config.sh all
```

## Code Style

- **Shell scripts**: Follow ShellCheck recommendations
- **PowerShell**: Follow PSScriptAnalyzer rules
- **YAML**: Use consistent indentation (2 spaces)
- **Markdown**: One sentence per line preferred

## Cross-Platform Compatibility

When modifying scripts:

- Always provide both `.sh` (Bash) and `.ps1` (PowerShell) versions
- Test `sed` commands on both Linux and macOS (use `sed -i''` for portability)
- Avoid Bash-only features like `grep -P` (use `grep -E` instead)
- Test PowerShell scripts on both Windows PowerShell and PowerShell Core

## Questions?

Open a GitHub Issue or Discussion.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

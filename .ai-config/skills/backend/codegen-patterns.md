---
name: codegen-patterns
description: >
  Patrones de generación de código para múltiples lenguajes. TypeMappers, NamingUtils, Features.
  Trigger: generador código, type mapper, naming utils, features, language generator
tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
metadata:
  author: apigen-team
  version: "1.0"
  tags: [codegen, patterns, generators]
  scope: ["apigen-codegen/**"]
---

# Code Generation Patterns

## Generator Interface

```java
public interface LanguageGenerator {
    GeneratedProject generate(GenerationContext context);
    String getLanguageId();
    String getFramework();
    Set<Feature> getSupportedFeatures();
}
```

## AbstractLanguageGenerator

```java
public abstract class AbstractLanguageGenerator implements LanguageGenerator {

    protected final TemplateEngine templateEngine;
    protected final AbstractLanguageTypeMapper typeMapper;

    @Override
    public GeneratedProject generate(GenerationContext context) {
        GeneratedProject project = new GeneratedProject();

        for (TableDefinition table : context.getTables()) {
            EntityContext entityContext = buildEntityContext(table, context);

            project.addFile(generateEntity(entityContext));
            project.addFile(generateDto(entityContext));
            project.addFile(generateRepository(entityContext));
            project.addFile(generateService(entityContext));
            project.addFile(generateController(entityContext));

            if (supportsFeature(Feature.MAPPER)) {
                project.addFile(generateMapper(entityContext));
            }
        }

        project.addFiles(generateProjectFiles(context));
        return project;
    }

    protected abstract GeneratedFile generateEntity(EntityContext context);
    protected abstract GeneratedFile generateDto(EntityContext context);
    // ...
}
```

## TypeMapper Pattern

```java
public abstract class AbstractLanguageTypeMapper {

    public String mapType(ColumnDefinition column) {
        String sqlType = column.getType().toUpperCase();
        String mappedType = getTypeMapping().getOrDefault(sqlType, getDefaultType());

        if (column.isNullable() && supportsNullableWrapper()) {
            return wrapNullable(mappedType);
        }
        return mappedType;
    }

    protected abstract Map<String, String> getTypeMapping();
    protected abstract String getDefaultType();
    protected abstract boolean supportsNullableWrapper();
    protected abstract String wrapNullable(String type);
}

// Java
public class JavaTypeMapper extends AbstractLanguageTypeMapper {
    @Override
    protected Map<String, String> getTypeMapping() {
        return Map.of(
            "VARCHAR", "String",
            "TEXT", "String",
            "INTEGER", "Integer",
            "BIGINT", "Long",
            "BOOLEAN", "Boolean",
            "TIMESTAMP", "Instant",
            "UUID", "UUID",
            "JSONB", "JsonNode"
        );
    }
}

// TypeScript
public class TypeScriptTypeMapper extends AbstractLanguageTypeMapper {
    @Override
    protected Map<String, String> getTypeMapping() {
        return Map.of(
            "VARCHAR", "string",
            "TEXT", "string",
            "INTEGER", "number",
            "BIGINT", "bigint",
            "BOOLEAN", "boolean",
            "TIMESTAMP", "Date",
            "UUID", "string",
            "JSONB", "Record<string, unknown>"
        );
    }
}
```

## NamingUtils

```java
public final class NamingUtils {

    public static String toPascalCase(String input) {
        // user_name → UserName
        return Arrays.stream(input.split("[_\\-\\s]+"))
            .map(word -> capitalize(word.toLowerCase()))
            .collect(Collectors.joining());
    }

    public static String toCamelCase(String input) {
        // user_name → userName
        String pascal = toPascalCase(input);
        return Character.toLowerCase(pascal.charAt(0)) + pascal.substring(1);
    }

    public static String toSnakeCase(String input) {
        // UserName → user_name
        return input.replaceAll("([a-z])([A-Z])", "$1_$2").toLowerCase();
    }

    public static String toKebabCase(String input) {
        // UserName → user-name
        return toSnakeCase(input).replace('_', '-');
    }

    public static String toPlural(String input) {
        if (input.endsWith("y") && !input.endsWith("ay") && !input.endsWith("ey")) {
            return input.substring(0, input.length() - 1) + "ies";
        }
        if (input.endsWith("s") || input.endsWith("x") || input.endsWith("ch") || input.endsWith("sh")) {
            return input + "es";
        }
        return input + "s";
    }

    public static boolean isAuditField(String columnName) {
        return Set.of("created_at", "updated_at", "created_by", "updated_by", "deleted_at")
            .contains(columnName.toLowerCase());
    }
}
```

## Feature Enum

```java
public enum Feature {
    // Core
    CRUD,
    ONE_TO_MANY,
    MANY_TO_ONE,
    MANY_TO_MANY,

    // API
    HATEOAS,
    OPENAPI,

    // Auth
    JWT_AUTH,
    OAUTH2,
    SOCIAL_LOGIN,
    PASSWORD_RESET,

    // Performance
    CACHING,
    ETAG_CACHING,
    RATE_LIMITING,

    // Data
    SOFT_DELETE,
    AUDITING,
    MIGRATIONS,
    BATCH_OPERATIONS,

    // Services
    MAIL_SERVICE,
    FILE_UPLOAD,
    S3_STORAGE,
    AZURE_STORAGE
}

// En cada generador
public class JavaSpringGenerator extends AbstractLanguageGenerator {
    @Override
    public Set<Feature> getSupportedFeatures() {
        return Set.of(
            Feature.CRUD, Feature.ONE_TO_MANY, Feature.MANY_TO_ONE, Feature.MANY_TO_MANY,
            Feature.HATEOAS, Feature.OPENAPI,
            Feature.JWT_AUTH, Feature.OAUTH2, Feature.SOCIAL_LOGIN,
            Feature.CACHING, Feature.ETAG_CACHING, Feature.RATE_LIMITING,
            Feature.SOFT_DELETE, Feature.AUDITING, Feature.MIGRATIONS, Feature.BATCH_OPERATIONS,
            Feature.MAIL_SERVICE, Feature.FILE_UPLOAD, Feature.S3_STORAGE, Feature.AZURE_STORAGE
        );
    }
}
```

## RelationshipUtils

```java
public final class RelationshipUtils {

    public static Map<String, List<RelationshipDefinition>> buildRelationshipsByTable(
            List<TableDefinition> tables) {

        Map<String, List<RelationshipDefinition>> result = new HashMap<>();

        for (TableDefinition table : tables) {
            List<RelationshipDefinition> relationships = new ArrayList<>();

            for (ColumnDefinition column : table.getColumns()) {
                if (column.isForeignKey()) {
                    relationships.add(RelationshipDefinition.builder()
                        .type(RelationshipType.MANY_TO_ONE)
                        .sourceTable(table.getName())
                        .sourceColumn(column.getName())
                        .targetTable(column.getReferencedTable())
                        .targetColumn(column.getReferencedColumn())
                        .build());
                }
            }

            result.put(table.getName(), relationships);
        }

        return result;
    }

    public static List<RelationshipDefinition> findInverseRelationships(
            String tableName, Map<String, List<RelationshipDefinition>> allRelationships) {

        return allRelationships.values().stream()
            .flatMap(List::stream)
            .filter(rel -> rel.getTargetTable().equals(tableName))
            .map(rel -> RelationshipDefinition.builder()
                .type(RelationshipType.ONE_TO_MANY)
                .sourceTable(tableName)
                .targetTable(rel.getSourceTable())
                .mappedBy(NamingUtils.toCamelCase(tableName))
                .build())
            .toList();
    }
}
```

## Checklist Nuevo Generador

- [ ] Extender AbstractLanguageGenerator
- [ ] Implementar TypeMapper específico
- [ ] Crear templates en resources/templates/{lang}/
- [ ] Definir getSupportedFeatures()
- [ ] Tests de generación
- [ ] Test de compilación del código generado
- [ ] Documentar en README

## Related Skills

- `mustache-templates`: Desarrollo de templates
- `apigen-codegen-dev`: Desarrollo del módulo


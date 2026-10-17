# Generated code ownership

Generated declarations are compiled normally. Their folders and project metadata
separate ownership without changing CLR types, SQL mappings, routes, or page URLs.

| Generator input | Generated output | Location |
| --- | --- | --- |
| `Prosto_ERP_DataClasses.dbml` | `Prosto_ERP_DataClasses.designer.vb` | `src/ProstoERP.Infrastructure/Generated/LinqToSql` |
| WebForms `.aspx`, `.ascx`, or `.Master` markup | Matching `.designer.vb` control declarations | Beside the markup under `src/Portal` |
| `Application.myapp`, `Resources.resx`, `Settings.settings` | Matching `.Designer.vb` files | Each VB project's `My Project` directory |

The DBML layout stays beside its DBML input. `DependentUpon`, `Generator`, and
`LastGenOutput` relationships are retained. Page designers remain adjacent to
markup for IDE nesting and regeneration. Resource and settings files retain their
standard project locations and existing resource names/settings identities.

## Handwritten changes

Put feature behavior in the existing `Features/<feature>` files. Use a separate
partial class file for customizations to generated partial types, with the same
namespace and type name. Never place business behavior in a designer file.
Page event handlers belong in the existing code-behind, not the control designer.

Edit generator inputs when declarations must change, then regenerate with a
compatible tool and review the resulting diff. Preserve the Infrastructure VB
root namespace `Prosto_ERP_ClassLibrary` and the existing DataContext/type names;
folder names must not become additional CLR namespaces during regeneration.
Do not regenerate the production mappings from the limited local development
database: it does not contain the complete original schema or procedure contracts.
This cleanup only relocates existing mappings; it does not regenerate them.

## Editor and repository handling

Both VB projects mark designer Compile items with `AutoGen` and `DesignTime`.
The root `.editorconfig` marks designer source as generated and leaves its
formatting untouched. `.gitattributes` marks VB designer files as generated for
repository tools. These settings do not exclude the source from compilation.

Infrastructure's local `My Project/Settings.settings` and `Settings.Designer.vb`
remain ignored because they contain local connection settings. Their sanitized
`.example` templates remain the setup inputs. Never copy credentials into a
tracked generated file or its template.

`scripts/generate_development_schema.py` reads the relocated DBML. Its output under
`database/development` is a separate, limited development baseline; generating or
applying it is not part of this organizational cleanup.

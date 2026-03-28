# Quick Vault Capture

Capture notes into the Obsidian vault at `/Users/przbadu/Documents/Obsidian` from any working directory.

## Workflow

1. Determine note type from context (work, idea, reference, career, learning, personal)
2. Read template from `note-templates.md` in this references directory
3. Generate frontmatter with today's date and appropriate fields
4. Determine target folder using category-to-folder mapping from `vault-config.md`
5. Create the note file with kebab-case filename
6. Suggest wikilinks to existing related notes (confirm before inserting)
7. Report: file path, category, folder, tags assigned

## Capture Modes

**Interactive (default):** Ask for title and content, infer type from context.

**One-liner:** User provides everything inline.
Example: `"capture idea: Build an AI-powered invoice validator for PE"`
Creates `ideas/ai-powered-invoice-validator.md` with idea template.

**From context:** User is working in another project and says "save this to my vault."
Capture the relevant context (code snippet, concept, decision) as a reference note.

## Type Detection

Infer note type from keywords and context:
- Mentions PE, ProcurementExpress, work, meeting, sprint → **work**
- Mentions idea, what if, business, build → **idea**
- Mentions how-to, setup, config, reference, docs → **reference**
- Mentions career, skill, job, interview, resume → **career**
- Mentions learn, course, tutorial, concept → **learning**
- Default or personal topics → **personal**

## Target Folder Selection

| Category | Target | Subfolder Logic |
|----------|--------|----------------|
| work | `ProcurementExpress/` | `wiki/` for docs, root for tasks/meetings |
| idea | `ideas/` | — |
| reference | `second-brain/notes/` | — |
| career | `AI-Career-Levelup/` | — |
| learning | Context-dependent | `genai-bootcamp/` for AI, `daily-dose-of-ds/` for DS, `second-brain/` otherwise |
| personal | `second-brain/` | — |

## Frontmatter Generation

Always include required fields. Set `created` and `modified` to today. Infer tags from title and content (max 5). Ask before adding any NEW tag not already used in the vault.

To check existing tags: `rg -o 'tags: \[.*?\]' /Users/przbadu/Documents/Obsidian --glob '*.md' --no-filename | sort -u`

## Wikilink Suggestions

After creating the note, scan for potential wikilinks:
1. Get existing note titles: `find /Users/przbadu/Documents/Obsidian -name '*.md' -not -path '*/.obsidian/*' -not -path '*/_trash/*' | xargs -I{} basename {} .md`
2. Check if any title appears in new note's content
3. Present matches, ask user which to convert to `[[wikilinks]]`

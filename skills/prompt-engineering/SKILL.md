---
name: prompt-engineering
description: Use when writing or improving prompts, agent instructions, commands, hooks, skills, or other LLM interactions.
---

# Prompt Engineering Patterns

Practical patterns for making prompts clear, bounded, and verifiable. A prompt can guide behavior, but it does not guarantee correctness; evaluate important prompts against representative inputs and observable outcomes.

## Core Capabilities

### 1. Few-Shot Learning

Show examples when they clarify the desired output or an important edge case. Use only as many as the task needs; examples that are irrelevant or contradictory can make a prompt less clear.

**Example:**

```markdown
Extract key information from support tickets:

Input: "My login doesn't work and I keep getting error 403"
Output: {"issue": "authentication", "error_code": "403", "priority": "high"}

Input: "Feature request: add dark mode to settings"
Output: {"issue": "feature_request", "error_code": null, "priority": "low"}

Now process: "Can't upload files larger than 10MB, getting timeout"
```

### 2. Ask for Observable Rationale and Evidence

Do not request hidden chain-of-thought or private reasoning traces. When a task needs explanation, ask for a concise, checkable summary: the decision, material assumptions, evidence or sources, verification performed, uncertainty, and unresolved issues. Specify observable acceptance criteria rather than requiring a particular internal reasoning process.

**Example:**

```markdown
Analyze this bug report and determine root cause.

Provide a concise diagnosis with:
1. Expected and observed behavior
2. Relevant changes or evidence found
3. Likely cause and uncertainty
4. A check that would confirm or disprove the cause

Bug: "Users can't save drafts after the cache update deployed yesterday"
```

### 3. Prompt Optimization

Improve prompts through task-specific evaluation. Start simple, define observable success measures, and evaluate on representative inputs and edge cases. Compare variants only when results can be measured meaningfully; do not infer a general performance gain from a small or unrepresentative sample.

**Example:**

```markdown
Version 1 (Simple): "Summarize this article"
→ Result: Inconsistent length, misses key points

Version 2 (Add constraints): "Summarize in 3 bullet points"
→ Result: Better structure, but still misses nuance

Version 3 (Add reasoning): "Identify the 3 main findings, then summarize each"
→ Result: Consistent, accurate, captures key information
```

### 4. Template Systems

Build reusable prompt structures with variables, conditional sections, and modular components. Use for multi-turn conversations, role-based interactions, or when the same pattern applies to different inputs. Reduces duplication and ensures consistency across similar tasks.

**Example:**

```python
# Reusable code review template
template = """
Review this {language} code for {focus_area}.

Code:
{code_block}

Provide feedback on:
{checklist}
"""

# Usage
prompt = template.format(
    language="Python",
    focus_area="security vulnerabilities",
    code_block=user_code,
    checklist="1. SQL injection\n2. XSS risks\n3. Authentication"
)
```

### 5. System Prompt Design

Set global behavior and constraints that persist across the conversation. Define the model's role, expertise level, output format, and safety guidelines. Use system prompts for stable instructions that shouldn't change turn-to-turn, freeing up user message tokens for variable content.

**Example:**

```markdown
System: You are a senior backend engineer specializing in API design.

Rules:
- Always consider scalability and performance
- Suggest RESTful patterns by default
- Flag security concerns immediately
- Provide code examples in Python
- Use early return pattern

Format responses as:
1. Analysis
2. Recommendation
3. Code example
4. Trade-offs
```

## Key Patterns

### Progressive Disclosure

Start with simple prompts, add complexity only when needed:

1. **Level 1**: Direct instruction
   - "Summarize this article"

2. **Level 2**: Add constraints
   - "Summarize this article in 3 bullet points, focusing on key findings"

3. **Level 3**: Add reasoning
   - "Summarize the article in 3 bullet points and cite the passages supporting each point"

4. **Level 4**: Add examples
   - Include 2-3 example summaries with input-output pairs

### Instruction Hierarchy

```
[System Context] → [Task Instruction] → [Examples] → [Input Data] → [Output Format]
```

### Error Recovery

Build prompts that gracefully handle failures:

- Include fallback instructions
- Ask for uncertainty and its basis; avoid numeric confidence scores unless they are calibrated and useful for the task
- Ask for alternative interpretations when uncertain
- Specify how to indicate missing information

## Best Practices

1. **Be Specific**: Vague prompts produce inconsistent results
2. **Show, Don't Tell**: Examples are more effective than descriptions
3. **Test Extensively**: Evaluate on diverse, representative inputs
4. **Iterate Rapidly**: Small changes can have large impacts
5. **Monitor Performance**: Track metrics in production
6. **Version Control**: Treat prompts as code with proper versioning
7. **Document Intent**: Explain why prompts are structured as they are

## Common Pitfalls

- **Over-engineering**: Starting with complex prompts before trying simple ones
- **Example pollution**: Using examples that don't match the target task
- **Context overflow**: Exceeding token limits with excessive examples
- **Ambiguous instructions**: Leaving room for multiple interpretations
- **Ignoring edge cases**: Not testing on unusual or boundary inputs

## Integration Patterns

### With RAG Systems

```python
# Combine retrieved context with prompt engineering
prompt = f"""Given the following context:
{retrieved_context}

{few_shot_examples}

Question: {user_question}

Provide a detailed answer based solely on the context above. If the context doesn't contain enough information, explicitly state what's missing."""
```

### With Validation

```python
# Add self-verification step
prompt = f"""{main_task_prompt}

After generating your response, verify it meets these criteria:
1. Answers the question directly
2. Uses only information from provided context
3. Cites specific sources
4. Acknowledges any uncertainty

If verification fails, revise your response."""
```

## Performance Optimization

### Token Efficiency

- Remove redundant words and phrases
- Use abbreviations consistently after first definition
- Consolidate similar instructions
- Move stable content to system prompts

### Latency Reduction

- Minimize prompt length without sacrificing quality
- Use streaming for long-form outputs
- Cache common prompt prefixes
- Batch similar requests when possible

---

# Agent Prompting Best Practices

Provider-agnostic patterns for agent prompts.

## Core principles

### Context Window

The “context window” refers to the entirety of the amount of text a language model can look back on and reference when generating new text plus the new text it generates. This is different from the large corpus of data the language model was trained on, and instead represents a “working memory” for the model. A larger context window allows the model to understand and respond to more complex and lengthy prompts, while a smaller context window may limit the model’s ability to handle longer prompts or maintain coherence over extended conversations.

- The usable context is bounded by the model and serving system. Earlier messages or files may be unavailable, truncated, or summarized; do not assume complete history or a fixed capacity.
- Put essential requirements in the active prompt or an authoritative project artifact, and verify important facts from their source.

### Concise is key

Available context is shared among instructions, conversation, tools, and task data. Keep prompts focused and include task-specific facts that are not reliably available elsewhere:

- The system prompt
- Conversation history
- Other commands, skills, hooks, metadata
- Your actual request

**Default assumption**: the model can handle ordinary instructions, but may not know private project facts or have access to a named tool.

Challenge each piece of information:

- "Does the model need this explanation for this task?"
- "Is this fact available from the task context or an accessible source?"
- "Does this paragraph justify its token cost?"

**Good example: Concise** (approximately 50 tokens):

````markdown  theme={null}
## Extract PDF text

Use pdfplumber for text extraction:

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

**Bad example: Too verbose** (approximately 150 tokens):

```markdown  theme={null}
## Extract PDF text

PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available for PDF processing, but we
recommend pdfplumber because it's easy to use and handles most cases well.
First, you'll need to install it using pip. Then you can use the code below...
```

The concise version leaves out background the task does not need while keeping the concrete operation.

### Set appropriate degrees of freedom

Match the level of specificity to the task's fragility and variability.

**High freedom** (text-based instructions):

Use when:

- Multiple approaches are valid
- Decisions depend on context
- Heuristics guide the approach

Example:

```markdown  theme={null}
## Code review process

1. Analyze the code structure and organization
2. Check for potential bugs or edge cases
3. Suggest improvements for readability and maintainability
4. Verify adherence to project conventions
```

**Medium freedom** (pseudocode or scripts with parameters):

Use when:

- A preferred pattern exists
- Some variation is acceptable
- Configuration affects behavior

Example:

````markdown  theme={null}
## Generate report

Use this template and customize as needed:

```python
def generate_report(data, format="markdown", include_charts=True):
    # Process data
    # Generate output in specified format
    # Optionally include visualizations
```
````

**Low freedom** (specific scripts, few or no parameters):

Use when:

- Operations are fragile and error-prone
- Consistency is critical
- A specific sequence must be followed

Example:

````markdown  theme={null}
## Database migration

Run exactly this script:

```bash
python scripts/migrate.py --verify --backup
```

Do not modify the command or add additional flags.
````

**Analogy**: Think of the task as a path with varying constraints:

- **Narrow bridge with cliffs on both sides**: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). Example: database migrations that must run in exact sequence.
- **Open field with no hazards**: Many paths lead to success. Give general direction and allow the model to use evidence and project conventions (high freedom). Example: code reviews where context determines the best approach.

# Clear and Trustworthy Instructions

State the actual requirement, its source or scope, and observable success criteria. Use emphatic language only for genuine requirements; do not add false urgency, social pressure, forced choices, or announcements as a substitute for a clear task contract.

For multi-step work, name real dependencies and the checks that matter. Request an external approval only when the task, user, or governing workflow actually requires one. Ask for a concise explanation of decisions and evidence when useful, not private reasoning traces.

## Quick Reference

When designing a prompt, ask:

1. **What outcome should the prompt produce?**
2. **Which facts, tools, and constraints are actually available?**
3. **What observable criteria show success or failure?**
4. **What uncertainty should be surfaced instead of guessed?**

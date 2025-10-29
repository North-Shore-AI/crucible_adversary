# CrucibleAdversary Examples

This directory contains comprehensive examples demonstrating all features of CrucibleAdversary.

## Running Examples

All examples can be run directly with `mix run`:

```bash
# Run from the project root
mix run examples/quickstart.exs
mix run examples/basic_attacks.exs
mix run examples/defense_pipeline.exs
mix run examples/model_evaluation.exs
mix run examples/advanced_attacks.exs
```

## Available Examples

### 1. quickstart.exs
**Best for**: First-time users wanting a quick overview

A simple introduction covering:
- Single attacks
- Batch processing
- Model evaluation
- Defense pipeline
- Configuration

**Run time**: ~1 second

### 2. basic_attacks.exs
**Best for**: Understanding all available attack types

Demonstrates all 21 attack types:
- Character-level perturbations (5 types)
- Word-level perturbations (4 types)
- Semantic perturbations (4 types)
- Prompt injection attacks (4 types)
- Jailbreak techniques (4 types)

**Run time**: ~2 seconds

### 3. defense_pipeline.exs
**Best for**: Implementing security defenses

Shows how to use defense mechanisms:
- Attack detection with risk scoring
- Input filtering (strict/permissive modes)
- Input sanitization strategies
- Complete defense pipeline
- Defense effectiveness metrics

**Run time**: ~1 second

### 4. model_evaluation.exs
**Best for**: Evaluating model robustness

Comprehensive robustness evaluation:
- Model evaluation setup
- Accuracy drop analysis
- Attack success rate metrics
- Vulnerability identification
- Model comparison
- Batch processing
- Evaluation recommendations

**Run time**: ~2 seconds

### 5. advanced_attacks.exs
**Best for**: Advanced attack techniques

Advanced features:
- Attack composition and chaining
- Systematic attack testing
- Adversarial training data generation
- Targeted attack scenarios
- Robustness testing
- Multi-modal combinations
- Performance benchmarking

**Run time**: ~3 seconds

## Example Output

Each example produces detailed output showing:
- Original and attacked text
- Metric calculations
- Visual comparisons
- Performance statistics
- Recommendations

## Usage Patterns

### For Security Testing
1. Start with `defense_pipeline.exs`
2. Use `basic_attacks.exs` to understand attack vectors
3. Apply defenses to your system

### For Model Development
1. Start with `quickstart.exs`
2. Use `model_evaluation.exs` for your model
3. Use `advanced_attacks.exs` for data augmentation

### For Research
1. Run all examples to understand capabilities
2. Focus on `model_evaluation.exs` for benchmarking
3. Use `advanced_attacks.exs` for custom experiments

## Integration with Your Code

All examples are self-contained but can be adapted:

```elixir
# Your model
defmodule MyModel do
  def predict(input) do
    # Your prediction logic
  end
end

# Evaluate it
test_set = [
  {"input1", :expected1},
  {"input2", :expected2}
]

{:ok, eval} = CrucibleAdversary.evaluate(
  MyModel,
  test_set,
  attacks: [:character_swap, :word_deletion],
  metrics: [:accuracy_drop, :asr]
)
```

## Requirements

- Elixir 1.14+
- CrucibleAdversary installed (`mix deps.get`)

## Troubleshooting

If you encounter issues:

1. Ensure dependencies are installed:
   ```bash
   mix deps.get
   ```

2. Compile the project:
   ```bash
   mix compile
   ```

3. Run tests to verify installation:
   ```bash
   mix test
   ```

## Contributing

Feel free to add more examples! Follow the existing pattern:
- Clear section headers
- Explanatory output
- Progressive complexity
- Practical use cases

## License

Same as CrucibleAdversary - MIT License

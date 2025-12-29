# Changelog

All notable changes to CrucibleAdversary will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-11-26

### Added

#### CrucibleIR Integration
- `CrucibleAdversary.Stage` - Pipeline stage for adversarial robustness testing
- Integration with CrucibleIR's pipeline architecture
- Composable adversarial evaluation as a pipeline stage
- Context-based configuration and result propagation

#### Dependencies
- Added `crucible_ir ~> 0.1.1` dependency for pipeline integration

### Features
- **Pipeline Composability**: Use adversarial testing in CrucibleIR pipelines
- **Context Preservation**: Stage preserves and augments pipeline context
- **Flexible Configuration**: Configure attacks, metrics, and options via context or opts
- **Chainable Stages**: Seamlessly chain with other CrucibleIR pipeline stages

### Testing
- 20+ new tests for Stage module
- Total: 298+ tests (278 → 298+)
- Integration tests for CrucibleIR pipeline compatibility
- Tests for context preservation and augmentation

### Documentation
- Complete API documentation for Stage module
- Usage examples for pipeline integration
- Stage description functionality

### Code Quality
- Added Credo for static analysis (`mix credo --strict` passes)
- Refactored aliases to alphabetical one-per-line format
- Replaced `Enum.map |> Enum.join` with `Enum.map_join`
- Renamed `is_safe?/2` to `safe?/2` per Elixir naming conventions
- Converted large case statements to pattern-matched function clauses
- Replaced `length(list) == 0` guards with `list == []`

### Quality Gates
- ✅ All Stage functionality fully tested
- ✅ Backwards compatible with v0.3.0
- ✅ Zero breaking changes
- ✅ CrucibleIR integration tested
- ✅ Credo strict mode passes

## [0.3.0] - 2025-11-25

### Added

#### Data Extraction Attacks
- `Extraction.repetition_attack/2` - Exploit repetition to trigger memorized continuations
- `Extraction.memorization_probe/2` - Test for memorized training examples
- `Extraction.pii_extraction/2` - Attempt to extract personally identifiable information
- `Extraction.context_confusion/2` - Use context manipulation to leak information

#### Model Inversion Attacks
- `Inversion.membership_inference/3` - Determine if data was in training set
- `Inversion.attribute_inference/3` - Infer attributes of training examples
- `Inversion.reconstruction_attack/3` - Reconstruct training features from outputs
- `Inversion.property_inference/3` - Infer dataset-level properties

#### Certified Robustness Metrics
- `Certified.randomized_smoothing/3` - Provable robustness guarantees via randomized smoothing
- `Certified.certified_accuracy/3` - Certified accuracy on test sets
- `Certified.certification_level/1` - Classification of certification quality
- `Certified.compute_radius/2` - Theoretical robustness radius calculation

#### Attack Composition Framework
- `Composition.chain/1` - Sequential attack chaining
- `Composition.execute/2` - Execute attack chains
- `Composition.parallel/1` - Parallel attack specification
- `Composition.execute_parallel/2` - Execute attacks in parallel
- `Composition.best_of/3` - Select best result from multiple attacks
- `Composition.conditional/3` - Conditional attack execution

### Features
- **25 Total Attack Types**: Added 4 data extraction + model inversion capabilities
- **Certified Robustness**: Research-grade provable guarantees
- **Attack Composition**: Sophisticated multi-stage attack strategies
- **Enhanced API**: Main API updated to support all new attack types

### Testing
- 75+ new tests added (covering all new modules)
- Total: 278+ tests (203 → 278+)
- Comprehensive test coverage for new features
- Property-based testing for statistical metrics

### Documentation
- Complete design document: `docs/20251125/ENHANCEMENTS_DESIGN.md`
- Updated README with new features and attack counts
- API documentation for all new modules
- Usage examples for composition and certified metrics

### Quality Gates
- ✅ All new modules fully documented
- ✅ TDD methodology followed throughout
- ✅ Backwards compatible with v0.2.0
- ✅ Zero breaking changes

## [0.2.0] - 2025-10-20

### Added

#### Prompt Injection Attacks
- `Injection.basic/2` - Direct instruction override with configurable strategies
- `Injection.context_overflow/2` - Context window flooding attacks
- `Injection.delimiter_attack/2` - Delimiter confusion techniques
- `Injection.template_injection/2` - Template variable exploitation

#### Jailbreak Techniques
- `Jailbreak.roleplay/2` - Persona-based bypass (DAN, etc.)
- `Jailbreak.context_switch/2` - Context manipulation attacks
- `Jailbreak.encode/2` - Obfuscation encoding (Base64, ROT13, hex, leetspeak)
- `Jailbreak.hypothetical/2` - Hypothetical scenario framing

#### Semantic Perturbations
- `Semantic.paraphrase/2` - Semantic-preserving paraphrasing
- `Semantic.back_translate/2` - Back-translation artifact simulation
- `Semantic.sentence_reorder/2` - Sentence order shuffling
- `Semantic.formality_change/2` - Formality level transformation

#### Defense Mechanisms
- `Detection.detect_attack/2` - Multi-pattern adversarial detection
  - Prompt injection keyword detection
  - Delimiter pattern detection
  - Roleplay/jailbreak detection
  - Encoding detection
  - Risk level classification
- `Detection.calculate_risk_level/1` - Risk score calculation
- `Detection.detect_pattern/2` - Individual pattern detection
- `Filtering.filter_input/2` - Input filtering based on detected patterns
  - Strict and permissive modes
  - Configurable pattern lists
- `Filtering.is_safe?/2` - Safety check for inputs
- `Sanitization.sanitize/2` - Input sanitization with multiple strategies
  - Delimiter removal
  - Whitespace normalization
  - Length limiting
  - Special character removal
- `Sanitization.remove_patterns/2` - Pattern removal utility

### Features
- **21 Total Attack Types**: Complete adversarial testing arsenal
- **Defense-in-Depth**: Detection → Filtering → Sanitization pipeline
- **Configurable Defenses**: Adjustable strictness and patterns
- **Production Security**: Ready for real-world deployment protection

### Testing
- 85 new tests (32 attacks + 32 defenses + 21 integration)
- Total: 203 tests, 0 failures
- 88.70% code coverage
- 100% coverage on core defense modules
- Comprehensive integration tests for all attack types

### Quality Gates
- ✅ 88.70% test coverage (exceeds 80% requirement)
- ✅ Zero compilation warnings
- ✅ Zero Dialyzer errors
- ✅ All attack types tested
- ✅ Complete defense pipeline
- ✅ Production-ready

## [0.1.0] - 2025-10-20

### Added

#### Core Data Structures
- `AttackResult` struct with comprehensive metadata support
- `EvaluationResult` struct for robustness evaluation results
- `Config` struct with validation for framework configuration

#### Character-Level Perturbations
- `Character.swap/2` - Adjacent character swapping with configurable rate
- `Character.delete/2` - Character deletion with optional space preservation
- `Character.insert/2` - Character insertion with custom character pools
- `Character.homoglyph/2` - Unicode homoglyph substitution (Cyrillic, Greek charsets)
- `Character.keyboard_typo/2` - Realistic keyboard-based typos (QWERTY/Dvorak layouts)

#### Word-Level Perturbations
- `Word.delete/2` - Word deletion with stopword preservation option
- `Word.insert/2` - Word insertion with custom dictionaries
- `Word.synonym_replace/2` - Synonym replacement using built-in dictionary
- `Word.shuffle/2` - Word order shuffling (random and adjacent-only strategies)

#### Robustness Metrics
- `Accuracy.drop/2` - Accuracy drop calculation with severity classification
- `Accuracy.robust_accuracy/2` - Robust accuracy on adversarial examples
- `ASR.calculate/2` - Attack success rate with per-type breakdown
- `ASR.query_efficiency/2` - Query efficiency metrics
- `Consistency.semantic_similarity/3` - Jaccard and Levenshtein distance similarity
- `Consistency.consistency/3` - Output consistency statistics (mean, median, std)

#### Evaluation Framework
- `Robustness.evaluate/3` - Comprehensive robustness evaluation orchestration
- `Robustness.evaluate_single/3` - Single input evaluation with multiple attacks
- Vulnerability identification based on metrics
- Support for both function and module-based models

#### Main API
- `CrucibleAdversary.attack/2` - Single attack execution
- `CrucibleAdversary.attack_batch/2` - Batch attack processing
- `CrucibleAdversary.evaluate/3` - Model robustness evaluation
- `CrucibleAdversary.config/0` - Configuration retrieval
- `CrucibleAdversary.configure/1` - Configuration management
- `CrucibleAdversary.version/0` - Version information

### Features
- **Reproducible Results**: All attacks support random seeding
- **Type Safety**: Comprehensive `@spec` annotations throughout
- **Error Handling**: Consistent `{:ok, result}` | `{:error, reason}` patterns
- **Documentation**: Extensive ExDoc documentation with examples
- **Test Coverage**: 91.48% test coverage with 118 passing tests

### Testing
- 118 total tests (all passing)
- Unit tests for all modules
- Integration tests for end-to-end workflows
- Zero compilation warnings
- Zero Dialyzer errors

### Quality Gates
- ✅ 91.48% test coverage (exceeds 80% requirement)
- ✅ Zero compilation warnings
- ✅ Comprehensive documentation
- ✅ Strict TDD methodology followed
- ✅ All quality gates passing

### Notes
This is the Phase 1 foundation release. Future releases will add:
- Prompt injection attacks
- Jailbreak techniques
- Data extraction attacks
- Defense mechanisms
- Advanced metrics (certified robustness)
- CrucibleBench integration
- Real-time monitoring

[0.2.0]: https://github.com/North-Shore-AI/crucible_adversary/releases/tag/v0.2.0
[0.1.0]: https://github.com/North-Shore-AI/crucible_adversary/releases/tag/v0.1.0

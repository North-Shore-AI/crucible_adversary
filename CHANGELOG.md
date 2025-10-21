# Changelog

All notable changes to CrucibleAdversary will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/North-Shore-AI/crucible_adversary/releases/tag/v0.1.0

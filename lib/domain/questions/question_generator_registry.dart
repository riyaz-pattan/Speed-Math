import '../../core/enums/enums.dart';
import 'generators/addition_generator.dart';
import 'generators/cube_roots_generator.dart';
import 'generators/cubes_generator.dart';
import 'generators/division_generator.dart';
import 'generators/exponents_generator.dart';
import 'generators/multiplication_generator.dart';
import 'generators/square_roots_generator.dart';
import 'generators/squares_generator.dart';
import 'generators/subtraction_generator.dart';
import 'question_generator.dart';

/// Single registry that maps [Topic] to the correct [QuestionGenerator].
///
/// To add a new topic, create a new generator class and register it here.
class QuestionGeneratorRegistry {
  QuestionGeneratorRegistry._();

  static final Map<Topic, QuestionGenerator> _generators = {
    Topic.addition: AdditionGenerator(),
    Topic.subtraction: SubtractionGenerator(),
    Topic.multiplication: MultiplicationGenerator(),
    Topic.division: DivisionGenerator(),
    Topic.squares: SquaresGenerator(),
    Topic.cubes: CubesGenerator(),
    Topic.squareRoots: SquareRootsGenerator(),
    Topic.cubeRoots: CubeRootsGenerator(),
    Topic.exponents: ExponentsGenerator(),
  };

  /// Returns the generator for the given [topic].
  /// Throws [ArgumentError] if the topic has no registered generator.
  static QuestionGenerator getGenerator(Topic topic) {
    final generator = _generators[topic];
    if (generator == null) {
      throw ArgumentError('No generator registered for topic: ${topic.name}');
    }
    return generator;
  }

  /// Returns all registered topics.
  static List<Topic> get registeredTopics => _generators.keys.toList();

  /// Registers a new generator (used for extensibility in later phases).
  static void register(Topic topic, QuestionGenerator generator) {
    _generators[topic] = generator;
  }
}

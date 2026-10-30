import 'package:equatable/equatable.dart';

enum QuestionType { multipleChoice, freeText }

class LessonQuestion extends Equatable {
  const LessonQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    this.correctIndex,
    this.explanation = '',
  });

  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final int? correctIndex;
  final String explanation;

  @override
  List<Object?> get props => [id, question, type, options, correctIndex, explanation];
}

class MlpLesson extends Equatable {
  const MlpLesson({
    required this.id,
    required this.milestoneId,
    required this.title,
    required this.content,
    required this.practicalTask,
    this.questions = const [],
    this.xpReward = 50,
    this.isCompleted = false,
    this.estimatedMinutes = 15,
  });

  final String id;
  final String milestoneId;
  final String title;
  final String content;
  final String practicalTask;
  final List<LessonQuestion> questions;
  final int xpReward;
  final bool isCompleted;
  final int estimatedMinutes;

  MlpLesson copyWith({bool? isCompleted}) {
    return MlpLesson(
      id: id, milestoneId: milestoneId, title: title, content: content,
      practicalTask: practicalTask, questions: questions, xpReward: xpReward,
      isCompleted: isCompleted ?? this.isCompleted, estimatedMinutes: estimatedMinutes,
    );
  }

  @override
  List<Object?> get props => [id, milestoneId, title, content, practicalTask, questions, xpReward, isCompleted, estimatedMinutes];
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'learn_screen.dart';
import 'lessons.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  const LessonScreen(this.lesson, {super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late final Future<String> _text = rootBundle.loadString(widget.lesson.asset);
  final Map<int, int> _answers = {};

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final t = Theme.of(context).textTheme;
    final allRight = _answers.length == l.quiz.length &&
        _answers.entries.every((e) => l.quiz[e.key].answer == e.value);

    return Scaffold(
      appBar: AppBar(title: Text(l.title)),
      body: FutureBuilder(
        future: _text,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MarkdownBody(data: snap.data!, selectable: true),
              if (l.tool != null) ...[const SizedBox(height: 16), ToolTile(l.tool!)],
              const SizedBox(height: 24),
              Text('Quick check', style: t.titleLarge),
              for (final (qi, q) in l.quiz.indexed) _question(qi, q),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(allRight ? 'Mark lesson complete' : 'Answer all questions correctly to finish'),
                onPressed: allRight
                    ? () async {
                        await ref.read(progressProvider.notifier).markDone(l.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    : null,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _question(int qi, QuizQuestion q) {
    final picked = _answers[qi];
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(q.question, style: Theme.of(context).textTheme.titleSmall),
        RadioGroup<int>(
          groupValue: picked,
          onChanged: (v) => setState(() => _answers[qi] = v!),
          child: Column(children: [
            for (final (oi, o) in q.options.indexed)
              RadioListTile<int>(value: oi, title: Text(o), dense: true, contentPadding: EdgeInsets.zero),
          ]),
        ),
        if (picked != null)
          Text(
            picked == q.answer ? '✓ ${q.why}' : '✗ Not quite: try again.',
            style: TextStyle(color: picked == q.answer ? Colors.green.shade700 : cs.error),
          ),
      ]),
    );
  }
}

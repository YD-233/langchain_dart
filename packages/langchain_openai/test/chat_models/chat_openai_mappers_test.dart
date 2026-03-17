import 'package:langchain_openai/src/chat_models/mappers.dart';
import 'package:openai_dart/openai_dart.dart' as oai;
import 'package:test/test.dart';

void main() {
  group('ChatOpenAI mapper tests', () {
    test('should map reasoning fields from chat completion responses', () {
      final response = oai.ChatCompletion.fromJson({
        'id': 'chatcmpl-1',
        'object': 'chat.completion',
        'created': 123,
        'model': 'deepseek-r1',
        'choices': [
          {
            'index': 0,
            'finish_reason': 'stop',
            'message': {
              'role': 'assistant',
              'content': 'Final answer',
              'reasoning_content': 'First reasoning path',
              'reasoning': 'Second reasoning path',
              'reasoning_details': [
                {'type': 'reasoning.text', 'text': 'Detailed reasoning'},
              ],
            },
          },
        ],
        'usage': {
          'prompt_tokens': 10,
          'completion_tokens': 5,
          'total_tokens': 15,
        },
      });

      final result = response.toChatResult('run-1');

      expect(result.output.content, 'Final answer');
      expect(
        result.output.reasoningContent,
        'First reasoning path\nSecond reasoning path',
      );
      expect(result.metadata['reasoning_content'], 'First reasoning path');
      expect(result.metadata['reasoning'], 'Second reasoning path');
      expect(result.metadata['reasoning_details'], [
        {'type': 'reasoning.text', 'text': 'Detailed reasoning'},
      ]);
    });

    test(
      'should not duplicate reasoning when provider returns the same text',
      () {
        final response = oai.ChatCompletion.fromJson({
          'id': 'chatcmpl-2',
          'object': 'chat.completion',
          'created': 123,
          'model': 'deepseek-r1',
          'choices': [
            {
              'index': 0,
              'finish_reason': 'stop',
              'message': {
                'role': 'assistant',
                'content': 'Final answer',
                'reasoning_content': 'Same reasoning',
                'reasoning': 'Same reasoning',
              },
            },
          ],
        });

        final result = response.toChatResult('run-2');

        expect(result.output.reasoningContent, 'Same reasoning');
      },
    );

    test('should map reasoning fields from streaming deltas', () {
      final event = oai.ChatStreamEvent.fromJson({
        'id': 'chatcmpl-3',
        'object': 'chat.completion.chunk',
        'created': 123,
        'model': 'deepseek-r1',
        'choices': [
          {
            'index': 0,
            'delta': {
              'role': 'assistant',
              'content': 'Final',
              'reasoning_content': 'Stream reasoning',
              'reasoning': 'Summary',
              'reasoning_details': [
                {'type': 'reasoning.summary', 'text': 'Short summary'},
              ],
            },
            'finish_reason': null,
          },
        ],
      });

      final result = event.toChatResult('run-3');

      expect(result.output.content, 'Final');
      expect(result.output.reasoningContent, 'Stream reasoning\nSummary');
      expect(result.metadata['reasoning_content'], 'Stream reasoning');
      expect(result.metadata['reasoning'], 'Summary');
      expect(result.metadata['reasoning_details'], [
        {'type': 'reasoning.summary', 'text': 'Short summary'},
      ]);
      expect(result.streaming, isTrue);
    });
  });
}

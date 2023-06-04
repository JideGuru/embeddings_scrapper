import 'dart:convert';
import 'dart:io';

import 'package:embeddings_scrapper/embeddings_scrapper.dart'
    as embeddings_scrapper;
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:html/dom.dart'; // Contains DOM related classes for extracting data from elements

void main(List<String> arguments) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final openAIKey = env['OPENAIKEY'];
  final randomPhraseUrl =
      'https://www.coolgenerator.com/random-phrase-generator'; // https://www.coolgenerator.com/recipe-generator
  final res = await http.get(Uri.parse(randomPhraseUrl));
  var document = parse(res.body);
  int currentFileCount = 1;
  List phrases = [];
  List<Element> phraseElements = document.getElementsByClassName('font-18');
  for (Element element in phraseElements) {
    List<Element> phraseSpans = element.getElementsByTagName('span');
    if (phraseSpans.isNotEmpty) {
      // print(phraseSpans[0].innerHtml);
      phrases.add(phraseSpans[0].text);
    }
  }

  for (String phrase in phrases) {
    String text = phrase.trim();
    print(text);
    List<double>? embedding =
        await getEmbeddingFromOpenAI(text, openAIKey ?? '');
    String json = '''
{
      "text": "$text",
      "embedding": $embedding
    }
''';
    currentFileCount += 1;
    // Create assets folder
    Directory('assets').create();
    File file = await File('assets/$currentFileCount.json').create();
    file.writeAsString(json);
  }
}

Future<List<double>?> getEmbeddingFromOpenAI(
    String text, String openAIKey) async {
  var url = Uri.parse('https://api.openai.com/v1/embeddings');
  var response = await http.post(
    url,
    body: jsonEncode({"input": text, "model": "text-embedding-ada-002"}),
    headers: {
      'Authorization': 'Bearer $openAIKey',
      'Content-Type': 'application/json',
    },
  );
  if (response.statusCode == 200) {
    Map<String, dynamic> json = jsonDecode(response.body);
    List<double> embedding = List.empty(growable: true);
    for (final value in json['data'][0]['embedding']) {
      embedding.add(value);
    }
    return embedding;
  } else {
    return null;
  }
}

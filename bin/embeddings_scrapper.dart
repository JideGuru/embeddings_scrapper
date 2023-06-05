import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:html/dom.dart'; // Contains DOM related classes for extracting data from elements

void main(List<String> arguments) async {
  int currentFileCount = 101;

  // List<String> phrases = await getCountriesList();
  List<String> phrases = await scrapeGenerator();
  if (phrases.isNotEmpty) {
    for (String phrase in phrases) {
      String text = phrase.trim();
      print(text);
      List<double>? embedding = await getEmbeddingFromOpenAI(text);
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
}

Future<List<String>> scrapeGenerator() async {
  final randomPhraseUrl =
      'https://www.coolgenerator.com/random-phrase-generator'; // https://www.coolgenerator.com/recipe-generator
  final res = await http.get(Uri.parse(randomPhraseUrl));
  var document = parse(res.body);
  List<String> phrases = [];
  List<Element> phraseElements = document.getElementsByClassName('font-18');
  for (Element element in phraseElements) {
    List<Element> phraseSpans = element.getElementsByTagName('span');
    if (phraseSpans.isNotEmpty) {
      // print(phraseSpans[0].innerHtml);
      phrases.add(phraseSpans[0].text);
    }
  }
  return phrases;
}

Future<List<String>> getCountriesList() async {
  var url = Uri.parse('https://restcountries.com/v3.1/all');
  var response = await http.get(
    url,
    headers: {'Content-Type': 'application/json'},
  );
  List<String> phrases = [];
  if (response.statusCode == 200) {
    List<dynamic> countries = jsonDecode(response.body);
    for (var country in countries) {
      print(country['name']['common']);
      phrases.add(country['name']['common']);
    }
  }
  return phrases;
}

Future<List<double>?> getEmbeddingFromOpenAI(String text) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final openAIKey = env['OPENAIKEY'];
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

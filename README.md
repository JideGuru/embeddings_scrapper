This is a simple dart cli script i wrote to help create embedding json files.

It works in this steps:
1. It scrapesfor phrases/recipes 
2. it runs the phrases through OpenAI's API to get the 1538-dimensions embeddings of the phrase
3. it then creates a json file with the phrase and embeddings

The json should look like {"text": phrase, "embedding": [0.0, 0.1,..etc]}

Just run the `dart run` command to see it at work.
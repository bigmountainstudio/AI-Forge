# Example evaluation script
# After fine-tuning, test on held-out data

# Test on training data (should be high)
# ollama run your-finetuned-model "<sample from train_dataset.jsonl>"

# Test on test data (should be similar if not overfitting)
# ollama run your-finetuned-model "<sample from test_dataset.jsonl>"

# Compare responses - if test responses are much worse, you have overfitting

# Convert to Ollama format
# After fine-tuning, convert the model:
# ollama create swiftui-expert -f Modelfile

# Modelfile content:
FROM ./swiftui-finetuned-model
SYSTEM """
You are a SwiftUI expert with deep knowledge of modern iOS development.
Always use the latest APIs and provide accurate, helpful code examples.
"""

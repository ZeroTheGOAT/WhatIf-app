# WhatIf - Alternate Reality Simulator

An imaginative mobile app that explores "what if" scenarios through AI-generated alternate timelines. Built with Flutter for a beautiful, dark-themed experience.

## 🌟 Features

- **Single-Page Design**: Clean, minimal interface with everything on one screen.
- **Dark Mode Only**: Sleek black theme with elegant typography.
- **Text & Voice Input**: Type or speak your "what if" questions.
- **Image-Based Scenarios**: Upload photos to generate scenarios based on visual content.
- **AI-Powered Responses**: Integrates with leading language models for imaginative, emotional timelines.
- **Save Favorites**: Bookmark your favorite alternate realities.
- **Offline Fallback**: Provides fun scenarios even when internet is unavailable.

## 🎨 Design

- **Background**: Pure black (#000000)
- **Chat Bubbles**: Dark gray cards with subtle borders
- **Typography**: Inter font family for clean, modern look
- **Colors**: Green accents (#4CAF50) for interactive elements
- **Animations**: Smooth transitions and loading states

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Android Studio or VS Code
- HuggingFace API key

### Installation

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd what_if
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Configure API Key**:
    - Get your API key from [HuggingFace](https://huggingface.co/settings/tokens).
    - Open `lib/main.dart` and replace the placeholder API key with your own.

4.  **Run the app**:
    ```bash
    flutter run
    ```

## 📱 Usage

### Text Input
1. Type your "what if" question in the text field
2. Press the send button (➡️) or hit Enter
3. Wait for the AI to generate your alternate timeline

### Voice Input
1. Tap and hold the microphone button (🎤)
2. Speak your "what if" question clearly
3. Release to send your voice message

### Image Analysis
1. Tap the image button (🖼️)
2. Select a photo from your gallery
3. The AI will analyze the image and create a scenario

### Saving Favorites
- Long-press any AI response to save it to favorites
- Tap the bookmark icon (📖) on any response

## 🛠️ Technical Details

- **Framework**: Flutter
- **Language**: Dart
- **API**: HuggingFace Inference API (`HuggingFaceH4/zephyr-7b-beta`)
- **Core Packages**:
  - `http`: For API communication.
  - `speech_to_text`: For voice input.
  - `image_picker`: For photo selection.
  - `shared_preferences`: For local storage.
  - `google_fonts`: For the Inter font family.

## 📋 Permissions

The app requires these permissions:
- **Internet**: For API calls
- **Microphone**: For voice input
- **Camera**: For image capture
- **Storage**: For image selection

## 🎯 Example Prompts

Try these "what if" questions:
- "What if I moved to Japan after graduation?"
- "What if I discovered I could fly?"
- "What if I won the lottery?"
- "What if I never met my best friend?"
- "What if I became a famous musician?"

## 🔧 Customization

### Colors
Modify the color scheme in `lib/main.dart`:
```dart
colorScheme: const ColorScheme.dark(
  primary: Color(0xFF1A1A1A),
  secondary: Color(0xFF333333),
  // ... other colors
),
```

### AI Prompt
Customize the AI system prompt in the `_generateWhatIfResponse` method to change the response style and format.

## 🐛 Troubleshooting

### Common Issues

1. **API Key Error**
   - Ensure your OpenAI API key is correctly set
   - Check your API key has sufficient credits

2. **Voice Input Not Working**
   - Grant microphone permission when prompted
   - Check device microphone settings

3. **Image Upload Fails**
   - Grant camera/storage permissions
   - Ensure image file size is reasonable

4. **App Crashes**
   - Run `flutter clean` and `flutter pub get`
   - Check Flutter version compatibility

## 📄 License

This project is for educational and personal use. Please respect the terms of service of any APIs used.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**WhatIf** - Explore the infinite possibilities of your alternate realities! ✨

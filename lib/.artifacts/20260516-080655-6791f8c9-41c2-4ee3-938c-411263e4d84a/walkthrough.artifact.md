# Walkthrough - AI Insights Navigation

I have implemented the "AI Insights" navigation feature, replacing the "Groups" option in the bottom navigation bar and providing a structured redirection flow.

## Changes

### New Screens
- [ai_insights_screen.dart](file:///C:/Users/HP/StudioProjects/my_first_app/lib/ai_insights_screen.dart): The main landing page for AI Insights with options for "Page 1" and "Page 2".
- [page_one_screen.dart](file:///C:/Users/HP/StudioProjects/my_first_app/lib/page_one_screen.dart): Redirected page for "Page 1".
- [page_two_screen.dart](file:///C:/Users/HP/StudioProjects/my_first_app/lib/page_two_screen.dart): Redirected page for "Page 2".

### AI Suggestions (Grok AI Placeholders)
- **Service Architecture**: Introduced `ai_service.dart` with a `MockAiService`. This keeps API keys out of the app while simulating realistic network calls.
- **Data Integration**: Both Page 1 and Page 2 now fetch `skills` and `careerInterests` from Firebase and pass them to the AI Service.
- **Page 1 (What to do next)**: Shows a loading state ("Grok AI is analyzing...") for 2 seconds before displaying dynamic suggestions based on the user's specific skills.
- **Page 2 (Career Trajectory)**: Shows a loading state before displaying a three-stage career ladder tailored to the user's profile.

### Real AI Integration (Gemini)
- **Live AI Power**: Replaced Mock AI with **Google Gemini 1.5 Flash** for real-time, high-quality professional summaries and career advice.
- **Dynamic Content**:
    - *Page 1*: Now returns real courses and projects based on Gemini's live analysis.
    - *Summary*: Gemini writes unique, professional paragraphs based on the user's specific goals and GPA.
- **Easy Setup**: Added `lib/api_config.dart` where you can paste your API key for the demo.
- **Graceful Fallback**: If no API key is provided, the app automatically falls back to the Mock AI so the demo never "breaks" during a presentation.

### Integration
- [main.dart](file:///C:/Users/HP/StudioProjects/my_first_app/lib/main.dart):
    - Replaced "Groups" destination with "AI Insights".
    - Updated icons to lightbulb icons for a better AI-themed look.
    - Integrated `AiInsightsScreen` into the navigation flow.
- [placeholder_screens.dart](file:///C:/Users/HP/StudioProjects/my_first_app/lib/placeholder_screens.dart):
    - Added "AI Insights" to the `MenuPage` (accessed via the horizontal lines icon on the Profile screen).
    - Linked the menu item to `AiInsightsScreen`.

## Verification Results

### Automated Tests
- Ran static analysis on `main.dart` and `ai_insights_screen.dart`, and no issues were found.

### Manual Verification Steps (For User)
1. Launch the app.
2. Tap the **AI Insights** tab (lightbulb icon) in the bottom navigation.
3. Observe the **AI Insights** screen with two buttons: "Page 1" and "Page 2".
4. Click **Page 1**, verify it navigates to a screen saying "This is new page 1".
5. Navigate back, click **Page 2**, verify it navigates to a screen saying "This is new page 2".

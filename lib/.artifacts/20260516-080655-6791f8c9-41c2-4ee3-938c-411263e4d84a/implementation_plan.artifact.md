# Implementation Plan - Real AI Integration (Gemini)

Transition from the simulated Mock AI to **Google Gemini AI** to provide real, high-quality suggestions and summaries for your client demo.

## Proposed Changes

### AI Service

#### [ai_service.dart](file:///C:/Users/HP/StudioProjects/my_first_app/lib/ai_service.dart)
- Import `google_generative_ai`.
- Implement `GeminiAiService` which uses a real API Key.
- Update the UI components to use `GeminiAiService` instead of `MockAiService`.

### Core Logic
- **`getNextSteps`**: Sends a prompt to Gemini like: *"As a student with skills in [Skills] and interests in [Interests], suggest one course and one project for my career."*
- **`getCareerTrajectory`**: Sends a prompt like: *"Predict a 3-step career path for a specialist in [Primary Skill]."*
- **`generateSummary`**: Sends all user data (GPA, Goals, Interests) and asks Gemini to write a summary in the requested tone (Academic vs Professional).

## Security Note for Demo
> [!WARNING]
> For this **Demo**, we will put the API Key in a separate file (e.g., `lib/api_config.dart`) which you should never share. For a **Production** release, we must move this logic to a backend as previously planned.

## Requirements
To proceed, you need a **Google Gemini API Key**:
1. Go to [Google AI Studio](https://aistudio.google.com/).
2. Click **"Get API Key"**.
3. Create a new key.

## Verification Plan

### Manual Verification
1. Input your Gemini API Key.
2. Navigate to **AI Insights**.
3. Tap **Page 1**.
4. Verify that the response is now **dynamic** and comes from Gemini (it will be more detailed than the mock).
5. Repeat for **Summary Generation**.

# MYLife Plan — Smart Coach Feature Upgrade

This build adds behavior-aware habit features on top of the existing Flutter + Provider + Firestore architecture.

## Implemented in this package

1. **Skip reason analysis**
   - Habit Detail has a skip flow with reasons: `Charchadim`, `Band edim`, `Unutdim`, `Xohlamadim`.
   - Statistics and Habit Detail show pattern insights such as most common day/time and reason.

2. **Identity-based accounting**
   - Each category maps to an identity role: Health → Sog‘lom odam, Study → Bilimli odam, etc.
   - Statistics shows identity votes; every completion is treated as one vote for a role.

3. **Recovery Mode**
   - Habit Detail includes Recovery action when a habit can be recovered.
   - Recovery gives half XP instead of fully breaking the user psychologically.

4. **Accountability partner / commitment contract fields**
   - Add Habit collects optional partner and contract text.
   - Habit Detail displays the accountability message.
   - No external social feed or push integration is added yet.

5. **“Why did you start?” reminder**
   - Add Habit collects a why note.
   - Habit Detail shows it as a motivation card.

6. **Mood and energy correlation**
   - Completing a habit asks mood and energy from 1–5.
   - Statistics summarizes category mood correlations after enough data.

7. **Habit stacking**
   - Model supports `stackAfterHabitId` and AppState can find a stacked next habit.
   - Habit Detail prompts the next stacked habit when a related habit is completed.
   - A full editor UI for linking habits can be added next.

8. **Investment visualization**
   - Habit Detail and Statistics convert completions into time/books/sessions.

9. **Adaptive reminder suggestion**
   - AppState calculates a suggested reminder from actual completion timestamps.
   - Habit Detail shows the suggested time.

10. **Two-minute minimal version**
    - Add Habit collects a minimal goal.
    - Habit Detail has a Minimal action and gives partial XP while preserving the habit chain.

11. **Automatic difficulty downshift suggestion**
    - Habit Detail suggests shrinking the goal if the user misses several recent days.

12. **Weekly auto-summary**
    - Statistics shows a weekly summary and next-week suggestion.

13. **Today’s #1 task**
    - Statistics highlights one priority habit to reduce notification fatigue.

14. **Compassionate language**
    - Detail status uses neutral language like “Yangi boshlanish kuni” and avoids shame wording.

15. **Future self letter**
    - Add Habit collects a future letter.
    - Habit Detail shows it again at 30/60/90 day checkpoints.

## Notes

- This upgrade does not add real push notifications because that needs platform-specific notification setup and permission flows.
- `android/app/google-services.json` is intentionally not included in the clean handoff zip for safety. Keep using your local Firebase config file.
- Run `flutter pub get`, then `flutter run` in your local machine.

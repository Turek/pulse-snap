# Photo-Based Pulse & Heart Rate Diary App: Market Research & Build Blueprint

## Executive Summary

The concept of "take a photo → data gets logged automatically" already exists in the market, but every current implementation has meaningful gaps — chiefly privacy, accuracy, vendor lock-in, aggressive monetization, and fragile OCR on varied device displays. For a developer with an existing Flutter + ASP.NET Core stack and Ollama running locally, building a self-hosted version that avoids all of these problems is technically within reach and represents a genuine quality-of-life advantage over what exists today.

***

## What Already Exists

### The "Photo-to-Log" Category

The closest apps to your vision are already shipping. The key players:

**BP Snap** (iOS only) is the most polished OCR-first BP app currently available. It points your camera at any blood pressure cuff, uses AI image recognition to extract systolic, diastolic, and pulse in under 5 seconds, auto-stamps date/time, and stores data locally — photos are deleted immediately after extraction. It syncs with Apple HealthKit, generates 7/14/30-day trend charts, and produces doctor-ready PDF reports. It has only 4 ratings as of late 2025, suggesting very recent release.[^1][^2][^3]

**SnapLog AI** (Flutter app, Android + iOS) is the most architecturally similar to what you want to build. It photographs BP monitors, scales, glucometers, and pulse oximeters; cloud-backed AI (Firebase) extracts values; history and trends are shown in-app. It explicitly notes it is built in Flutter. However, it relies on cloud AI (no self-hosted option) and uses Firebase for sync, which means your data lives on Google's infrastructure.[^4][^5]

**Blood Pressure Log: Scan & Go** (Android) uses on-device OCR to scan 7-segment LCD displays from any brand (Omron, Citizen, Tanita, wrist-type, upper-arm). It handles multiple readings per day and auto-calculates daily averages.[^6]

**BP Assistant** (iOS/Android) offers OCR photo recognition for batch importing multiple readings at once, plus FHIR/CSV export, Apple/Google Health integration, and offline privacy processing.[^7]

**Blood Pressure Log: Health AI** (iOS) combines camera-based pulse detection with an AI health journal and Apple Health sync, targeting both heart rate monitoring and BP logging.[^8][^9]

### Manual-Entry Apps with Strong Diary Features

**SmartBP** has 1M+ downloads and 50,000+ five-star ratings. It does not do photo capture — readings are entered manually or synced via Bluetooth — but it excels at analytics: trend charts, AM/PM breakdowns, correlation analysis, PDF reports, multiple user profiles, and HIPAA/GDPR compliance. Users consistently praise the charting and doctor-sharing features but complain about ads and aggressive subscription prompts.[^10][^11]

### Open-Source / Self-Hosted Reference

**Helse** (GitHub: FSchiltz/Helse) is a self-hosted health logging app built with exactly your stack: a C# Web API backend and a Flutter frontend that runs on Web, Android, or iOS, deployable via Docker Compose with PostgreSQL. It does not include photo OCR but is the closest open-source starting point for the backend architecture you would build.[^12]

***

## What People Complain About

### Aggressive Monetization

This is the #1 complaint across nearly every existing app in this category. SmartBP users report being asked to pay "every time you open the app," with ads making it hard to reach the actual data entry screen. Blood Pressure Scan Health users report ads appearing "every second," covering menus, and the app triggering ad redirects instead of actually functioning. SmartBP crashes apps on first load and then shows upsell screens. Users with one legitimate use-case — logging health data — are being squeezed at every interaction.[^13][^11]

### Privacy and Data Ownership

Most apps sync to cloud services (Firebase, AWS, proprietary servers) and share health data with third parties. SmartBP's own data safety declaration states it "may share these data types with third parties: Personal info, Health and fitness". For health data, this is deeply uncomfortable for privacy-conscious users. BP Snap takes a better approach — photos are deleted immediately after OCR — but readings still go to HealthKit.[^11][^1]

### OCR Accuracy and Failure Modes

Photo recognition on LCD/7-segment displays is reliable under good conditions but fails under several common scenarios:[^14][^15]

- **Poor lighting or glare** — backlit LCD screens reflecting ambient light cause misreads. Contrast is critical for OCR accuracy.[^14]
- **Image tilt or rotation** — vision models (including GPT-4V) fail significantly when the display is tilted even a few degrees. Straightening the image resolves it, but that's a UX friction point.[^14]
- **Display font variety** — apps trained primarily on Omron M7 cuffs (the most common training dataset in academic research) perform worse on unusual display fonts or older monitor models.[^16][^17]
- **Processing speed** — locally-run vision models (Llama 3.2-Vision 11B via Ollama) on consumer hardware take **16–47 seconds** per image, which breaks the "instant" UX promise.[^18]
- **Display resolution / number splitting** — when images are chunked into 512×512 tiles by vision models, numbers at tile boundaries get split and misread.[^14]

Academic CNN-based approaches achieve ~91% classification accuracy with a mean absolute error of 3.19 mmHg for systolic BP on readable images from a single monitor model — solid for personal logging, but accuracy drops on lower-quality photos or different device designs.[^17][^16]

### Measuring BP Directly from Camera (The Scam Problem)

A critical distinction must be maintained: **apps that photograph your BP monitor display** (OCR approach — legitimate) vs. **apps that claim to measure blood pressure by pointing the camera at your finger or chest** (PPG/cameraless approach — dangerously inaccurate).[^19]

The latter category has been repeatedly and thoroughly debunked. A Johns Hopkins study found that "Instant Blood Pressure" missed dangerous hypertension in 4 out of 5 cases, with readings off by ~12 mmHg systolic and ~10 mmHg diastolic. Harvard Medicine explicitly advises: "Don't use any app that uses the phone itself to measure your blood pressure". However, PPG-based *heart rate* (pulse) measurement via smartphone camera is validated and accurate in adults — correlation coefficient ≥0.90 vs. validated methods in a meta-analysis of 14 studies. So measuring pulse from a fingertip on camera is fine; inferring blood pressure that way is not.[^20][^21][^22][^23][^24][^25]

### Ecosystem Lock-in and Poor Cross-Platform Support

BP Snap is iOS only. Most apps tie data to Apple Health or Google Fit, creating barriers when switching platforms. Few offer true multi-platform, self-hosted, or export-first designs.[^2][^1]

***

## The Gap Your App Can Fill

| Problem with existing apps | Your self-hosted solution |
|---|---|
| Cloud data, shared with third parties | All data on your DigitalOcean/local server |
| Aggressive ads and paywalls | No monetization constraints — pure utility |
| iOS-only or Android-only | Flutter: one codebase, both platforms |
| Slow cloud AI latency | Ollama vision model on your server |
| Single monitor brand support | Generic 7-segment LCD OCR works across brands |
| No custom analytics | Full control over charting and data schema |
| Vendor abandonment (apps go dead) | You own the codebase |

***

## Technical Architecture for Your Build

### The OCR Layer — Recommended Approach

For a self-hosted setup, the best practical approach is a **hybrid pipeline**:

1. **Pre-processing on the server** (OpenCV / ImageSharp in C#): auto-rotate, crop, increase contrast, threshold the image to isolate the LCD digits before passing to the model.
2. **Vision LLM via Ollama** for extraction: `llama3.2-vision:11b` is a strong choice — it excels at text recognition and image reasoning, outperforming many closed models on benchmarks. Ollama's API accepts base64-encoded images and returns structured text.  For state-of-the-art OCR accuracy, `olmocr2` (based on Qwen2.5-VL-7B, fine-tuned for OCR) on Ollama achieves 82.4 on olmOCR-Bench.[^26][^27][^28]
3. **Structured prompt** to the model: `"Extract the three numeric values from this blood pressure monitor display. Return JSON: {systolic: int, diastolic: int, pulse: int}. If a value is unclear, return null."`
4. **Confirmation step in the UI**: Always show the extracted values for 1-tap confirmation before saving — SnapLog AI does this correctly. This is critical for user trust when OCR misreads occur.[^5]

### Server Stack (Your Existing Tools)

```
Flutter App (mobile)
    ↓ HTTPS + JWT
ASP.NET Core API (DigitalOcean / your NAS)
    ↓ HTTP
Ollama (llama3.2-vision or olmocr2)
    ↓
PostgreSQL (readings, history, user data)
```

The Ollama REST API is straightforward from .NET — `POST /api/chat` with `model`, `messages`, and `images` (base64) fields. The full vision model pipeline in .NET is documented and battle-tested.[^29]

For on-device heart rate measurement (PPG), the Flutter `camera` package can capture the rear camera with flashlight active — fingertip over lens — and process the red channel brightness variation to calculate BPM. This is scientifically validated for resting adults.[^20]

### Data Model (Minimal)

```
Reading
  - id (uuid)
  - user_id
  - timestamp
  - systolic (nullable int) 
  - diastolic (nullable int)
  - pulse (int)
  - source_type (enum: photo_ocr | manual | camera_ppg)
  - device_label (text, optional: "Omron M7", etc.)
  - notes (text)
  - image_hash (for deduplication, photo deleted after extraction)
```

### UI Flow (Your "Simple as Possible" Goal)

1. Open app → single large "+" button or immediate camera view
2. Camera preview with overlay guide frame (position monitor in frame)
3. Auto-capture on stability (or manual shutter)
4. Image sent to your server → Ollama extracts values (~5–15s with good GPU)
5. Confirmation screen: show extracted values with edit capability
6. One-tap save → data stored → chart updated instantly
7. Main screen: rolling chart of last 30 readings + color-coded status

***

## Key Technical Pitfalls to Avoid

- **Don't skip the confirmation step.** OCR will occasionally misread. Always show extracted values before committing — this is the #1 differentiator between a trustworthy app and a frustrating one.[^14]
- **Image preprocessing is mandatory.** Raw photos sent to vision models without contrast normalization and deskewing will fail on dark rooms, glare, and tilted captures. OpenCV (available via Python sidecar) handles this well.[^15][^14]
- **Don't conflate BP measurement with pulse.** Camera-based pulse (PPG) is validated. Camera-based BP is not. Be clear in your app what each feature is doing.[^24][^19][^20]
- **Response time management.** Llama 3.2-Vision 11B on CPU takes 16–47 seconds. On a server with a decent GPU (or even a modern Synology NAS with sufficient RAM), this drops significantly. Show a visible processing animation with estimated time. Consider streaming the response.[^18]
- **7-segment LCD training data.** Academic research shows that models trained specifically on LCD digit patterns (via CNN approaches) achieve better accuracy on BP displays than general-purpose vision models. Consider fine-tuning a small model on 7-segment digit images if general-purpose accuracy is insufficient.[^16][^17]

***

## Competitive Positioning

Your app has a natural fit for privacy-first users, technically literate households managing chronic health conditions, and anyone frustrated by the ad-saturated market. The key differentiators to build into the UX from day one:

- **No cloud dependency** — all data stays on your server (or their own self-hosted instance if you open-source it)
- **Multi-device support** — any brand BP monitor, scale, pulse oximeter, glucose meter (just train the OCR prompt)
- **Zero friction** — open, snap, confirm, done (3 taps)
- **Honest about limitations** — always show confidence level from OCR, allow easy manual override
- **Export-first** — CSV, JSON, PDF on demand, always

The Helse project demonstrates the Flutter + C# WebAPI stack is viable for self-hosted health logging. Your app adds the AI OCR layer on top of that foundation — which is the differentiating feature none of the open-source alternatives have yet.[^12]

---

## References

1. [BP Snap - Blood Pressure Log App - App Store](https://apps.apple.com/ca/app/bp-snap-blood-pressure-log/id6754580515) - Download BP Snap - Blood Pressure Log by Third Horizon Technologies Inc. on the App Store. See scree...

2. [BP Snap - Blood Pressure Log - App Store - Apple](https://apps.apple.com/gb/app/bp-snap-blood-pressure-log/id6754580515) - Download BP Snap - Blood Pressure Log by Third Horizon Technologies Inc. on the App Store. See scree...

3. [BP Snap - Blood Pressure Log - App Store - Apple](https://apps.apple.com/us/app/bp-snap-blood-pressure-log/id6754580515) - BP Snap reads your BP monitor screen instantly—in under 5 seconds using advanced AI image recognitio...

4. [SnapLog AI — Log health readings from device photos](https://snaplogai.com) - Turn photos of your devices into organized readings, history, and trends. Personal wellness tracking...

5. [Read Customer Service Reviews of snapchat.com - Trustpilot](https://www.trustpilot.com/review/snapchat.com) - Snapchat Reviews 1,074 · Social media. Consumers express significant dissatisfaction with social med...

6. [Scan & Go. App reads Blood Pressure rate from the monitor!](https://celestialbrain.com/photo-blood-pressure-tracker-android-app-intro/) - Blood Pressure Log: Scan & Go is a blood pressure logging app that automatically reads and records t...

7. [Blood Pressure Heart Assistant - App Store - Apple](https://apps.apple.com/au/app/blood-pressure-heart-assistant/id6751407894) - Quick Entry & Bulk Import: Use our OCR photo recognition to quickly log your blood pressure, pulse, ...

8. [Blood Pressure Log: Health AI App - App Store](https://apps.apple.com/us/app/blood-pressure-log-health-ai/id6758089587) - Download Blood Pressure Log: Health AI by Neko Soft on the App Store. See screenshots, ratings and r...

9. [Health AI - Blood Pressure Log - App Store](https://apps.apple.com/us/app/health-ai-blood-pressure-log/id6758089587) - Download Health AI - Blood Pressure Log by Neko Soft on the App Store. See screenshots, ratings and ...

10. [Smart Blood Pressure App](https://www.smartbp.app) - SmartBP is a free, easy to use blood pressure management app that allows you to record, track, analy...

11. [Blood Pressure App - SmartBP – Apps on Google Play](https://play.google.com/store/apps/details/Blood_Pressure_App_SmartBP?id=com.smartbloodpressure&hl=en_AU) - Smart BP monitor health app creates a detailed blood pressure ... Same accuracy and ease of use with...

12. [FSchiltz/Helse: Selfhosted application for logging health data - GitHub](https://github.com/FSchiltz/Helse) - This is a simple work in progress selfhosted app for logging health data. The app is composed of a c...

13. [Blood Pressure：Scan Health - Ratings & Reviews - App Store - Apple](https://apps.apple.com/us/app/blood-pressure-scan-health/id6504895693?see-all=reviews&platform=iphone) - So far the app displays accurate readings for blood pressure and heart rates ... This app is nothing...

14. [GPT-4 Turbo with Vision incorrectly analyzed the image - API](https://community.openai.com/t/gpt-4-turbo-with-vision-incorrectly-analyzed-the-image/504043) - I am working on a feature to read blood pressure information from photos of blood pressure monitors....

15. [GitHub - DevashishPrasad/LCD-OCR: This is a tesseract based OCR to read from seven segment display.](https://github.com/DevashishPrasad/LCD-OCR) - This is a tesseract based OCR to read from seven segment display. - GitHub - DevashishPrasad/LCD-OCR...

16. [CNN-Based LCD Transcription of Blood Pressure From a Mobile ...](https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2021.543176/full) - On readable low- and high-quality images, this proposed approach achieved a 91% classification accur...

17. [CNN-Based LCD Transcription of Blood Pressure From a Mobile ...](https://pmc.ncbi.nlm.nih.gov/articles/PMC8177819/) - A total of 8192 BP readings were captured from the Liquid Crystal Display (LCD) screen of a standard...

18. [Performance Test Results](https://dev.to/karavanjo/how-to-run-a-local-model-for-text-recognition-in-images-2d6a) - Want to extract text from images without relying on cloud services? You can run a powerful optical.....

19. [PSA: don't fall for 'phone camera' blood pressure apps - Reddit](https://www.reddit.com/r/cardilog/comments/1mm4kdj/psa_dont_fall_for_phone_camera_blood_pressure_apps/) - Sadly, there are many apps on the market claiming you can get a BP reading using your phone's camera...

20. [Smartphone Apps Using Photoplethysmography for Heart Rate ...](https://cardio.jmir.org/2018/1/e4/) - Objective: The objective of this meta-analysis was to evaluate the available evidence on the use of ...

21. [Smartphone Apps Using Photoplethysmography for Heart Rate ...](https://www.sciencedirect.com/org/science/article/pii/S2561101118000041) - Smartphone apps measuring heart rate by performing PPG appear to agree with a validated method in an...

22. [Popular Blood Pressure App Gives "Very Inaccurate" Results, Study ...](https://www.yahoo.com/lifestyle/popular-blood-pressure-app-gives-160219838.html) - Their blood pressure was taken twice with blood pressure cuffs and twice with the app. The results s...

23. [Top-selling blood pressure app "very inaccurate" - CBS News](https://www.cbsnews.com/news/top-selling-blood-pressure-measuring-app-very-inaccurate/) - A mobile app that's been downloaded more than 100,000 times to measure blood pressure is wrong eight...

24. [Don't trust this smartphone app to measure your blood pressure](https://www.health.harvard.edu/heart-health/dont-trust-this-smartphone-app-to-measure-your-blood-pressure) - A popular smartphone app that uses the phone's microphone and camera to estimate blood pressure give...

25. [Wildly Popular, Dangerously Inaccurate: Blood Pressure Monitoring ...](https://www.tctmd.com/news/wildly-popular-dangerously-inaccurate-blood-pressure-monitoring-app-misses-mark) - One expert asks: should smartphone companies require health app developers to prove that their devic...

26. [Vision - Ollama's documentation](https://docs.ollama.com/capabilities/vision)

27. [Ollama-OCR for High-Precision OCR with Ollama - DEV Community](https://dev.to/bytefer/ollama-ocr-for-high-precision-ocr-with-ollama-4o31) - Llama 3.2-Vision is a multimodal large language model available in 11B and 90B sizes, capable of...

28. [richardyoung/olmocr2 - Ollama](https://ollama.com/richardyoung/olmocr2) - State-of-the-art OCR (Optical Character Recognition) vision language model based on [allenai/olmOCR-...

29. [Running Local AI Models in .NET with Ollama (Step-by-Step Guide)](https://dev.to/alinabi19/running-local-ai-models-in-net-with-ollama-step-by-step-guide-4die) - Ollama allows you to run powerful language models directly on your machine and access them through a...


# yt-dlp-MAX Project Plan (Revised)
## Building Your First Native macOS App: A Beginner-Friendly Powerhouse

### Project Philosophy

yt-dlp-MAX follows the VLC model: dead simple for beginners, powerful when you need it. A grandmother should be able to download her cooking videos, while a data hoarder can queue up an entire channel with custom naming schemes. The interface says "friendly," but the capabilities say "serious tool."

This is also your journey into native macOS development. We're going to build this in a way that teaches you Swift patterns as we go, leveraging your existing programming knowledge while filling in the Apple-specific gaps. Every phase will introduce new concepts at a digestible pace.

### Adjusted Timeline for Your Reality

Given your 4-5 day PTO burst followed by 2-4 hours weekly, here's our strategy:

**PTO Sprint (Days 1-5): Foundation & Core Features**
- Day 1: Environment setup, first window, "Hello yt-dlp"
- Day 2: Basic downloading with real progress bars
- Day 3: Format selection and cookie handling
- Day 4: Queue system and file management
- Day 5: Polish, testing, and breathing room

**Sustainable Development (Weeks 2-8): Enhancement & Polish**
- Week 2-3: Preferences and persistence (2-4 hours each week)
- Week 4-5: History, logging, and debugging tools
- Week 6-7: UI polish and quality-of-life features
- Week 8: Distribution preparation

This front-loads the critical learning and core features during your PTO, then shifts to manageable weekly improvements.

### Technical Architecture (Simplified for Swift Beginners)

Let's think of your app as a restaurant:

**The Kitchen (Services Layer)**
- `YTDLPService`: Your head chef that knows how to talk to yt-dlp
- `CookieManager`: Handles browser cookies (your secret ingredient supplier)
- `FileManager`: Organizes where finished dishes (videos) go

**The Dining Room (Views Layer)**
- `MainWindow`: Where customers (users) place orders
- `ProgressView`: Shows the order status
- `QueueView`: The order board showing all pending meals

**The Waitstaff (ViewModels Layer)**
- `DownloadViewModel`: Takes orders from the UI and tells the kitchen what to make
- Manages the state between what users see and what's actually happening

This separation means you can change how things look without breaking how they work, and vice versa. It's a pattern that will click once you see it in action.

### Core Features Roadmap (Beginner-First Design)

**Phase 1: The Minimally Lovable Product**
Essential features that make it worth using over Terminal:
- Paste a URL, click download, it just works
- See download progress that doesn't lie
- Choose video quality with human-readable options ("1080p" not "format code 247+251")
- Browser cookie import with one click (this is your killer feature)

**Phase 2: The Queue Revolution**
What makes it better than downloading one at a time:
- Add multiple videos to a queue
- Download them in order (or parallel if you're brave)
- Resume interrupted downloads
- See what you've already downloaded (history)

**Phase 3: The Power User's Secret Garden**
Hidden complexity for those who need it:
- Custom naming templates (but with a preview!)
- Advanced format selection
- Download rate limiting
- Subtitle and metadata options

### Swift Concepts You'll Master

Since you're new to Swift but experienced with programming, here's what you'll learn mapped to concepts you already know:

**Week 1 Concepts:**
- **SwiftUI = React-like declarative UI**: You describe what you want, not how to build it
- **@State and @Published = reactive variables**: Change the data, UI updates automatically
- **async/await = promises done right**: Familiar from JavaScript but cleaner
- **Optionals = null safety**: Swift forces you to handle missing values explicitly

**Week 2-3 Concepts:**
- **Combine = RxJS/Observables**: Reactive streams for handling events
- **UserDefaults = localStorage**: Simple key-value storage for preferences
- **Process = subprocess**: How to run command-line tools from Swift

**Week 4+ Concepts:**
- **Core Data = embedded database**: For history and complex state
- **CloudKit = sync across devices**: Maybe for phase 2 if you're feeling ambitious

### The Cookie Solution (Your Competitive Advantage)

Here's why cookie handling is brilliant and how we'll make it trivial:

Most yt-dlp users struggle with authentication because exporting cookies is arcane. We'll make it one click: detect installed browsers, read their cookie stores (with user permission), and pass them to yt-dlp automatically. This alone will make your app invaluable for anyone downloading from sites that require login.

The technical approach:
1. Read browser cookie databases (they're just SQLite files)
2. Convert to Netscape cookie format (what yt-dlp expects)
3. Pass via temporary file to yt-dlp
4. Clean up afterwards for security

This is complex enough to be valuable but simple enough to implement in day 3 of your PTO.

### Working with Claude Code (Your Secret Weapon)

Since you're experienced with AI-assisted development, here's how to maximize Claude Code's effectiveness for Swift:

**Session Initialization Pattern:**
```
"We're building yt-dlp-MAX, a macOS app in Swift using SwiftUI.
Current state: [describe what works]
Current goal: [specific feature]
Architecture: MVVM with YTDLPService handling process management
Please implement [specific task] with explanatory comments for Swift patterns I might not know."
```

**Learning Extraction Pattern:**
After Claude Code writes something, ask:
"Explain the Swift-specific patterns you just used and why they're idiomatic for macOS development."

**Your Swift Mentor Integration:**
When Claude Code suggests something complex, you can run it by your mentor with:
"Claude suggested [pattern]. Is this idiomatic Swift? Any gotchas?"

### Minimum Viable Success Metrics

Let's be realistic about what success looks like for version 1.0:

**Technical Success:**
- Downloads a YouTube video without crashing ✓
- Handles cookies from at least Safari and Chrome ✓
- Queue processes multiple videos reliably ✓
- Progress bars actually show progress ✓

**User Success:**
- Your non-technical friend can use it without help
- You personally use it instead of the command line
- Someone you don't know stars it on GitHub
- First "thank you, this is exactly what I needed" issue

**Learning Success:**
- You understand SwiftUI's declarative model
- You can debug a hanging Process call
- You know when to use @State vs @StateObject
- You've shipped your first native Mac app

### The First Five Days (Your PTO Battle Plan)

**Day 1: Hello, Swift World**
Morning: Install Xcode, create project, get a window showing
Afternoon: Make yt-dlp respond to a button click, see output in console
Victory: "I made yt-dlp run from Swift!"

**Day 2: Real Downloads**
Morning: Parse yt-dlp's JSON output into Swift structures
Afternoon: Download a file with progress updates
Victory: "I can see the percentage going up!"

**Day 3: The Cookie Monster**
Morning: Read Safari's cookies (this is your unique value!)
Afternoon: Pass cookies to yt-dlp, download a private video
Victory: "I just downloaded a members-only video with one click!"

**Day 4: Queue It Up**
Morning: Build a list that holds multiple downloads
Afternoon: Process them sequentially, show status
Victory: "It's downloading my whole playlist!"

**Day 5: Make It Real**
Morning: Add error handling for common failures
Afternoon: Create a proper app icon, test with friends
Victory: "Someone else successfully used my app!"

### Risk Mitigation for a Beginner

**Risk: "SwiftUI is too confusing"**
Mitigation: Start with one view, one button. Build complexity gradually. Your architectural background means you understand components - SwiftUI is just components all the way down.

**Risk: "yt-dlp integration is harder than expected"**
Mitigation: Start with the simplest possible call: `--version`. Then `--dump-json`. Then actual downloads. Each step builds confidence.

**Risk: "I'll lose momentum after PTO"**
Mitigation: The 5-day sprint delivers a usable app. Everything after is enhancement. You could literally stop after day 5 and have something valuable.

**Risk: "Cookie handling is too complex"**
Mitigation: Start with Safari only (it's easier). Chrome can come later. Manual cookie file import is the fallback.

### Your Learning Journey Milestones

By the end of this project, you'll have learned:

1. **SwiftUI Fundamentals**: How to build modern Mac interfaces
2. **Process Management**: Controlling external tools from Swift
3. **Async Programming**: Managing long-running operations without freezing the UI
4. **macOS Integration**: How Mac apps should behave (drag-drop, keyboard shortcuts, etc.)
5. **App Distribution**: Code signing, notarization, and DMG creation

More importantly, you'll have the confidence to build your next Mac app without training wheels.

### The Support Network

You're not doing this alone:
- **Claude Code**: Your pair programmer for implementation
- **Your Swift Mentor**: Your safety net for architectural decisions
- **Me (through check-ins)**: Your project guide and rubber duck
- **The Swift Community**: Surprisingly helpful and welcoming to beginners

### Remember Your Advantages

You're not a typical beginner:
- You understand complex systems (solutions architect background)
- You know how to work with AI tools effectively
- You have real experience with APIs and integration
- You've identified actual user pain points (cookies!)
- You have a Swift expert on speed dial

This combination is powerful. You're going to build something great.

### Next Steps

Ready to start Day 1? Let's set up your development environment and create that first window. The journey from zero to shipped Mac app starts with `File > New > Project`.

The beauty of this project is that every day you'll have something new working. By the end of your PTO, you'll have created real value for real users. By week 8, you'll have built something you're proud to put your name on.

Let's begin. yt-dlp-MAX awaits.
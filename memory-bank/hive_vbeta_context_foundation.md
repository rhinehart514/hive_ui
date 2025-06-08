# HIVE vBETA Context Foundation

_Last Updated: January 2025_  
_Purpose: Foundational context for all product decisions_  
_Launch Campus: University at Buffalo (UB)_

## 1. University at Buffalo (UB) Specific Context

### Campus Demographics & Scale

**Student Population:**
- **Total enrollment:** ~32,000 students (undergraduate + graduate)
- **Undergraduate:** ~22,000 students
- **International students:** ~4,500 (14% of total population)
- **Summer session:** ~800-1,200 students on campus
- **Commuter vs. residential:** 60% commuter, 40% on-campus housing

**Campus Geography:**
- **North Campus:** Main campus, most dorms, academic buildings, student life
- **South Campus:** Medical school, some undergraduate programs
- **Downtown Campus:** Architecture, planning, some graduate programs
- **Shuttle system:** Connects campuses, critical for student coordination

**Academic Calendar (2025):**
- **Spring semester:** January 27 - May 12
- **Summer sessions:** May 19 - August 15 (multiple session lengths)
- **Fall semester:** August 25 - December 15
- **vBETA launch target:** May 29, 2025 (start of summer session)

### UB-Specific Student Behavioral Reality

**Primary Apps (Daily Use at UB):**
- **Communication:** iMessage, Instagram DM, Snapchat, Discord
- **Academic:** UBLearns (Brightspace), UB email, Google Drive
- **Campus Life:** UB Mobile app (dining, shuttle), Campus Dining app
- **Productivity:** Apple/Google Calendar, Notes app, Reminders
- **Social Discovery:** Instagram, TikTok, GroupMe for classes/clubs

**UB-Specific Pain Points:**
- **Multi-campus coordination:** "Which campus is this event on?"
- **Shuttle timing:** "When's the next shuttle to North Campus?"
- **Dining coordination:** "Which dining halls are open? Where should we meet?"
- **Weather impact:** Buffalo winters affect all campus activity and coordination
- **Commuter integration:** "How do commuter students connect with campus life?"
- **International student isolation:** Large international population needs better integration

**Information Flow at UB:**
- **Official:** UB email (ignored), UB Mobile app (basic info), UBLearns (academic only)
- **Semi-official:** Student organization Instagram accounts, club Discord servers
- **Informal:** Class GroupMe chats, friend group texts, overheard conversations
- **Discovery:** Bulletin boards, word-of-mouth, Instagram stories

### UB Campus Infrastructure & Data Sources

**Available RSS Feeds & Data:**
- **Campus events:** UB events calendar RSS feed
- **Dining services:** Menu updates, hours, special events
- **Campus news:** UB news and announcements
- **Academic calendar:** Important dates, deadlines, breaks
- **Weather alerts:** Campus closures, shuttle delays
- **Student organization events:** Some clubs publish RSS feeds

**Physical Infrastructure:**
- **Dining locations:** 15+ dining locations across campuses with varying hours
- **Study spaces:** Libraries (4 main), study lounges, 24-hour spaces
- **Recreation:** Student Union, gym facilities, outdoor spaces
- **Transportation:** Shuttle system, parking, bike paths
- **Weather considerations:** Indoor connections, winter accessibility

**Technology Environment:**
- **WiFi:** UB-Secure campus-wide, reliable in most buildings
- **Student tech:** Mix of iPhone/Android, laptops required for most programs
- **Existing platforms:** UBLearns (required), UB Mobile (low engagement), various club Discord servers

## 2. UB Student Segment Analysis

### International Students at UB (Primary Target - ~4,500 students)

**Unique UB Context:**
- **Large international community:** 14% of student body, critical mass for community
- **Cultural centers:** International Student Services, cultural organizations
- **Academic focus:** Many in STEM programs, high academic achievement pressure
- **Buffalo-specific challenges:** Harsh winters, unfamiliar city, limited transportation
- **Visa/work restrictions:** Limited off-campus work, need campus-based community

**UB-Specific Pain Points:**
- "I don't know which campus events are happening or how to get there"
- "Buffalo winters are isolating - I need indoor community spaces"
- "I want to connect with other international students but don't know how"
- "Shuttle schedules are confusing and I miss campus activities"
- "Dining halls close early and I don't know where to eat with friends"

**Behavioral Patterns at UB:**
- **Academic clustering:** Form study groups within major/program
- **Cultural clustering:** Connect through international student organizations
- **Campus-bound:** Limited off-campus exploration, especially in winter
- **Event-seeking:** Want to attend campus events but need clear information and coordination

### Incoming Students at UB (Secondary Target - ~5,500 new students annually)

**UB-Specific Context:**
- **Orientation programs:** Summer orientation, welcome week activities
- **Housing assignment:** Most live on North Campus, some in downtown apartments
- **Academic transition:** Large university, need to find smaller communities
- **Buffalo newcomers:** Many from NYC/Long Island, unfamiliar with Buffalo

**UB-Specific Pain Points:**
- "UB is huge - how do I find my people in such a big place?"
- "I'm from downstate - I don't know anything about Buffalo or campus"
- "How do I get involved without being overwhelmed by options?"
- "Which dining halls are good? Where do people hang out?"

### General UB Students (Broad Target - ~22,000 undergraduates)

**UB-Specific Context:**
- **Commuter majority:** 60% commute, need different engagement patterns
- **Academic diversity:** Wide range of programs from engineering to liberal arts
- **Buffalo natives:** Some local students, familiar with city but want campus community
- **Transfer students:** Significant transfer population, need integration support

**UB-Specific Pain Points:**
- "As a commuter, I miss out on campus life and spontaneous activities"
- "Events are scattered across multiple campuses and platforms"
- "I want to be more involved but don't know what's happening when"
- "Group projects are hard to coordinate across different schedules and locations"

## 3. UB-Specific Data Integration Strategy

### RSS Feed Integration

**Campus Events Feed:**
- **Source:** UB events calendar RSS
- **Content:** Official events, lectures, performances, student organization events
- **Integration:** Automatic import to Calendar Tool and Spaces event surfaces
- **Value:** Students see all campus events in one place with RSVP capability

**Dining Services Feed:**
- **Source:** Campus Dining RSS/API
- **Content:** Menu updates, hours, special events, closures
- **Integration:** Now Panel shows current dining status, Calendar Tool shows meal times
- **Value:** Real-time dining coordination and meal planning

**Campus News & Alerts:**
- **Source:** UB news RSS, emergency alerts
- **Content:** Weather closures, shuttle delays, campus announcements
- **Integration:** Now Panel priority alerts, Calendar Tool schedule adjustments
- **Value:** Critical campus information without checking multiple sources

**Academic Calendar Feed:**
- **Source:** UB registrar RSS/calendar
- **Content:** Important dates, deadlines, breaks, exam periods
- **Integration:** Calendar Tool academic overlay, Now Panel deadline reminders
- **Value:** Academic planning integrated with social and personal calendars

### Campus-Specific Tool Opportunities

**Shuttle Coordination Tool:**
- **Data source:** UB shuttle tracking (if available) or crowdsourced timing
- **Functionality:** "Next shuttle to North Campus in 8 minutes"
- **Social layer:** "3 people waiting at this shuttle stop"
- **Builder opportunity:** Students create shuttle timing Tools for specific routes

**Dining Coordination Tool:**
- **Data source:** Dining RSS feeds + crowdsourced activity
- **Functionality:** "Dining hall hours, current crowds, menu highlights"
- **Social layer:** "Study group meeting at SU Food Court at 6pm"
- **Builder opportunity:** Students create meal coordination and dining review Tools

**Study Space Finder Tool:**
- **Data source:** Library hours RSS + crowdsourced occupancy
- **Functionality:** "Quiet study spaces available now"
- **Social layer:** "Study group active in Lockwood Library"
- **Builder opportunity:** Students create study group coordination and space review Tools

**Weather-Aware Event Tool:**
- **Data source:** Weather RSS + campus alerts
- **Functionality:** "Outdoor events moved indoors due to weather"
- **Social layer:** "Indoor hangout spots during snowstorm"
- **Builder opportunity:** Students create weather-adaptive activity Tools

## 4. UB-Specific Competitive Landscape

### What UB Students Currently Use

**Official UB Platforms:**
- **UB Mobile app:** Basic dining/shuttle info, low engagement
- **UBLearns:** Required for academics, poor social features
- **UB email:** Official communications, mostly ignored
- **Campus dining app:** Menu/hours only, no social features

**Student-Adopted Platforms:**
- **GroupMe:** Class coordination, club communication
- **Discord:** Gaming communities, some study groups, club servers
- **Instagram:** Event discovery through stories, social proof
- **Snapchat:** Friend coordination, location sharing
- **Google Calendar:** Personal scheduling, some shared calendars

**Gaps in Current UB Ecosystem:**
- **No unified campus information:** Students check 4-5 different sources
- **Poor cross-campus coordination:** Multi-campus events poorly communicated
- **Limited commuter integration:** Commuter students feel disconnected
- **No ambient campus awareness:** Students miss spontaneous opportunities
- **Fragmented group coordination:** Different tools for different groups

### UB-Specific Differentiation Opportunities

**Multi-Campus Integration:**
- Unified view of events and activities across North/South/Downtown campuses
- Shuttle-aware event planning and coordination
- Campus-specific Tool placement and activation

**Commuter Student Integration:**
- Tools that work for both residential and commuter students
- Event discovery that accommodates commuter schedules
- Study group coordination across different availability patterns

**International Student Support:**
- Cultural event discovery and coordination
- International student-specific Spaces and Tools
- Language-friendly interface and community features

**Buffalo Weather Integration:**
- Weather-aware event planning and indoor alternatives
- Winter-specific campus navigation and activity coordination
- Seasonal Tool adaptation and community building

## 5. UB Launch Strategy & Success Metrics

### Summer 2025 Launch Context

**UB Summer Population (~1,000 students):**
- **International students:** ~300 (staying for summer programs/research)
- **Incoming students:** ~200 (early arrival, summer orientation)
- **Continuing students:** ~500 (summer courses, research, internships)
- **Graduate students:** Research-focused, different social patterns

**Summer-Specific Value Propositions:**
- **Reduced social density:** Platform provides connection in low-activity period
- **Campus navigation:** Help students find open facilities and services
- **Event discovery:** Surface summer programming and informal activities
- **Community building:** Create connections before fall semester influx

### UB-Specific Success Metrics

**Campus Integration Metrics:**
- RSS feed event discovery and attendance rates
- Dining coordination usage and satisfaction
- Shuttle timing Tool usage and accuracy
- Multi-campus event participation

**Student Segment Metrics:**
- International student engagement and community formation
- Incoming student orientation Tool usage and social connection
- Commuter student platform adoption and campus involvement
- General student retention and word-of-mouth growth

**UB Platform Health:**
- Cross-campus Tool placement and usage
- Weather-adaptive behavior and Tool usage
- Academic calendar integration and planning usage
- Buffalo-specific community formation and sustainability

---

**Note:** This UB-specific context foundation should guide all product decisions for our launch campus. The RSS feed integration and Buffalo-specific features will be critical differentiators that generic platforms cannot provide. Success at UB will validate our campus-native approach before expanding to other universities. 
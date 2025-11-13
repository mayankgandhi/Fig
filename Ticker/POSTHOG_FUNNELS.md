# PostHog Dashboard Funnels for Ticker

This document provides the complete configuration for PostHog funnels to track user retention and detect bugs in Ticker.

## How to Use This Document

Each funnel below contains:
1. **Funnel Name** - What to call it in PostHog
2. **Purpose** - What the funnel measures
3. **Events** - The exact event sequence to track
4. **Configuration** - Settings for the funnel (time windows, filters)
5. **Alert Thresholds** - When to be notified

## Setup Instructions

1. Log into your PostHog dashboard
2. Navigate to "Insights" → "New Insight" → "Funnel"
3. Add events in the specified order
4. Configure the time window and filters as specified
5. Save with the provided funnel name

---

## RETENTION-FOCUSED FUNNELS

### 1. Core Onboarding → First Alarm Retention

**Purpose:** Measure how many users successfully create and enable their first alarm after completing onboarding.

**Events:**
```
onboarding_started
→ onboarding_permission_granted
→ onboarding_completed
→ alarm_created (within 24 hours)
→ alarm_toggled [is_enabled: true] (within 7 days)
```

**Configuration:**
- Time window: 7 days
- Conversion window: Any time
- Breakdown: None

**Success Metric:** >60% complete all steps

**Alert If:** Drop-off >50% at any step

---

### 2. Week 1 Engagement

**Purpose:** Track early retention and app revisits to identify churn risk.

**Events:**
```
app_launched
→ alarm_created
→ app_foregrounded (Day 2)
→ app_foregrounded (Day 7)
```

**Configuration:**
- Time window: 7 days
- Group by: creation_method property on alarm_created
- Breakdown by: schedule_type

**Success Metric:** >40% return on Day 7

**Alert If:** Day 2 retention <50%

---

### 3. AI Feature Discovery → Repeat Usage

**Purpose:** Measure AI feature stickiness and repeat usage patterns.

**Events:**
```
ai_alarm_create_started
→ ai_alarm_created
→ ai_alarm_create_started (within 7 days)
```

**Configuration:**
- Time window: 7 days
- Filter: Only users with successful first creation
- Breakdown: None

**Success Metric:** >30% create a second AI alarm within 7 days

**Alert If:** Repeat usage <20%

---

### 4. Premium Conversion → Retention

**Purpose:** Track premium user retention after subscription.

**Events:**
```
premium_feature_gate_shown
→ paywall_opened
→ subscription_status_viewed [is_subscribed: true]
→ premium_feature_unlocked
→ app_foregrounded (within 7 days)
```

**Configuration:**
- Time window: 7 days
- Filter: is_subscribed = true
- Breakdown by: feature property

**Success Metric:** >70% of subscribers return within 7 days

**Alert If:** Subscriber retention <60%

---

### 5. Multi-Alarm Power Users

**Purpose:** Identify and track power users who create multiple alarms.

**Events:**
```
alarm_created
→ alarm_created (2nd alarm within 24 hours)
→ alarm_created (3rd alarm within 7 days)
→ app_foregrounded (Day 14)
```

**Configuration:**
- Time window: 14 days
- Breakdown: None
- Cohort: Create "Power Users" cohort at step 3

**Success Metric:** >15% become power users (3+ alarms)

**Alert If:** Power user conversion <10%

---

## BUG DETECTION FUNNELS

### 6. Alarm Creation Success Rate

**Purpose:** Detect creation failures - high drop-off indicates bugs.

**Events:**
```
alarm_create_started
→ [SUCCESS PATH] alarm_created
OR
→ [FAILURE PATH] alarm_creation_failed
```

**Configuration:**
- Time window: 1 hour
- Show both paths
- Breakdown by: schedule_type, error

**Success Metric:** >95% success rate

**Alert If:**
- Failure rate >5%
- Sudden spike in alarm_creation_failed events
- Specific error appears >3 times

---

### 7. AI Parsing Health Check

**Purpose:** Monitor AI feature reliability - track failure rates.

**Events:**
```
ai_generation_started
→ ai_parsing_completed
→ ai_generation_completed
→ ai_alarm_created
```

**Alternative Failure Path:**
```
ai_generation_started
→ ai_parsing_failed
OR
→ ai_generation_failed
```

**Configuration:**
- Time window: 1 hour
- Track both success and failure paths
- Breakdown by: error property

**Success Metric:** >90% parse successfully

**Alert If:**
- Parsing failure rate >10%
- Generation failure rate >15%
- Average parse_time_ms >5000

---

### 8. Permission Grant Flow

**Purpose:** Detect permission issues - low grant rate or crashes.

**Events:**
```
permission_prompt_shown
→ permission_granted
```

**Alternative Path:**
```
permission_prompt_shown
→ permission_denied
→ permission_settings_opened
```

**Configuration:**
- Time window: 10 minutes
- Breakdown by: context property (onboarding vs settings)
- Track both paths

**Success Metric:** >75% grant permission on first prompt

**Alert If:**
- Grant rate <60%
- Settings opened >25% of the time (indicates friction)

---

### 9. Alarm Synchronization Health

**Purpose:** Detect sync delays or failures - should complete quickly.

**Events:**
```
app_foregrounded
→ alarm_sync_started
→ alarm_sync_completed (within 5 seconds)
```

**Configuration:**
- Time window: 5 seconds
- Filter: duration_ms property
- Alert on: duration_ms >5000

**Success Metric:** >98% complete within 5 seconds

**Alert If:**
- >2% take longer than 5 seconds
- Average duration_ms >3000
- Any sync takes >10 seconds

---

### 10. Alarm Edit Success

**Purpose:** Track edit flow completion - drop-offs indicate bugs.

**Events:**
```
alarm_viewed
→ alarm_create_started [source: "edit"]
→ alarm_edited
```

**Configuration:**
- Time window: 10 minutes
- Filter: source = "edit"
- Breakdown: None

**Success Metric:** >90% successfully edit

**Alert If:** Edit completion rate <85%

---

### 11. Countdown Feature Reliability

**Purpose:** Ensure countdown features work end-to-end.

**Events:**
```
alarm_countdown_configured
→ alarm_created [has_countdown: true]
→ alarm_paused OR alarm_stopped OR alarm_countdown_repeated
```

**Configuration:**
- Time window: 30 days
- Filter: has_countdown = true
- Track all interaction types

**Success Metric:** >90% of countdown alarms are interacted with

**Alert If:**
- <70% interaction rate (feature may be broken)
- High ratio of alarm_stopped to alarm_paused (poor UX)

---

### 12. Critical Background Operations

**Purpose:** Monitor background alarm generation failures.

**Events:**
```
alarm_regeneration_started
→ alarm_regeneration_completed
```

**Alternative Failure Path:**
```
alarm_regeneration_started
→ alarm_regeneration_failed
```

**Configuration:**
- Time window: 1 hour
- Breakdown by: error property
- Track both paths

**Success Metric:** >99% regeneration success rate

**Alert If:**
- Any regeneration failure
- Same ticker_id fails twice
- Average generated_count = 0

---

### 13. Empty State to First Alarm

**Purpose:** Detect issues in new user activation flow.

**Events:**
```
empty_state_viewed
→ alarm_create_started OR ai_alarm_create_started
→ alarm_created OR ai_alarm_created
```

**Configuration:**
- Time window: 1 hour
- Filter: has_onboarded = false
- Track both manual and AI paths

**Success Metric:** >70% create an alarm from empty state

**Alert If:** Activation rate <60%

---

## ENGAGEMENT & CHURN RISK FUNNELS

### 14. Today View Engagement

**Purpose:** Track Today tab usage and engagement patterns.

**Events:**
```
app_launched
→ today_view_opened
→ upcoming_alarm_viewed
→ alarm_viewed
```

**Configuration:**
- Time window: 1 day
- Breakdown: None
- Track daily engagement

**Success Metric:** >50% use Today view daily

**Alert If:** Today view usage drops >20%

---

### 15. Search Usage

**Purpose:** Track search feature usage among users with many alarms.

**Events:**
```
alarm_list_viewed [alarm_count > 5]
→ alarm_searched
→ alarm_viewed
```

**Configuration:**
- Time window: 1 hour
- Filter: alarm_count > 5
- Breakdown by: results_count

**Success Metric:** >40% of power users use search

**Alert If:**
- Search usage <30% among users with 10+ alarms
- Average results_count = 0 (search not working)

---

### 16. Settings Exploration (Churn Indicator)

**Purpose:** Track users seeking help - potential churn indicators.

**Events:**
```
settings_opened
→ faq_opened OR roadmap_opened OR help_support_opened
→ app_foregrounded (within 24 hours)
```

**Configuration:**
- Time window: 24 hours
- Track all help-seeking behaviors
- Create "At Risk" cohort

**Success Metric:** >70% return after visiting help

**Alert If:**
- Return rate <60% (indicates unresolved issues)
- Sudden spike in help_support_opened

---

## DASHBOARD SETUP RECOMMENDATIONS

### Page 1: Retention Overview
**Funnels:** #1, #2, #4, #5

**Additional Metrics:**
- DAU/WAU/MAU trend line
- Retention curves (D1, D7, D30)
- Cohort retention table

---

### Page 2: Feature Health & Bug Detection
**Funnels:** #6, #7, #10, #11, #12

**Additional Metrics:**
- Error rate trend (alarm_creation_failed)
- AI feature failure rate trend
- Average sync duration chart

---

### Page 3: Technical Monitoring
**Funnels:** #8, #9, #12

**Additional Metrics:**
- App crash rate
- Average alarm_sync_completed duration
- Permission grant rate over time

---

### Page 4: Growth & Conversion
**Funnels:** #3, #13, #14, #16

**Additional Metrics:**
- New user activation rate
- Premium conversion rate
- Feature adoption rates

---

## CRITICAL ALERTS TO SET UP

### High Priority (Immediate Action Required)

1. **Alarm Creation Failure Spike**
   - Event: `alarm_creation_failed`
   - Threshold: >5% failure rate OR >10 failures in 1 hour
   - Action: Investigate immediately, may need hotfix

2. **Sync Performance Degradation**
   - Event: `alarm_sync_completed` where duration_ms >5000
   - Threshold: >2% of syncs
   - Action: Check server performance, database issues

3. **Background Regeneration Failures**
   - Event: `alarm_regeneration_failed`
   - Threshold: ANY occurrence
   - Action: Critical - alarms won't fire correctly

4. **Permission Grant Rate Drop**
   - Funnel: #8 (Permission Grant Flow)
   - Threshold: <60% grant rate
   - Action: Review permission prompt copy/timing

### Medium Priority (Daily Monitoring)

5. **AI Feature Degradation**
   - Events: `ai_parsing_failed`, `ai_generation_failed`
   - Threshold: >15% failure rate
   - Action: Check AI service status, model performance

6. **Day 1 Retention Drop**
   - Funnel: #2 (Week 1 Engagement)
   - Threshold: Day 2 retention <50%
   - Action: Review onboarding, first-time UX

7. **Premium Subscriber Churn**
   - Funnel: #4 (Premium Conversion → Retention)
   - Threshold: 7-day return rate <60%
   - Action: Engage with churned subscribers

### Low Priority (Weekly Monitoring)

8. **Power User Conversion**
   - Funnel: #5 (Multi-Alarm Power Users)
   - Threshold: <10% create 3+ alarms
   - Action: Consider engagement campaigns

9. **Feature Discovery**
   - Funnel: #14 (Today View Engagement)
   - Threshold: Usage drops >20%
   - Action: Improve feature discoverability

---

## COHORT DEFINITIONS

Create these cohorts in PostHog for segmented analysis:

### User Lifecycle Cohorts

1. **New Users**
   - Condition: `onboarding_completed` within last 7 days

2. **Active Users**
   - Condition: `app_foregrounded` at least 3 times in last 7 days

3. **Power Users**
   - Condition: `alarm_created` at least 3 times (all-time)
   - AND: `app_foregrounded` at least 5 times in last 7 days

4. **At Risk Users**
   - Condition: `help_support_opened` in last 7 days
   - OR: No `app_foregrounded` in last 14 days
   - AND: Has at least one alarm created

5. **Churned Users**
   - Condition: No `app_foregrounded` in last 30 days
   - AND: `alarm_created` exists (all-time)

### Feature Usage Cohorts

6. **AI Users**
   - Condition: `ai_alarm_created` at least once

7. **Manual-Only Users**
   - Condition: `alarm_created` exists
   - AND: Never triggered `ai_alarm_create_started`

8. **Premium Subscribers**
   - Condition: `subscription_status_viewed` where is_subscribed = true
   - Within last 90 days

---

## RECOMMENDED ANALYSIS FREQUENCY

### Daily
- Funnel #6: Alarm Creation Success Rate
- Funnel #9: Alarm Synchronization Health
- New user activation rate

### Weekly
- All Retention Funnels (#1-5)
- Bug Detection Funnels (#6-13)
- Cohort retention analysis

### Monthly
- Long-term retention curves
- Premium subscriber LTV
- Feature adoption trends
- Churn analysis by cohort

---

## INTEGRATION WITH PRODUCT DECISIONS

### Use These Funnels To:

1. **Prioritize Bug Fixes**
   - Any funnel with <90% completion rate
   - High drop-off indicates critical bugs

2. **Validate Feature Launches**
   - Create similar funnels for new features
   - Compare adoption vs. existing features

3. **Guide Product Roadmap**
   - Low engagement funnels = features need improvement
   - High engagement funnels = double down on these

4. **Identify Onboarding Issues**
   - Funnel #1 shows exactly where users drop off
   - Iterate on problem steps

5. **Monitor Health in Production**
   - Technical funnels (#8, #9, #12) are early warning system
   - Catch bugs before user complaints

---

## NOTES

- All event names match exactly what's implemented in `AnalyticsEvents.swift`
- Time windows are recommendations - adjust based on your user behavior
- Set up Slack/email alerts for critical thresholds
- Review funnel performance weekly in team meetings
- Update thresholds as your app matures and patterns emerge


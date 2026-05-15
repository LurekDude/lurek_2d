# Block Simulator — Domain Blueprints & Examples

> Canonical examples and real-world domain models for the block simulator.
> Core system design lives in [BLOCK-DESIGN.md](BLOCK-DESIGN.md).
> Mechanics reference lives in [MECHANICS-GUIDE.md](MECHANICS-GUIDE.md).

---

## Table of Contents

- [1. Worked Example: Software Feature Pipeline](#1-worked-example-software-feature-pipeline)
- [2. Cross-Cutting Simulation Patterns](#2-cross-cutting-simulation-patterns)
- [3. Real-World Domain Blueprints](#3-real-world-domain-blueprints)
  - [3.1 Manufacturing — Automotive Assembly Line](#31-manufacturing--automotive-assembly-line)
  - [3.2 Healthcare — Emergency Department Patient Flow](#32-healthcare--emergency-department-patient-flow)
  - [3.3 Financial Services — Trade Order Lifecycle](#33-financial-services--trade-order-lifecycle)
  - [3.4 IT Service Management — ITSM / ITIL Incident Flow](#34-it-service-management--itsm--itil-incident-flow)
  - [3.5 Logistics — E-Commerce Fulfillment](#35-logistics--e-commerce-fulfillment)
  - [3.6 Software Delivery — CI/CD Pipeline](#36-software-delivery--cicd-pipeline)
  - [3.7 Human Resources — Recruitment Pipeline](#37-human-resources--recruitment-pipeline)
  - [3.8 Banking — Loan Origination](#38-banking--loan-origination)
  - [3.9 Energy — Power Grid Fault Management](#39-energy--power-grid-fault-management)
  - [3.10 Legal / Compliance — Contract Lifecycle Management](#310-legal--compliance--contract-lifecycle-management)
  - [3.11 Construction — Project Phase Management](#311-construction--project-phase-management)
  - [3.12 Retail — Merchandise Planning & Buying](#312-retail--merchandise-planning--buying)
  - [3.13 Pharmaceutical — Drug Development Pipeline](#313-pharmaceutical--drug-development-pipeline)
  - [3.14 Public Sector — Planning Permission Authority](#314-public-sector--planning-permission-authority)
  - [3.15 Insurance — Claims Processing](#315-insurance--claims-processing)
- [4. Extended YAML Graph Examples](#4-extended-yaml-graph-examples)
  - [4.1 HTTP Request Approval Pipeline](#41-http-request-approval-pipeline)
  - [4.2 Manufacturing Rework Loop](#42-manufacturing-rework-loop)
  - [4.3 IT Incident Parallel SOC Investigation](#43-it-incident-parallel-soc-investigation)
  - [4.4 Financial Trade Settlement with Saga Compensation](#44-financial-trade-settlement-with-saga-compensation)
  - [4.5 Content Moderation with Human-in-the-Loop](#45-content-moderation-with-human-in-the-loop)
- [5. Layered Composite Examples](#5-layered-composite-examples)
  - [5.1 Two-Layer: Software Feature Sprint](#51-two-layer-software-feature-sprint)
  - [5.2 Three-Layer: Software Development Department](#52-three-layer-software-development-department)

---

## 1. Worked Example: Software Feature Pipeline

> See [BLOCK-DESIGN.md](BLOCK-DESIGN.md) §2–§5 for port anatomy and [MECHANICS-GUIDE.md](MECHANICS-GUIDE.md) for mechanic details.

```
[ Requirements ]──(feature_spec)──▶[ Developer ]──(draft_code)──▶[ Code Review ]──(approved_code)──▶[ Deploy ]
                                        │                                ▲▼
                                  [worker_hours]              [filter: complexity < 10]
                                  [skill >= 5]
                                  value_cost: 150/run
```

```yaml
- id: developer
  label: "Developer"
  type: processor
  description: "Writes code from a feature spec. Needs skilled worker hours."
  ports:
    data_in:  [ feature_spec ]
    data_out: [ draft_code ]
    trigger_in:  true
    event_out:
      on_complete: code_written
      on_fail: blocked
    value_cost:
      amount: 150.0
      type: labor
  container:
    capacity: 5
    strategy: priority
    priority_field: business_value
  script:
    fires_on: any
    concurrency: 1
    requires:
      - type: worker_hours
        count: 8
        attribute: skill_level
        min_value: 5
    steps:
      - id: analyze
        duration_ms: 800
        fail_chance: 0.0
      - id: write
        duration_ms: 2000
        fail_chance: 0.05
        on_fail: emit_event
      - id: test_local
        duration_ms: 600
        output: draft_code
        fail_chance: 0.10
        on_fail: reject
    converts:
      - from: feature_spec
        to: draft_code
        ratio: 1
```

---

## 2. Cross-Cutting Simulation Patterns

These named patterns compose existing mechanics into reusable design idioms.
See [MECHANICS-GUIDE.md](MECHANICS-GUIDE.md) for details on each referenced mechanic.

| Pattern                | Mechanics used                             | Models                                                  |
| ---------------------- | ------------------------------------------ | ------------------------------------------------------- |
| **Dead reckoning**     | tap + accumulator + alert                  | detect throughput deviation from expected baseline      |
| **Heartbeat**          | schedule → sink with aging                 | prove a feed is alive; alert on silence                 |
| **Watchdog**           | tap + circuit_breaker                      | kill a feed if data quality degrades past threshold     |
| **Catch-up replay**    | dead_letter + replay                       | process backlog after downstream outage resumes         |
| **Blue/green routing** | router + context variable                  | A/B test two processing paths with traffic split        |
| **Shadow mode**        | split + both paths + comparator tap        | run new logic parallel without affecting production     |
| **Canary release**     | rate_limiter + context + adaptive          | slowly increase traffic % to new block version          |
| **Chaos injection**    | filter with random fail_chance             | deliberately degrade blocks to test resilience          |
| **Token passing**      | signal edges only between blocks           | shared lock pattern — no data carried                   |
| **Event sourcing**     | audit_trail on every item + sink           | rebuild any state by replaying the item log             |
| **CQRS**               | split: command vs. query data paths        | separate read/write optimization lanes                  |
| **Debounce**           | accumulator + timer + batch_timeout        | ignore rapid-fire events; act on final stable state     |
| **Bulkhead**           | separate resource pools per criticality    | isolate P1 pool so P3 surge cannot starve critical path |
| **Saga**               | saga_id + compensation steps               | distributed multi-block transaction with rollback       |
| **Saga with fallback** | saga + dead_letter + human_approval        | partial failure goes to operator for manual resolution  |
| **Leaky bucket**       | rate_limiter: token_bucket + queue         | smooth burst traffic into steady downstream flow        |
| **Fan-out/fan-in**     | split + N parallel processors + join       | parallel acceleration with guaranteed merge point       |
| **Priority lane**      | router → separate high/low pools           | fast-track urgent items independently of normal flow    |
| **Seasonal scaling**   | context scenario + adaptive concurrency    | simulate peak vs. off-peak capacity requirements        |
| **Health degradation** | resource health + circuit_breaker + repair | machine that ages, breaks, and is repaired              |

---

## 3. Real-World Domain Blueprints

Each blueprint lists the key blocks, dominant mechanics, and what the simulation reveals. Use as starting templates.
See [BLOCK-DESIGN.md](BLOCK-DESIGN.md) for block anatomy and [MECHANICS-GUIDE.md](MECHANICS-GUIDE.md) for mechanic specifications.

---

### 3.1 Manufacturing — Automotive Assembly Line

**Process**: Stamping → welding → painting → final assembly → end-of-line test

| Block                | Key mechanics                                          |
| -------------------- | ------------------------------------------------------ |
| `stamping_press`     | resource pool, health degradation, fail_chance → scrap |
| `welding_robot_bank` | concurrency: 8, adaptive, health                       |
| `paint_booth`        | time_window: Mon-Fri 06:00-22:00, batch_size: 4        |
| `quality_gate_body`  | router: weld_score >= 0.95                             |
| `rework_station`     | loopback, max_retry: 2 then dead_letter                |
| `jit_parts_supplier` | schedule: interval, circuit_breaker on supplier API    |
| `final_assembly`     | join: [ body, engine, interior ] key: vehicle_id       |
| `end_of_line_test`   | probabilistic: 97% pass / 2% rework / 1% scrap         |

**Reveals**: Robot breakdown → queue spike → downstream starvation. Paint booth capacity as throughput bottleneck. JIT delay → assembly stoppage. Shift gaps create overnight WIP buildup.

---

### 3.2 Healthcare — Emergency Department Patient Flow

**Process**: Arrival → triage → registration → doctor → diagnostics → treatment → discharge or admission

| Block                   | Key mechanics                                       |
| ----------------------- | --------------------------------------------------- |
| `ambulance_arrival`     | schedule: Poisson via probabilistic                 |
| `triage_nurse`          | router: critical / urgent / non-urgent lanes        |
| `waiting_room`          | aging escalation → re-triage after 4h, capacity: 40 |
| `ed_doctor`             | resource pool: 6 doctors, concurrency: 3 each       |
| `radiology`             | resource pool: 2 scanners, rate_limiter: 15/hr      |
| `lab_processing`        | batch_size: 10, result → back to doctor             |
| `hospital_bed`          | resource pool: 200 beds, on_unavailable: queue      |
| `discharge_coordinator` | human_approval for complex cases                    |

**Reveals**: Friday night surge → doctor pool saturation → 6h wait. Scanner downtime cascades. Boarding patients block ED beds. Nurse strike simulation (reduce pool) → collapse timeline.

---

### 3.3 Financial Services — Trade Order Lifecycle

**Process**: Order → compliance → risk → routing → execution → settlement → reporting

| Block                  | Key mechanics                                           |
| ---------------------- | ------------------------------------------------------- |
| `order_intake`         | rate_limiter: 1000/sec token bucket                     |
| `pre_trade_compliance` | split to: sanctions / position / kyc; join all_required |
| `compliance_join`      | timeout: 500ms → auto_reject                            |
| `risk_engine`          | probabilistic: 94% pass / 5% flag / 1% block            |
| `exchange_connector`   | circuit_breaker: 3 fails → open, half_open 30s          |
| `settlement_t2`        | time_window: settlement hours; aging to T+2             |
| `trade_reporting`      | tap on completed trades → audit_trail                   |
| `reconciliation`       | join: executed vs confirmed, key: trade_id              |

**Reveals**: Flash crash opens circuit → reroute surge. Compliance timeout SLA breach cascade. Settlement failure → saga compensation (trade unwind). Market open surge saturates risk engine.

---

### 3.4 IT Service Management — ITSM / ITIL Incident Flow

**Process**: Incident intake → triage → L1 → L2 escalation → resolution → closure

| Block                   | Key mechanics                                              |
| ----------------------- | ---------------------------------------------------------- |
| `incident_intake`       | multi-channel: monitoring auto + portal manual             |
| `auto_classifier`       | probabilistic: P1/P2/P3 severity                           |
| `p1_fast_track`         | circuit_breaker + human_approval: 15min timeout → escalate |
| `l1_support`            | resource: 10 agents, concurrency: 5 each                   |
| `sla_timer`             | aging: P1→15min / P2→4h / P3→24h → sla_breach event        |
| `change_advisory_board` | human_approval + time_window: Wed 14:00-16:00              |
| `cmi_bridge`            | tap → problem_management (pattern detection)               |

**Reveals**: P1 storm after deployment → L1 flood → L2 saturation. CAB weekly window as change bottleneck. SLA breach rate climbing vs. L1 pool size. Auto-resolver impact on throughput.

---

### 3.5 Logistics — E-Commerce Fulfillment

**Process**: Order → fraud check → inventory reservation → pick → pack → label → carrier → delivery → POD

| Block                   | Key mechanics                                           |
| ----------------------- | ------------------------------------------------------- |
| `order_intake`          | rate_limiter: burst_capacity 10000 (Black Friday model) |
| `fraud_detection`       | probabilistic: 98% pass / 1.5% review / 0.5% block      |
| `inventory_reservation` | resource: stock_pool, on_unavailable: backorder queue   |
| `conveyor_sorter`       | router by zone, rate_limiter: 800/hr                    |
| `label_printer`         | resource pool: 5 printers, circuit_breaker on WMS API   |
| `carrier_handover`      | time_window: pickup windows, batch by carrier           |
| `last_mile_delivery`    | probabilistic: 94% delivered / 4% attempted / 2% failed |
| `returns_initiation`    | saga compensation: inventory_return rollback            |

**Reveals**: Peak demand: sorter becomes bottleneck. Printer API outage → circuit opens. Out-of-stock reservation fails → backorder aging → cancellations. Returns spike load on reverse logistics.

---

### 3.6 Software Delivery — CI/CD Pipeline

**Process**: Commit → lint → unit tests → build → integration → security scan → staging → smoke test → production → health check

| Block                | Key mechanics                                          |
| -------------------- | ------------------------------------------------------ |
| `git_commit_trigger` | trigger_in from webhook                                |
| `test_runner`        | split to 3 suites, join all_required, timeout: 10min   |
| `artifact_builder`   | resource: build_agent_pool (5)                         |
| `sast_scanner`       | probabilistic: 90% pass / 8% warn / 2% critical_block  |
| `staging_deployer`   | resource: staging_env_pool (3)                         |
| `change_freeze_gate` | time_window: blocks deploys during freeze period       |
| `canary_deployer`    | adaptive: 1% → 10% → 50% → 100% via error_rate context |
| `rollback_trigger`   | saga compensation on health check failure              |

**Reveals**: Agent pool saturation → commit latency SLA breach. Flaky integration test opens circuit. Friday deploy: change freeze → queue over weekend. Canary rollback sensitivity tuning.

---

### 3.7 Human Resources — Recruitment Pipeline

**Process**: Application → screening → phone → technical assessment → panel interview → offer → background check → onboarding

| Block                     | Key mechanics                                         |
| ------------------------- | ----------------------------------------------------- |
| `ats_intake`              | context: demand_multiplier for hiring surge           |
| `cv_auto_screener`        | probabilistic: 60% reject / 35% phone / 5% fast_track |
| `recruiter_phone_screen`  | resource: recruiter_pool (4), human_approval          |
| `technical_assessment`    | time_window: 5 business days, aging → expire          |
| `panel_interview`         | join: 3 panelists, all_required, resource pool        |
| `background_check`        | circuit_breaker (external), timeout: 5 business days  |
| `onboarding_orchestrator` | fan_out to: IT_setup / badge / payroll                |
| `probation_tracker`       | aging: 90 days → human_approval: pass/fail            |

**Reveals**: Recruiter pool overwhelmed → phone screen queue 3 weeks. Panel unavailability bottleneck for senior roles. Background check delay → offer expiry → candidate drop-out rate.

---

### 3.8 Banking — Loan Origination

**Process**: Application → eligibility → credit check → valuation → underwriting → approval → documentation → disbursement

| Block                | Key mechanics                                                       |
| -------------------- | ------------------------------------------------------------------- |
| `eligibility_engine` | router: hard reject / soft reject / eligible                        |
| `credit_bureau_call` | circuit_breaker (external API), rate_limiter: 100/min               |
| `property_valuation` | human_approval: surveyor, time_window: 10 business days             |
| `underwriting_ai`    | probabilistic: 70% auto / 20% manual / 10% decline                  |
| `approval_committee` | join: credit + valuation + underwriting; time_window: Mon/Thu 10:00 |
| `esign_dispatch`     | circuit_breaker on docusign API, compensation: re-send on fail      |
| `disbursement`       | time_window: banking hours, saga compensation: unwind on fail       |

**Reveals**: Valuation queue → application abandonment. Committee meeting twice/week → batch lag. Credit bureau outage → stack. Auto-underwriting threshold tuning vs. underwriter load.

---

### 3.9 Energy — Power Grid Fault Management

**Process**: Sensor alarm → classification → crew dispatch → repair → test → restore

| Block                    | Key mechanics                                              |
| ------------------------ | ---------------------------------------------------------- |
| `alarm_storm_suppressor` | batch within 60s, deduplicate by substation                |
| `fault_classifier`       | router: P1_transmission / P2_distribution / P3_metering    |
| `crew_dispatcher`        | resource: crew_pool (zone-based), human_approval for P1    |
| `permit_to_work`         | human_approval + audit_trail + time_window: daylight hours |
| `field_repair`           | probabilistic: 90% fixed / 8% escalate / 2% major_incident |
| `regulatory_report`      | tap on all P1 events, time_window: 30min SLA               |
| `restoration`            | saga compensation: if test fails → re-isolate              |

**Reveals**: Storm event: 50 simultaneous alarms → dispatcher overwhelmed. Crew shortage doubles repair cycle time → customer minutes lost. Permit bottleneck on overnight work. Cascade fault from upstream restoration.

---

### 3.10 Legal / Compliance — Contract Lifecycle Management

**Process**: Request → drafting → legal review → negotiation → approval → execution → obligation tracking → renewal

| Block                 | Key mechanics                                                       |
| --------------------- | ------------------------------------------------------------------- |
| `template_selector`   | router: pre-approved templates bypass legal (throughput fast path)  |
| `legal_drafting`      | resource: lawyer_pool, human_approval: senior review for high-value |
| `risk_scoring`        | probabilistic: low / medium / high → additional review              |
| `negotiation_tracker` | aging: rounds > 5 → escalate; items carry version history           |
| `approvals_matrix`    | split by value: finance / legal / exec; join all                    |
| `esign_dispatch`      | circuit_breaker on docusign, compensation: re-send on fail          |
| `obligation_monitor`  | schedule: daily; aging → alert at 90-day threshold                  |
| `renewal_trigger`     | aging: 90 days before expiry → renewal_due event                    |

**Reveals**: Lawyer constraint → contract cycle time exceeds 30 days. Exec approval blocking million-dollar deals. Template bypass throughput impact. Obligation breach rate when monitoring gaps exist.

---

### 3.11 Construction — Project Phase Management

**Process**: Design → planning approval → procurement → groundwork → structure → MEP → finishing → inspection → handover

| Block                         | Key mechanics                                                    |
| ----------------------------- | ---------------------------------------------------------------- |
| `planning_authority`          | time_window: statutory 8-week period, probabilistic: 70% approve |
| `procurement_tendering`       | fan_out to: structural / MEP / groundwork; join all awarded      |
| `material_delivery`           | circuit_breaker on supplier, resource: site_storage_pool, aging  |
| `groundwork_crew`             | resource pool, time_window: Mon-Sat 07:30-18:00                  |
| `weather_gate`                | filter: blocks when context.weather = bad_weather                |
| `building_control_inspection` | human_approval, time_window: 5 business days, probabilistic      |
| `practical_completion`        | join: inspection_pass + snagging_clear + as_built_docs           |

**Reveals**: Planning delay cascades to procurement gap. Weather disruption critical path impact. Material delivery failure → site idle cost per day. Inspection queue → completion date drift.

---

### 3.12 Retail — Merchandise Planning & Buying

**Process**: Range plan → supplier selection → sampling → production order → QC → inbound → allocation → replenishment

| Block                | Key mechanics                                          |
| -------------------- | ------------------------------------------------------ |
| `factory_production` | probabilistic: on_time 75% / delay 20% / cancel 5%     |
| `qc_inspection`      | router: pass / minor_rework / major_fail → renegotiate |
| `inbound_logistics`  | aging: late arrival → markdown_flag on item            |
| `allocation_engine`  | router by store tier, fan_out to store clusters        |
| `replenishment`      | schedule: nightly, reads stock_level context variable  |

**Reveals**: Factory cancel → range gap → lost sales value. QC fail spike → supplier performance. Inbound delay → markdown flag rate → margin erosion.

---

### 3.13 Pharmaceutical — Drug Development Pipeline

**Process**: Discovery → in-vitro → preclinical → Phase I → Phase II → Phase III → regulatory submission → approval → launch

| Block                      | Key mechanics                                                     |
| -------------------------- | ----------------------------------------------------------------- |
| `in_vitro_screening`       | batch_size: 96 (well plate), probabilistic: 10% advance           |
| `preclinical_study`        | duration: 12-18 months sim-time, resource: ethics_pool            |
| `ind_filing`               | human_approval + audit_trail, probabilistic: 80% approve          |
| `safety_monitoring_board`  | tap on adverse events, circuit_breaker: trial pause on serious AE |
| `phase_3_trial`            | join: efficacy + safety + PK arms, massive resource requirement   |
| `post_market_surveillance` | tap on launched products, aging detects safety signals            |

**Reveals**: Pipeline attrition rates → expected NDA submissions per year. Safety signal mid-Phase 3 → circuit breaker → portfolio value impact. Enrollment stretch from site count variation.

---

### 3.14 Public Sector — Planning Permission Authority

**Process**: Application → validation → consultation → officer assessment → committee → decision → appeal

| Block                    | Key mechanics                                                    |
| ------------------------ | ---------------------------------------------------------------- |
| `validation_check`       | human_approval: completeness, 21-day statutory clock starts      |
| `neighbour_notification` | fan_out to adjacent properties, time_window: 21-day consultation |
| `statutory_consultees`   | parallel: highways / environment / heritage; join all required   |
| `committee_report`       | time_window: monthly committee cycle; aging → missed cycle       |
| `planning_committee`     | human_approval: councillor vote, probabilistic: 65% approve      |
| `appeal_process`         | triggered by refusal event, resource: planning_inspector_pool    |

**Reveals**: Officer shortage → past statutory 8-week target. Committee cycle misses → 4-week delay per miss. Statutory consultee bottleneck as system constraint.

---

### 3.15 Insurance — Claims Processing

**Process**: FNOL → triage → fraud screening → liability → investigation → settlement → payment → recovery

| Block                   | Key mechanics                                              |
| ----------------------- | ---------------------------------------------------------- |
| `fnol_intake`           | context: catastrophe_multiplier on weather events          |
| `auto_triage`           | probabilistic: 40% fast_track / 50% standard / 10% complex |
| `fraud_screening`       | circuit_breaker on external DB, probabilistic: 2% flag     |
| `field_inspector`       | resource pool, time_window, geographic routing             |
| `reserve_setting`       | human_approval above threshold, value_stamp on item        |
| `payment_authorization` | parallel: finance + fraud_final; join all                  |
| `recovery_subrogation`  | saga: pursue recovery, compensate if fails                 |
| `catastrophe_mode`      | context scenario override: pool halved, volume x15         |

**Reveals**: Flood event → claim surge → inspector overwhelmed. Fraud threshold tightening vs. throughput vs. leakage. Reserve adequacy vs. settlement development variance.

---

## 4. Extended YAML Graph Examples

Each example below is a complete graph definition using the block vocabulary from [BLOCK-DESIGN.md](BLOCK-DESIGN.md).
**All inputs are on the LEFT side** of every block; **all outputs are on the RIGHT side**.
Flow runs left → right. Edges connect RIGHT outputs to LEFT inputs.

---

### 4.1 HTTP Request Approval Pipeline

**Scenario**: HTTP requests enter a validator, then a policy engine. Invalid requests and policy
rejections route to an error handler. API costs tracked per call. Circuit breaker opens on >20%
rejection rate. Rate limiter absorbs ingest bursts.

```
in:http_request --> [validator] --> in:valid_request --> [policy_engine] --> out:decision
                        |                                      |
                   event:invalid                        event:rejected
                        +--------------+----------------+
                                       v
                               [error_handler]
```

```yaml
graph:
  id: http_approval_pipeline
  label: "HTTP Request Approval"

  data_types:
    - type: http_request
    - type: valid_request
    - type: decision

  resources:
    - id: api_workers
      type: worker_pool
      capacity: 20

  blocks:

    - id: validator
      label: "Request Validator"
      type: processor
      ports:
        trigger_in:
          - id: start             # ▲ LEFT: fires on request arrival
        data_in:
          - type: http_request    # □ LEFT
        event_out:
          - id: valid             # ▼ RIGHT -> policy_engine.start
          - id: invalid           # ▼ RIGHT -> error_handler.on_invalid
        value_cost:
          amount: 0.001           # ⊖ RIGHT: $0.001 per run
        data_out:
          - type: valid_request   # □ RIGHT
      rate_limiter:
        type: token_bucket
        tokens_per_second: 500
        burst_capacity: 2000
        on_throttle: queue
      script:
        fires_on: any
        requires_resource:
          pool: api_workers
          slots: 1
          on_unavailable: queue
        steps:
          - id: check_schema
            duration_ms: 2
            fail_chance: 0.03
            on_fail: emit_event
          - id: check_auth
            duration_ms: 5
            fail_chance: 0.08
            on_fail: emit_event
        converts:
          - from: http_request
            to: valid_request
            ratio: 1

    - id: policy_engine
      label: "Policy Engine"
      type: processor
      ports:
        trigger_in:
          - id: start             # ▲ LEFT: from validator.valid
        filter_in:
          - id: policy_config     # ◇ LEFT: inject rule set at runtime
        data_in:
          - type: valid_request   # □ LEFT
        event_out:
          - id: approved          # ▼ RIGHT
          - id: rejected          # ▼ RIGHT -> error_handler.on_rejected
        value_cost:
          amount: 0.005           # ⊖ RIGHT
        value_out:
          - id: api_revenue       # ○ RIGHT: $0.10 per approved request
        data_out:
          - type: decision        # □ RIGHT
      circuit_breaker:
        mode: rate
        fail_threshold: 0.20
        half_open_after_ms: 5000
        on_open: emit_event
      script:
        fires_on: all
        concurrency:
          mode: fixed
          value: 10
        outcome_distribution:
          - outcome: approved
            probability: 0.92
            output_type: decision
          - outcome: rejected
            probability: 0.08
            emit_event: rejected

    - id: error_handler
      label: "Error Handler"
      type: sink
      ports:
        trigger_in:
          - id: on_invalid        # ▲ LEFT: from validator.invalid
          - id: on_rejected       # ▲ LEFT: from policy_engine.rejected
        event_out:
          - id: error_logged      # ▼ RIGHT
      script:
        fires_on: any
        audit_stamp:
          enabled: true
          fields: [block_id, timestamp, error_type, request_id]

  edges:
    - from: validator      to: policy_engine   type: data    item_type: valid_request
    - from: validator.event_out.valid          to: policy_engine.trigger_in.start     type: signal
    - from: validator.event_out.invalid        to: error_handler.trigger_in.on_invalid  type: signal
    - from: policy_engine.event_out.rejected   to: error_handler.trigger_in.on_rejected type: signal
    - from: validator.value_cost               to: ledger  type: value
    - from: policy_engine.value_cost           to: ledger  type: value
    - from: policy_engine.value_out.api_revenue to: ledger type: value
```

---

### 4.2 Manufacturing Rework Loop

**Scenario**: Raw blanks enter a stamping press. A QC gate routes good parts to assembly and defects
to a rework station. Reworked parts loop back to the press. After 2 failed rework attempts, the item
is scrapped (goes to DLQ). The press has a health meter — degradation triggers a maintenance block
that fires a `maintenance_done` signal to restore health.

```
in:blank --> [stamping_press] --> [quality_gate] --> out:good_part --> [assembly]
                  ^                     |
          in:rework_part          out:rejected_part
                  |                     v
             [rework] <-----------[rework station]
             [maintenance] <-- event:machine_fail
```

```yaml
graph:
  id: manufacturing_rework
  label: "Stamping + QC + Rework Loop"

  resources:
    - id: machine_ops_pool
      type: worker_pool
      capacity: 3

  blocks:

    - id: stamping_press
      label: "Stamping Press"
      type: processor
      ports:
        trigger_in:
          - id: start_shift       # ▲ LEFT: from shift scheduler
          - id: rework_ready      # ▲ LEFT: from rework.rework_done (loopback)
        filter_in:
          - id: speed_params      # ◇ LEFT: operator adjusts speed at runtime
        data_in:
          - type: blank           # □ LEFT: raw metal blanks
          - type: rework_part     # □ LEFT: looped-back rework items
        event_out:
          - id: part_done         # ▼ RIGHT
          - id: machine_fail      # ▼ RIGHT -> maintenance.on_machine_fail
        value_cost:
          amount: 12.0            # ⊖ RIGHT: $12 per run
        value_out:
          - id: throughput_value  # ○ RIGHT: $45 per completed part
        data_out:
          - type: stamped_part    # □ RIGHT -> quality_gate
      container:
        capacity: 20
        strategy: fifo
        overflow: block
        aging:
          field: age_ms
          escalation_rules:
            - after_ms: 14400000
              set_priority: urgent
          expiry_ms: 86400000
          on_expire: dead_letter
      resource:
        health: 1.0
        degradation_per_run: 0.02
        failure_threshold: 0.15
        repair_signal: maintenance_done
        repair_amount: 0.85
      script:
        fires_on: any
        concurrency:
          mode: fixed
          value: 1
        requires_resource:
          pool: machine_ops_pool
          slots: 1
          on_unavailable: queue
        steps:
          - id: load
            duration_ms: 400
          - id: press
            duration_ms: 800
            fail_chance: 0.03
            on_fail: emit_event
          - id: unload
            duration_ms: 300
            output: stamped_part
        converts:
          - from: blank
            to: stamped_part
            ratio: 1
          - from: rework_part
            to: stamped_part
            ratio: 1
        cost_stamp:
          label: press_cost
          amount_formula: "duration_ms / 1000.0 * 15.0"
          accumulate_on: item

    - id: quality_gate
      label: "QC Gate"
      type: router
      ports:
        data_in:
          - type: stamped_part    # □ LEFT
        event_out:
          - id: pass_event        # ▼ RIGHT
          - id: fail_event        # ▼ RIGHT
        data_out:
          - type: good_part       # □ RIGHT -> assembly
          - type: rejected_part   # □ RIGHT -> rework
      filter:
        mode: route
        routes:
          - condition: "item.rework_count >= 2"
            output_port: dead_letter
          - condition: "item.quality >= 0.85"
            output_port: data_out.good_part
          - default: data_out.rejected_part

    - id: rework
      label: "Rework Station"
      type: processor
      ports:
        trigger_in:
          - id: on_fail           # ▲ LEFT: from quality_gate.fail_event
        data_in:
          - type: rejected_part   # □ LEFT
        event_out:
          - id: rework_done       # ▼ RIGHT -> stamping_press.rework_ready
        value_cost:
          amount: 8.0             # ⊖ RIGHT
        data_out:
          - type: rework_part     # □ RIGHT -> stamping_press (loopback)
      script:
        fires_on: any
        steps:
          - id: inspect_defect
            duration_ms: 600
          - id: correct
            duration_ms: 1200
            output: rework_part
            fail_chance: 0.05
            on_fail: emit_event

    - id: maintenance
      label: "Maintenance Crew"
      type: processor
      ports:
        trigger_in:
          - id: on_machine_fail   # ▲ LEFT: from stamping_press.machine_fail
        event_out:
          - id: maintenance_done  # ▼ RIGHT -> stamping_press.resource.repair_signal
        value_cost:
          amount: 250.0
      script:
        fires_on: trigger_only
        steps:
          - id: diagnose
            duration_ms: 1800000
          - id: repair
            duration_ms: 3600000
            fail_chance: 0.05

  edges:
    - from: stamping_press  to: quality_gate  type: data   item_type: stamped_part
    - from: quality_gate    to: rework        type: data   item_type: rejected_part
    - from: rework          to: stamping_press type: data  item_type: rework_part
    - from: stamping_press.event_out.machine_fail  to: maintenance.trigger_in.on_machine_fail  type: signal
    - from: quality_gate.event_out.fail_event      to: rework.trigger_in.on_fail               type: signal
    - from: rework.event_out.rework_done           to: stamping_press.trigger_in.rework_ready  type: signal
    - from: maintenance.event_out.maintenance_done to: stamping_press.resource.repair_signal   type: signal
    - from: stamping_press.backpressure_out        to: upstream_feeder.throttle_in             type: backpressure
```

---

### 4.3 IT Incident Parallel SOC Investigation

**Scenario**: Monitoring alerts are classified by severity. P1 alerts fan out to two parallel
investigation lanes (network and application). Both must return findings before the incident can close.
If either lane finds a root cause requiring rollback, a saga coordinator fires. Items in the
investigation queue escalate after 15 minutes (P1 SLA).

```
in:raw_alert --> [classifier] --(P1)--> [split] --> [soc_network] --                                                --> [soc_app    ] --> [join] --> [incident_close]
                              --(P2/3)--> [std_queue]
```

```yaml
graph:
  id: it_incident_parallel
  label: "IT Incident Parallel Investigation"

  resources:
    - id: soc_analysts
      type: worker_pool
      capacity: 8

  blocks:

    - id: alert_classifier
      label: "Alert Classifier"
      type: processor
      ports:
        trigger_in:
          - id: new_alert         # ▲ LEFT: from monitoring bus
        filter_in:
          - id: severity_matrix   # ◇ LEFT: on-call severity thresholds
        data_in:
          - type: raw_alert       # □ LEFT
        event_out:
          - id: p1_routed         # ▼ RIGHT -> investigation_split.on_p1
          - id: p23_routed        # ▼ RIGHT -> std_queue
        data_out:
          - type: p1_incident     # □ RIGHT
          - type: std_incident    # □ RIGHT
      script:
        fires_on: any
        outcome_distribution:
          - outcome: p1
            probability: 0.05
            output_type: p1_incident
          - outcome: p2_or_p3
            probability: 0.95
            output_type: std_incident
        audit_stamp:
          enabled: true
          fields: [block_id, timestamp, severity, alert_id]

    - id: investigation_split
      label: "P1 Split: Network + App"
      type: split
      ports:
        trigger_in:
          - id: on_p1             # ▲ LEFT: from classifier.p1_routed
        data_in:
          - type: p1_incident     # □ LEFT
        event_out:
          - id: split_done        # ▼ RIGHT
        data_out:
          - type: p1_incident     # □ RIGHT: broadcast to both lanes
      fan_out: 2
      output_ports: [to_network, to_app]
      item_copy: true

    - id: soc_network
      label: "SOC: Network Lane"
      type: processor
      ports:
        trigger_in:
          - id: start             # ▲ LEFT
        data_in:
          - type: p1_incident     # □ LEFT
        event_out:
          - id: finding_done      # ▼ RIGHT -> investigation_join.network_done
          - id: rollback_needed   # ▼ RIGHT -> saga coordinator
        value_cost:
          amount: 150.0
        data_out:
          - type: network_finding # □ RIGHT
      container:
        aging:
          field: age_ms
          escalation_rules:
            - after_ms: 900000
              set_priority: urgent
              emit_event: sla_breach
      script:
        fires_on: any
        requires_resource:
          pool: soc_analysts
          slots: 2
          on_unavailable: queue
        steps:
          - id: packet_capture
            duration_ms: 300000
          - id: analyse_logs
            duration_ms: 600000
            output: network_finding

    - id: soc_app
      label: "SOC: Application Lane"
      type: processor
      ports:
        trigger_in:
          - id: start             # ▲ LEFT
        data_in:
          - type: p1_incident     # □ LEFT
        event_out:
          - id: finding_done      # ▼ RIGHT -> investigation_join.app_done
          - id: rollback_needed   # ▼ RIGHT
        value_cost:
          amount: 150.0
        data_out:
          - type: app_finding     # □ RIGHT
      script:
        fires_on: any
        requires_resource:
          pool: soc_analysts
          slots: 2
          on_unavailable: queue
        steps:
          - id: trace_errors
            duration_ms: 240000
          - id: correlate_deploys
            duration_ms: 480000
            output: app_finding

    - id: investigation_join
      label: "Join: Merge Findings"
      type: join
      ports:
        trigger_in:
          - id: network_done      # ▲ LEFT: from soc_network.finding_done
          - id: app_done          # ▲ LEFT: from soc_app.finding_done
        data_in:
          - type: network_finding # □ LEFT
          - type: app_finding     # □ LEFT
        event_out:
          - id: all_complete      # ▼ RIGHT -> incident_close
        data_out:
          - type: combined_finding # □ RIGHT
      expects_ports: [network_done, app_done]
      join_mode: all_required
      key_field: incident_id
      timeout_ms: 3600000
      on_timeout: emit_event

  edges:
    - from: alert_classifier    to: investigation_split  type: data  item_type: p1_incident
    - from: investigation_split to: soc_network  type: data  item_type: p1_incident  port: to_network
    - from: investigation_split to: soc_app      type: data  item_type: p1_incident  port: to_app
    - from: soc_network  to: investigation_join  type: data  item_type: network_finding
    - from: soc_app      to: investigation_join  type: data  item_type: app_finding
    - from: alert_classifier.event_out.p1_routed  to: investigation_split.trigger_in.on_p1 type: signal
    - from: soc_network.event_out.finding_done    to: investigation_join.trigger_in.network_done  type: signal
    - from: soc_app.event_out.finding_done        to: investigation_join.trigger_in.app_done      type: signal
    - from: soc_network.event_out.rollback_needed to: rollback_coordinator.trigger_in.start       type: signal
    - from: soc_app.event_out.rollback_needed     to: rollback_coordinator.trigger_in.start       type: signal
```

---

### 4.4 Financial Trade Settlement with Saga Compensation

**Scenario**: A trade flows through compliance, risk scoring, and settlement. Settlement is
time-windowed to market hours. If risk or settlement fails, a saga coordinator fires compensating
actions: releases the risk reserve and refunds compliance fees. Market volatility is a simulation
context variable — change it to model flash crash, normal day, or end-of-month scenarios.
Each block stamps its cost on the item so full per-trade cost is observable at the settlement sink.

```
in:trade_order --> [compliance] --> [risk_engine] --> [settlement (T+2)] --> out:settled_trade
                                          |                  |
                                    event:rejected      event:failed
                                          +-------+----------+
                                                  v
                                    [saga_coordinator] compensates upstream
```

```yaml
graph:
  id: financial_settlement_saga
  label: "Trade Settlement with Saga Compensation"
  simulation:
    context:
      - name: market_volatility
        default: 0.02
    scenarios:
      - id: flash_crash
        overrides:
          market_volatility: 0.35
      - id: normal_day
        overrides:
          market_volatility: 0.01

  blocks:

    - id: compliance_check
      label: "Pre-Trade Compliance"
      type: processor
      ports:
        trigger_in:
          - id: new_trade         # ▲ LEFT
        data_in:
          - type: trade_order     # □ LEFT
        event_out:
          - id: cleared           # ▼ RIGHT -> risk_engine.on_cleared
          - id: blocked           # ▼ RIGHT: hard compliance block
        value_cost:
          amount: 0.50            # ⊖ RIGHT
        data_out:
          - type: cleared_trade   # □ RIGHT
      script:
        fires_on: any
        saga_id: trade_saga
        steps:
          - id: sanctions_check
            duration_ms: 50
            fail_chance: 0.005
            on_fail: emit_event
          - id: position_check
            duration_ms: 80
            fail_chance: 0.02
            on_fail: emit_event
        cost_stamp:
          label: compliance_cost
          amount_formula: "0.50"
          accumulate_on: item
        audit_stamp:
          enabled: true
          fields: [block_id, timestamp, trade_id, outcome]

    - id: risk_engine
      label: "Risk Engine"
      type: processor
      ports:
        trigger_in:
          - id: on_cleared        # ▲ LEFT: from compliance.cleared
        filter_in:
          - id: volatility_feed   # ◇ LEFT: live volatility adjusts thresholds
        data_in:
          - type: cleared_trade   # □ LEFT
        event_out:
          - id: risk_accepted     # ▼ RIGHT -> settlement.on_risk_ok
          - id: risk_rejected     # ▼ RIGHT -> saga_coordinator
        value_cost:
          amount: 0.25            # ⊖ RIGHT
        data_out:
          - type: risk_approved_trade # □ RIGHT
      circuit_breaker:
        mode: rate
        fail_threshold: 0.15
        half_open_after_ms: 30000
        on_open: emit_event
      script:
        fires_on: all
        saga_id: trade_saga
        compensation:
          trigger_signal: saga_rollback
          steps:
            - id: release_reserve
              target_block: risk_reserve_pool
              action: release
        outcome_distribution:
          - outcome: accepted
            probability: 0.94
            output_type: risk_approved_trade
          - outcome: rejected
            probability: 0.06
            emit_event: risk_rejected
        cost_stamp:
          label: risk_cost
          amount_formula: "0.25"
          accumulate_on: item

    - id: settlement
      label: "Settlement (T+2)"
      type: processor
      ports:
        trigger_in:
          - id: on_risk_ok        # ▲ LEFT: from risk_engine.risk_accepted
        data_in:
          - type: risk_approved_trade # □ LEFT
        event_out:
          - id: settled           # ▼ RIGHT
          - id: failed            # ▼ RIGHT -> saga_coordinator
        value_cost:
          amount: 1.20            # ⊖ RIGHT
        value_out:
          - id: commission        # ○ RIGHT: brokerage commission earned
        data_out:
          - type: settled_trade   # □ RIGHT
      time_window:
        timezone: Europe/London
        windows:
          - days: [Mon, Tue, Wed, Thu, Fri]
            start: "08:00"
            end: "17:30"
        outside_window: queue
      script:
        fires_on: all
        saga_id: trade_saga
        compensation:
          trigger_signal: saga_rollback
          steps:
            - id: reverse_settlement
              target_block: settlement_registry
              action: rollback
            - id: refund_fee
              target_block: fee_ledger
              action: refund
        steps:
          - id: net_positions
            duration_ms: 100
            fail_chance: 0.01
          - id: update_custody
            duration_ms: 200
            output: settled_trade
            fail_chance: 0.005

  edges:
    - from: compliance_check  to: risk_engine    type: data  item_type: cleared_trade
    - from: risk_engine       to: settlement     type: data  item_type: risk_approved_trade
    - from: compliance_check.event_out.cleared   to: risk_engine.trigger_in.on_cleared    type: signal
    - from: risk_engine.event_out.risk_accepted  to: settlement.trigger_in.on_risk_ok     type: signal
    - from: risk_engine.event_out.risk_rejected  to: saga_coordinator.trigger_in.rollback type: signal
    - from: settlement.event_out.failed          to: saga_coordinator.trigger_in.rollback type: signal
    - from: compliance_check.value_cost    to: trade_ledger    type: value
    - from: risk_engine.value_cost         to: trade_ledger    type: value
    - from: settlement.value_cost          to: trade_ledger    type: value
    - from: settlement.value_out.commission to: revenue_ledger type: value
```

---

### 4.5 Content Moderation with Human-in-the-Loop

**Scenario**: User submissions are classified by an AI: safe content auto-approves, clear violations
auto-reject, borderline items go to a human moderator queue with a 4-hour SLA. After SLA breach the
item escalates to a senior reviewer. Items that expire (no review in 24h) go to a DLQ for audit and
replay. The AI taps 10% of all decisions to an analytics bus (non-consuming).

```
in:submission --> [ai_classifier] --> safe_content   --> [auto_approve]
                                  --> borderline      --> [human_review] --(breach)--> [senior_review]
                                  --> violation       --> [auto_reject]
```

```yaml
graph:
  id: content_moderation
  label: "Content Moderation with Human-in-the-Loop"

  resources:
    - id: moderator_pool
      type: worker_pool
      capacity: 15

  blocks:

    - id: ai_classifier
      label: "AI Content Classifier"
      type: processor
      ports:
        trigger_in:
          - id: new_submission    # ▲ LEFT
        filter_in:
          - id: policy_update     # ◇ LEFT: inject updated policy at runtime
        data_in:
          - type: submission      # □ LEFT
        event_out:
          - id: safe_routed       # ▼ RIGHT -> auto_approve
          - id: review_routed     # ▼ RIGHT -> human_review
          - id: violation_routed  # ▼ RIGHT -> auto_reject
        value_cost:
          amount: 0.003           # ⊖ RIGHT: AI inference cost
        data_out:
          - type: safe_content      # □ RIGHT
          - type: borderline_content # □ RIGHT
          - type: violation_content  # □ RIGHT
      rate_limiter:
        type: token_bucket
        tokens_per_second: 2000
        burst_capacity: 10000
        on_throttle: queue
      script:
        fires_on: any
        outcome_distribution:
          - outcome: safe
            probability: 0.82
            output_type: safe_content
          - outcome: borderline
            probability: 0.14
            output_type: borderline_content
          - outcome: violation
            probability: 0.04
            output_type: violation_content

    - id: tap_ai_decisions
      label: "AI Decision Analytics Tap (10%)"
      type: tap
      tap:
        source_edge:
          from: ai_classifier
          to: auto_approve
        copy_to: analytics_bus
        sample_rate: 0.10
        transform:
          - field: user_id
            action: mask

    - id: human_review
      label: "Human Moderation Queue"
      type: processor
      ports:
        trigger_in:
          - id: on_borderline     # ▲ LEFT: from ai_classifier.review_routed
        filter_in:
          - id: escalation_rule   # ◇ LEFT: types needing senior review
        data_in:
          - type: borderline_content # □ LEFT
        event_out:
          - id: approved          # ▼ RIGHT
          - id: rejected          # ▼ RIGHT
          - id: escalated         # ▼ RIGHT -> senior_review.on_escalated
          - id: sla_breach        # ▼ RIGHT -> senior_review.on_sla_breach
        value_cost:
          amount: 4.50            # ⊖ RIGHT: moderator time per review
        data_out:
          - type: approved_content  # □ RIGHT
          - type: rejected_content  # □ RIGHT
      container:
        capacity: 5000
        strategy: priority
        priority_field: risk_score
        overflow: block
        aging:
          field: age_ms
          escalation_rules:
            - after_ms: 10800000
              set_priority: urgent
            - after_ms: 14400000
              set_priority: urgent
              emit_event: sla_breach
          expiry_ms: 86400000
          on_expire: dead_letter
      script:
        fires_on: any
        requires_resource:
          pool: moderator_pool
          slots: 1
          on_unavailable: queue
        human_approval:
          required: true
          notify: [role_moderator]
          timeout_ms: 14400000
          on_timeout: escalate
          escalate_to: role_senior_moderator
          ui_action: moderation_form

    - id: senior_review
      label: "Senior Moderator Review"
      type: processor
      ports:
        trigger_in:
          - id: on_escalated      # ▲ LEFT: from human_review.escalated
          - id: on_sla_breach     # ▲ LEFT: from human_review.sla_breach
        data_in:
          - type: borderline_content # □ LEFT
        event_out:
          - id: decision_made     # ▼ RIGHT
        value_cost:
          amount: 15.0            # ⊖ RIGHT
        data_out:
          - type: final_decision  # □ RIGHT
      script:
        fires_on: any
        requires_resource:
          pool: moderator_pool
          slots: 1
          on_unavailable: queue
        human_approval:
          required: true
          notify: [role_senior_moderator, role_trust_safety_lead]
          timeout_ms: 7200000
          on_timeout: auto_reject
          ui_action: senior_review_form
        audit_stamp:
          enabled: true
          fields: [block_id, timestamp, content_id, decision, reviewer_id]

    - id: content_dlq
      label: "Expired Content DLQ"
      type: dead_letter
      ports:
        trigger_in:
          - id: on_expire         # ▲ LEFT: receives expired items
        event_out:
          - id: dlq_item_logged   # ▼ RIGHT
      dead_letter:
        accepts_from: [human_review]
        replay:
          enabled: true
          target_block: human_review
          operator_required: true

  edges:
    - from: ai_classifier    to: auto_approve  type: data  item_type: safe_content
    - from: ai_classifier    to: human_review  type: data  item_type: borderline_content
    - from: ai_classifier    to: auto_reject   type: data  item_type: violation_content
    - from: human_review     to: senior_review type: data  item_type: borderline_content
    - from: ai_classifier.event_out.safe_routed      to: auto_approve.trigger_in.start           type: signal
    - from: ai_classifier.event_out.review_routed    to: human_review.trigger_in.on_borderline   type: signal
    - from: ai_classifier.event_out.violation_routed to: auto_reject.trigger_in.start            type: signal
    - from: human_review.event_out.escalated         to: senior_review.trigger_in.on_escalated   type: signal
    - from: human_review.event_out.sla_breach        to: senior_review.trigger_in.on_sla_breach  type: signal
    - from: ai_classifier.value_cost  to: cost_ledger  type: value
    - from: human_review.value_cost   to: cost_ledger  type: value
    - from: senior_review.value_cost  to: cost_ledger  type: value
```

---

## 5. Layered Composite Examples

These examples show how atomic blocks are assembled into composites, and how composites
nest into larger composites. Every example uses the left/right port model and shows value
flowing upward through VALUE_IN (⊕) at each layer.

See [BLOCK-DESIGN.md](BLOCK-DESIGN.md) §1.2–§1.4 for the composability model and
[MECHANICS-GUIDE.md](MECHANICS-GUIDE.md) for value aggregation details.

---

### 5.1 Two-Layer: Software Feature Sprint

**Layers**:
- **L0 (atomics)**: `estimator`, `coder`, `code_reviewer`, `test_runner`, `deployer`
- **L1 (outer composite)**: `dev_sprint` wraps all atomics into one reusable sprint block

**Behaviour**: A feature request enters the sprint, flows through 5 sequential atomic blocks,
and exits as a deployed feature. The outer composite reports total sprint cost and velocity
to the parent graph (e.g. a project scheduler).

#### L0: Atomic blocks

```yaml
data_types:
  - type: feature_request
  - type: estimate
  - type: coded_feature
  - type: reviewed_feature
  - type: tested_feature
  - type: deployed_feature

resources:
  - id: engineers
    type: worker_pool
    capacity: 4
  - id: ci_runners
    type: worker_pool
    capacity: 2

# ── Atomic L0: Estimator ─────────────────────────────────────────────────────
- id: estimator
  label: "Story Estimator"
  type: processor
  ports:
    trigger_in:
      - id: start                  # ▲ LEFT: fired by sprint_start event
    data_in:
      - type: feature_request      # □ LEFT
    event_out:
      - id: estimated              # ▼ RIGHT -> coder.start
    value_cost:
      amount: 20.0                 # ⊖ RIGHT: planning cost
    data_out:
      - type: estimate             # □ RIGHT
  script:
    fires_on: any
    requires_resource:
      pool: engineers
      slots: 1
      on_unavailable: queue
    steps:
      - id: breakdown
        duration_ms: 3600000       # 1h estimate session
        output: estimate

# ── Atomic L0: Coder ─────────────────────────────────────────────────────────
- id: coder
  label: "Developer"
  type: processor
  ports:
    trigger_in:
      - id: start                  # ▲ LEFT: from estimator.estimated
    filter_in:
      - id: sprint_config          # ◇ LEFT: velocity target, tech stack flags
    data_in:
      - type: estimate             # □ LEFT
    event_out:
      - id: coded                  # ▼ RIGHT -> code_reviewer.start
      - id: blocked                # ▼ RIGHT: dependency missing
    value_cost:
      amount: 0.0                 # ⊖ RIGHT: computed per step (see cost_stamp)
    value_out:
      - id: story_points           # ○ RIGHT: output velocity
    data_out:
      - type: coded_feature        # □ RIGHT
  script:
    fires_on: all
    requires_resource:
      pool: engineers
      slots: 1
      on_unavailable: queue
    steps:
      - id: implement
        duration_ms: 14400000      # 4h typical coding
        fail_chance: 0.05
        on_fail: emit_event
        output: coded_feature
    cost_stamp:
      label: dev_time
      amount_formula: "duration_ms / 3600000 * 80.0"   # €80/h
      accumulate_on: item
    concurrency:
      mode: fixed
      value: 2                     # 2 features in parallel

# ── Atomic L0: Code Reviewer ─────────────────────────────────────────────────
- id: code_reviewer
  label: "Code Review"
  type: processor
  ports:
    trigger_in:
      - id: start                  # ▲ LEFT
    data_in:
      - type: coded_feature        # □ LEFT
    event_out:
      - id: approved               # ▼ RIGHT -> test_runner.start
      - id: rejected               # ▼ RIGHT -> coder.start (loop back)
    value_cost:
      amount: 40.0                 # ⊖ RIGHT: review cost per feature
    data_out:
      - type: reviewed_feature     # □ RIGHT
  script:
    fires_on: any
    requires_resource:
      pool: engineers
      slots: 1
      on_unavailable: queue
    steps:
      - id: review
        duration_ms: 7200000       # 2h review
        output: reviewed_feature
    outcome_distribution:
      - outcome: approved
        probability: 0.75
        output_type: reviewed_feature
      - outcome: rejected
        probability: 0.25
        emit_event: rejected

# ── Atomic L0: Test Runner ────────────────────────────────────────────────────
- id: test_runner
  label: "Automated Tests"
  type: processor
  ports:
    trigger_in:
      - id: start                  # ▲ LEFT
    data_in:
      - type: reviewed_feature     # □ LEFT
    event_out:
      - id: passed                 # ▼ RIGHT -> deployer.start
      - id: failed                 # ▼ RIGHT -> coder.start (fix loop)
    value_cost:
      amount: 15.0                 # ⊖ RIGHT: CI machine cost
    data_out:
      - type: tested_feature       # □ RIGHT
  script:
    fires_on: any
    requires_resource:
      pool: ci_runners
      slots: 1
      on_unavailable: queue
    steps:
      - id: unit_tests
        duration_ms: 600000
        fail_chance: 0.12
        on_fail: emit_event
      - id: integration_tests
        duration_ms: 1200000
        fail_chance: 0.08
        on_fail: emit_event
        output: tested_feature

# ── Atomic L0: Deployer ───────────────────────────────────────────────────────
- id: deployer
  label: "Deployment"
  type: processor
  ports:
    trigger_in:
      - id: start                  # ▲ LEFT
    data_in:
      - type: tested_feature       # □ LEFT
    event_out:
      - id: deployed               # ▼ RIGHT -> sprint done
      - id: rollback               # ▼ RIGHT -> alerting
    value_cost:
      amount: 10.0                 # ⊖ RIGHT: infra cost
    value_out:
      - id: business_value         # ○ RIGHT: value delivered
    data_out:
      - type: deployed_feature     # □ RIGHT
  script:
    fires_on: any
    requires_resource:
      pool: ci_runners
      slots: 1
      on_unavailable: queue
    steps:
      - id: build_artifact
        duration_ms: 900000
      - id: deploy_prod
        duration_ms: 300000
        fail_chance: 0.02
        on_fail: emit_event
        output: deployed_feature
```

#### L1: The `dev_sprint` composite (wraps all L0 atomics)

```yaml
# ── Layer-1 Composite: dev_sprint ─────────────────────────────────────────────
- id: dev_sprint
  label: "Development Sprint"
  type: composite
  # Ports the PARENT sees — completely hides inner complexity:
  ports:
    trigger_in:
      - id: sprint_start           # ▲ LEFT (wires to inner estimator.start)
    filter_in:
      - id: sprint_config          # ◇ LEFT (wires to inner coder.sprint_config)
    data_in:
      - type: feature_request      # □ LEFT (wires to inner estimator container)
    event_out:
      - id: sprint_done            # ▼ RIGHT (from inner deployer.deployed)
      - id: sprint_blocked         # ▼ RIGHT (from inner coder.blocked)
    value_in:
      - id: all                    # ⊕ LEFT: collects all inner ⊖/○ flows
    value_cost:
      aggregate: true              # ⊖ RIGHT: sum of estimator+coder+reviewer+runner+deployer costs
    value_out:
      - id: velocity               # ○ RIGHT: sum of coder.story_points + deployer.business_value
        aggregate: true
    data_out:
      - type: deployed_feature     # □ RIGHT (from inner deployer output)

  children:
    boundary_nodes:
      - { id: _in_feature,    type: boundary_in,  port_kind: data,   data_type: feature_request }
      - { id: _in_trigger,    type: boundary_in,  port_kind: signal                              }
      - { id: _in_filter,     type: boundary_in,  port_kind: filter                              }
      - { id: _out_deployed,  type: boundary_out, port_kind: data,   data_type: deployed_feature }
      - { id: _out_events,    type: boundary_out, port_kind: signal                              }

    nodes: [estimator, coder, code_reviewer, test_runner, deployer]

    edges:
      # data flow (left → right through all 5 atomics)
      - { from: _in_feature,     to: estimator,      type: data, item_type: feature_request  }
      - { from: estimator,       to: coder,          type: data, item_type: estimate         }
      - { from: coder,           to: code_reviewer,  type: data, item_type: coded_feature   }
      - { from: code_reviewer,   to: test_runner,    type: data, item_type: reviewed_feature }
      - { from: test_runner,     to: deployer,       type: data, item_type: tested_feature   }
      - { from: deployer,        to: _out_deployed,  type: data, item_type: deployed_feature }
      # signal wiring
      - { from: _in_trigger,              to: estimator.trigger_in.start,          type: signal }
      - { from: estimator.event_out.estimated,   to: coder.trigger_in.start,       type: signal }
      - { from: code_reviewer.event_out.rejected, to: coder.trigger_in.start,      type: signal }
      - { from: code_reviewer.event_out.approved, to: test_runner.trigger_in.start, type: signal }
      - { from: test_runner.event_out.failed,    to: coder.trigger_in.start,       type: signal }
      - { from: test_runner.event_out.passed,    to: deployer.trigger_in.start,    type: signal }
      - { from: deployer.event_out.deployed,     to: _out_events,                  type: signal }
      # value wiring: ALL inner ⊖/○ -> composite value_in
      - { from: estimator.value_cost,    to: dev_sprint.value_in.all, type: value }
      - { from: coder.value_cost,        to: dev_sprint.value_in.all, type: value }
      - { from: coder.value_out.story_points,  to: dev_sprint.value_in.all, type: value }
      - { from: code_reviewer.value_cost, to: dev_sprint.value_in.all, type: value }
      - { from: test_runner.value_cost,  to: dev_sprint.value_in.all, type: value }
      - { from: deployer.value_cost,     to: dev_sprint.value_in.all, type: value }
      - { from: deployer.value_out.business_value, to: dev_sprint.value_in.all, type: value }
```

---

### 5.2 Three-Layer: Software Development Department

**Layers**:
- **L0 (atomics)**: individual programmers, QA engineers, automated test runners
- **L1 (composites)**: `dev_team`, `qa_team`, `ops_team` (each wrapping their L0 blocks)
- **L2 (outer composite)**: `software_dept` wrapping all three L1 composites

**Behaviour**: Feature requests enter the department. They pass through dev, QA, and ops.
Each team is a self-contained composite. The department reports aggregate cost and velocity
to the C-suite dashboard without exposing any internal team details.

```yaml
graph:
  id: software_department_3layer
  label: "Software Department (3-Layer Composite)"

  data_types:
    - type: feature_request
    - type: coded_feature
    - type: qa_approved_feature
    - type: released_feature

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 0: Atomic blocks (defined above in 21.1 or abbreviated here)
  # ═══════════════════════════════════════════════════════════════════════════

  # (L0 atomics: coder, code_reviewer, test_runner, deployer defined as above)
  # Below we show abbreviated declarations for the QA and Ops atoms:

  # ── L0: QA Engineer ──────────────────────────────────────────────────────
  - id: qa_engineer
    label: "QA Engineer"
    type: processor
    ports:
      trigger_in:
        - id: start               # ▲ LEFT
      data_in:
        - type: coded_feature     # □ LEFT
      event_out:
        - id: approved            # ▼ RIGHT
        - id: bug_found           # ▼ RIGHT -> back to dev
      value_cost: { amount: 60.0 }   # ⊖ RIGHT
      data_out:
        - type: qa_approved_feature  # □ RIGHT
    script:
      fires_on: any
      steps:
        - id: functional_test    # duration_ms: 5400000  (90m)
          output: qa_approved_feature
          fail_chance: 0.18
          on_fail: emit_event

  # ── L0: Release Manager ──────────────────────────────────────────────────
  - id: release_manager
    label: "Release Manager"
    type: processor
    ports:
      trigger_in:
        - id: start              # ▲ LEFT
      filter_in:
        - id: release_window     # ◇ LEFT: allowed release schedule (time_window rule)
      data_in:
        - type: qa_approved_feature   # □ LEFT
      event_out:
        - id: released           # ▼ RIGHT
        - id: postponed          # ▼ RIGHT: outside release window
      value_cost: { amount: 30.0 }   # ⊖ RIGHT
      value_out:
        - id: delivery_value     # ○ RIGHT
      data_out:
        - type: released_feature # □ RIGHT
    script:
      fires_on: all
    time_window:
      timezone: Europe/Berlin
      windows:
        - days: [Mon, Wed, Thu]
          start: "10:00"
          end: "15:00"
      outside_window: queue

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 1: Composites wrapping L0 atomics
  # ═══════════════════════════════════════════════════════════════════════════

  # ── L1: dev_team composite ────────────────────────────────────────────────
  - id: dev_team
    label: "Development Team"
    type: composite
    ports:
      trigger_in:
        - id: start              # ▲ LEFT (wires to coder.start)
      filter_in:
        - id: sprint_config      # ◇ LEFT
      data_in:
        - type: feature_request  # □ LEFT
      event_out:
        - id: coded              # ▼ RIGHT -> qa_team.start
        - id: blocked            # ▼ RIGHT -> dept.event alert
      value_in:                  # ─ KEY: receives all inner block cost/revenue ─
        - id: all                # ⊕ LEFT
      value_cost:
        aggregate: true          # ⊖ RIGHT: summed dev team cost -> dept.value_in
      value_out:
        - id: story_points
          aggregate: true        # ○ RIGHT: summed dev output -> dept.value_in
      data_out:
        - type: coded_feature    # □ RIGHT -> qa_team entry
    children:
      nodes: [coder, code_reviewer, test_runner]   # L0 atoms
      edges:
        - { from: feature_request, to: coder,         type: data }
        - { from: coder,           to: code_reviewer, type: data }
        - { from: code_reviewer,   to: test_runner,   type: data }
        - { from: test_runner,     to: coded_feature_out, type: data }
        # value wiring to dev_team.value_in.all:
        - { from: coder.value_cost,         to: dev_team.value_in.all, type: value }
        - { from: coder.value_out.story_points, to: dev_team.value_in.all, type: value }
        - { from: code_reviewer.value_cost, to: dev_team.value_in.all, type: value }
        - { from: test_runner.value_cost,   to: dev_team.value_in.all, type: value }

  # ── L1: qa_team composite ─────────────────────────────────────────────────
  - id: qa_team
    label: "QA Team"
    type: composite
    ports:
      trigger_in:
        - id: start              # ▲ LEFT (from dev_team.coded)
      data_in:
        - type: coded_feature    # □ LEFT
      event_out:
        - id: qa_done            # ▼ RIGHT -> ops_team.start
        - id: bug_found          # ▼ RIGHT -> dev_team.start (rework loop)
      value_in:
        - id: all                # ⊕ LEFT
      value_cost:
        aggregate: true          # ⊖ RIGHT -> dept.value_in
      data_out:
        - type: qa_approved_feature  # □ RIGHT -> ops_team entry
    children:
      nodes: [qa_engineer]       # can have multiple QA engineers
      edges:
        - { from: coded_feature,    to: qa_engineer,         type: data }
        - { from: qa_engineer,      to: qa_approved_out,     type: data }
        - { from: qa_engineer.value_cost, to: qa_team.value_in.all, type: value }

  # ── L1: ops_team composite ────────────────────────────────────────────────
  - id: ops_team
    label: "Ops / Release Team"
    type: composite
    ports:
      trigger_in:
        - id: start              # ▲ LEFT (from qa_team.qa_done)
      filter_in:
        - id: release_schedule   # ◇ LEFT: inject release windows
      data_in:
        - type: qa_approved_feature  # □ LEFT
      event_out:
        - id: released           # ▼ RIGHT -> dept.done
        - id: postponed          # ▼ RIGHT
      value_in:
        - id: all                # ⊕ LEFT
      value_cost:
        aggregate: true          # ⊖ RIGHT -> dept.value_in
      value_out:
        - id: delivery_value
          aggregate: true        # ○ RIGHT -> dept.value_in
      data_out:
        - type: released_feature # □ RIGHT
    children:
      nodes: [release_manager]
      edges:
        - { from: qa_approved_feature, to: release_manager,   type: data }
        - { from: release_manager,     to: released_feature_out, type: data }
        - { from: release_manager.value_cost,      to: ops_team.value_in.all, type: value }
        - { from: release_manager.value_out.delivery_value, to: ops_team.value_in.all, type: value }

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: software_dept wraps all three L1 composites
  # ═══════════════════════════════════════════════════════════════════════════

  - id: software_dept
    label: "Software Department"
    type: composite
    # What the executive dashboard / parent graph sees:
    ports:
      trigger_in:
        - id: sprint_start       # ▲ LEFT: project manager fires this
      filter_in:
        - id: dept_config        # ◇ LEFT: velocity targets, release schedule
      data_in:
        - type: feature_request  # □ LEFT: intake from product backlog
      event_out:
        - id: feature_released   # ▼ RIGHT: one feature shipped
        - id: bottleneck_alert   # ▼ RIGHT: SLA breach in any team
      value_in:
        - id: all                # ⊕ LEFT: receives dev_team + qa_team + ops_team value flows
      value_cost:
        aggregate: true          # ⊖ RIGHT: total dept salary/infra per feature
      value_out:
        - id: business_throughput
          aggregate: true        # ○ RIGHT: total business value delivered
      data_out:
        - type: released_feature # □ RIGHT: to deployment registry / product analytics

    children:
      nodes: [dev_team, qa_team, ops_team]    # the three L1 composites

      edges:
        # Data flow: L → R through three L1 composites
        - { from: feature_request_in, to: dev_team,  type: data, item_type: feature_request   }
        - { from: dev_team,           to: qa_team,   type: data, item_type: coded_feature      }
        - { from: qa_team,            to: ops_team,  type: data, item_type: qa_approved_feature }
        - { from: ops_team,           to: released_feature_out, type: data,
            item_type: released_feature }

        # Signal wiring
        - { from: sprint_start_in,             to: dev_team.trigger_in.start,   type: signal }
        - { from: dev_team.event_out.coded,    to: qa_team.trigger_in.start,    type: signal }
        - { from: qa_team.event_out.bug_found, to: dev_team.trigger_in.start,   type: signal }
        - { from: qa_team.event_out.qa_done,   to: ops_team.trigger_in.start,   type: signal }
        - { from: ops_team.event_out.released, to: feature_released_out,        type: signal }

        # Value wiring: L1 composite outputs -> software_dept.value_in.all
        - { from: dev_team.value_cost,              to: software_dept.value_in.all, type: value }
        - { from: dev_team.value_out.story_points,  to: software_dept.value_in.all, type: value }
        - { from: qa_team.value_cost,               to: software_dept.value_in.all, type: value }
        - { from: ops_team.value_cost,              to: software_dept.value_in.all, type: value }
        - { from: ops_team.value_out.delivery_value, to: software_dept.value_in.all, type: value }

# Parent graph only sees software_dept as one block.
# Drill once: dev_team, qa_team, ops_team with their live queues.
# Drill twice into dev_team: coder, code_reviewer, test_runner atomics with their queues.
# Each layer's total cost and revenue is visible as ⊖/○ on that composite's RIGHT side.
```

**What the 3-layer composite looks like from the outside (parent graph view):**

```
  software_dept (Layer-2 composite):
  ────────────────────────────────────────────────────────────────────────
  ▲ trigger_in.sprint_start          ▼ event_out.feature_released
  ◇ filter_in.dept_config     [ L1: dev + qa + ops   ▼ event_out.bottleneck_alert
  □ in: feature_request        subgraphs hidden ]     ⊖ value_cost  (total dept spend)
  ⊕ value_in.all                                      ○ value_out.business_throughput
                                                           □ out: released_feature
```

**Drill once** into `software_dept` — see `dev_team`, `qa_team`, `ops_team` as blocks with
their own live queue depths and value outputs.

**Drill twice** into `dev_team` — see the individual atomic blocks (`coder`, `code_reviewer`,
`test_runner`) with per-block queue visibility and cost stamps on items.

Cost visibility at every level:
- `coder.⊖` = €80/h per individual coder run
- `dev_team.⊖` = sum of all atomics = total dev team spend per feature
- `software_dept.⊖` = sum of all three teams = total dept spend per feature

---

*Extracted from [BLOCK-DESIGN.md](BLOCK-DESIGN.md) v4.0 — §16, §18, §19, §20, §21*
*Mechanics: [MECHANICS-GUIDE.md](MECHANICS-GUIDE.md) | Core Design: [BLOCK-DESIGN.md](BLOCK-DESIGN.md)*

# CAG Required-Section Coverage

## system_prompt  (n=1)

| Field | Coverage |
|-------|---------:|
| `Engine Identity` |   0.0% |
| `Binding Constraints` |   0.0% |
| `Cross-Artifact Sync` | 100.0% |
| `Discovery` |   0.0% |
| `Quality Gates` |   0.0% |
| `Repository Layout` | 100.0% |

## agent  (n=20)

| Field | Coverage |
|-------|---------:|
| `fm:name` | 100.0% |
| `fm:mission` |   0.0% |
| `fm:personas` |   0.0% |
| `fm:primary_skills` |   0.0% |
| `fm:secondary_skills` |   0.0% |
| `fm:routes_to` |   0.0% |
| `fm:loads_tools` |   0.0% |
| `sec:Mission` | 100.0% |
| `sec:Scope` | 100.0% |
| `sec:Inputs` |   0.0% |
| `sec:Outputs` |   0.0% |
| `sec:Workflow` | 100.0% |
| `sec:Routing Table` |   0.0% |
| `sec:Anti-patterns` | 100.0% |

## skill  (n=32)

| Field | Coverage |
|-------|---------:|
| `fm:name` | 100.0% |
| `fm:description` | 100.0% |
| `fm:companion_files` |   0.0% |
| `fm:related_skills` |   0.0% |
| `sec:Mission` |   3.1% |
| `sec:When To Load` |   0.0% |
| `sec:When To Skip` |   0.0% |
| `sec:Domain Knowledge` |   0.0% |
| `sec:Companion File Index` |   0.0% |
| `sec:References` |   3.1% |

## prompt  (n=45)

| Field | Coverage |
|-------|---------:|
| `fm:description` | 100.0% |
| `fm:mode` |   0.0% |
| `fm:loads_skills` |   0.0% |
| `fm:loads_tools` |   0.0% |
| `fm:expected_agent` |   0.0% |
| `fm:inputs_required` |   0.0% |
| `sec:Goal` |   2.2% |
| `sec:Inputs` |  64.4% |
| `sec:Steps` |  84.4% |
| `sec:Success Criteria` |   0.0% |
| `sec:Anti-patterns` |   2.2% |
| `sec:Example Invocation` |   0.0% |

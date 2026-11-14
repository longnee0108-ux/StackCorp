# 05 — RECIPES (root card in **bold**; thời gian ở 1x)

| id | Root + Stack | Worker | Time | Outputs | Stress | Idea |
|---|---|---|---|---|---|---|
| r_concept | **Whiteboard** + Founder + Marker | Founder | 30s | Concept | 1 | starter |
| r_idea | **Whiteboard** + Founder (không Marker) | Founder | 45s | random undiscovered Idea (P-theo) | 1 | starter |
| r_proto | **Laptop** + Dev + Concept | Dev | 40s | Prototype | 1 | starter |
| r_polish | **Prototype** + Designer | Designer | 30s | Polished Prototype | 1 | Idea: Polish |
| r_deal | **Polished Prototype** + Sales + Freelance Contract | Sales | 30s | Signed Deal (+$ lead) | 1 | Idea: Close Deal |
| r_gig | **Laptop** + Founder + Freelance Contract | Founder | 30s | $8 | 1 | starter |
| r_coffee | **Coffee Machine** + Coffee Beans | — | 25s | Coffee | 0 | Idea: Brew |
| r_pantry | **Pantry** + Person | Person | 15s | Person stress −3 | 0 | Idea: Pantry |
| r_bug | **Bug** + Dev | Dev | 5s/tick | Bug hp −1 | 0 | starter |
| r_fixbug | **Buggy Product** + Dev | Dev | 20s | Product | 0 | starter |
| r_pitch | **Whiteboard** + Designer + Polished Prototype + 2 Concept | Designer | 50s | Pitch Deck | 1 | Idea: Pitch Deck |
| r_seriesA | **Founder** + Pitch Deck + Investor + Polished Prototype | Founder | 60s | 5×$100 + Term Sheet | 0 | Idea: Series A |
| r_overclock | **Founder** + 3 Coffee | Founder | 5s | Overclock 1 Day → Hospitalized | — | Idea: Overclock |
| r_idea2 | **Pantry** + 2 Person | 2 Person | 30s | 70% Idea / 30% Office Drama | 0 | Idea: Brainstorm |
| r_sub | **Server** (P2: Laptop) + Senior Dev + Designer + Concept | SrDev | 50s | Subscription | 1 | Idea: SaaS |
| r_ent | **Subscription** + Sales + Lawyer | Sales | 40s | Enterprise License | 1 | Idea: Enterprise |
| r_ledger | **Accountant** + 10 Receipt | Accountant | 20s | Ledger Folder | 0 | Idea: Ledger |
| r_shred | **Shredder** + Receipt | — | 5s | Black Fund (+untaxed) | 0 | Idea: Shredder |
| r_hire | **Founder** + Candidate (pack Intern/Dev/...) + $20 | Founder | 15s | Person | 0 | starter |
| r_ai | **Cloud Server** + 3 Person (cấp thấp, bị consume) + $200 | — | 60s | AI Agent | 0 | Idea: Automation |
| r_ipo | **Founder** + Lawyer + Accountant + Term Sheet + 3 Ledger | Founder | 90s | Stock Price + HQ | 0 | Idea: IPO |
| r_buyout | **Weakened Rival** + $ giá | Lawyer | 60s | Subsidiary | 0 | Idea: M&A |
| r_upgrade_floor | **Document: Lease Office Floor** + $ deposit | Founder | 20s | Office Floor cap | 0 | Idea: Expand |
| r_branch | **Plane Ticket** + Founder + $300 | Founder | 30s | Gateway (bàn 2) | 0 | Idea: Branch |

Quy tắc: recipe thiếu worker → chạy chậm gấp đôi nếu `Founder` làm thay (trừ recipe `specialist`).

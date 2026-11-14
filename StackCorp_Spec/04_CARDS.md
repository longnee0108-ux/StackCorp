# 04 — CARD CATALOG (giá trị khởi điểm, tinh chỉnh bằng simulator ở 07)

Wage = USD / Pay Cycle. Sell = USD. P = phase xuất hiện.

## People
| id | Name | P | Wage | Speed | Notes |
|---|---|---|---|---|---|
| founder | Founder | 1 | 0 | 1.0 | Duy nhất, không bán, không chết (chỉ Hospitalized) |
| intern | Intern | 1 | 3 | 0.7 | Chỉ làm recipe `basic` |
| dev | Developer | 1 | 12 | 1.0 | Build, fix Bug |
| sales | Sales Rep | 1 | 10 | 1.0 | Ký hợp đồng |
| designer | Designer | 1 | 10 | 1.0 | Polish, Pitch Deck |
| senior_dev | Senior Developer | 2 | 20 | 1.4 | Bug dmg 2 |
| marketing | Marketing Specialist | 2 | 14 | 1.0 | Viral campaign |
| team_leader | Team Leader | 2 | 25 | 1.0 | Aura: 3 person kề +20% speed, không cần kéo thủ công |
| accountant | Accountant | 2 | 20 | 1.0 | Thuế −30%, Ledger, đánh Inspector (2) |
| hr | HR Manager | 2 | 18 | 1.0 | Auto hút Burnout vào Pantry, giải Strike |
| lawyer | Lawyer | 2 | 30 | 1.0 | Inspector dmg 3, giải Lawsuit |
| lobbyist | Lobbyist | 3 | 40 | 1.0 | Recession −40% |
| ai_agent | AI Agent | 3 | 15 (điện) | 1.5 | Không stress, thay 3 person cấp thấp; Power Outage dừng; sinh AI Hallucination |

## Equipment & Container
| id | Name | P | Effect |
|---|---|---|---|
| laptop_old | Old Laptop | 1 | Cần cho Dev/Founder làm việc số |
| desk | Desk | 1 | +10% speed person trên cùng stack |
| coffee_machine | Coffee Machine | 1 | Sinh `coffee` mỗi 25s khi có `coffee_beans` |
| whiteboard | Whiteboard | 1 | Founder → Concept/Idea |
| shredder | Shredder | 2 | Hủy Receipt (Quỹ đen) |
| pantry | Pantry Counter | 2 | Hồi stress |
| ergo_chair | Ergonomic Chair | 2 | −25% stress gain |
| bank_counter | Bank Counter | 1 | Đổi mệnh giá |
| office_safe | Office Safe | 1 | 3 cọc, miễn nhiễm trộm |
| bank_card | Bank Card | 1 | Số dư tối đa $500 (Corporate $5,000, P2) |
| server_cloud | Cloud Server | 3 | Cần cho AI Agent, điện $10/cycle |
| assembly_line | Auto Assembly Line | 3 | Tự hút nguyên liệu, nhả product mỗi 20s |

## Resources & Products
| id | Name | Sell | Notes |
|---|---|---|---|
| concept | Concept | 1 | Output Whiteboard |
| marker | Marker | 1 | Input Whiteboard |
| coffee_beans | Coffee Beans | 1 | |
| coffee | Coffee | 1 | Stress −2 / boost speed 1 Day |
| prototype | Prototype | 10 | |
| polished_prototype | Polished Prototype | 16 | |
| signed_deal | Signed Deal | 30 | Cần Lead |
| pitch_deck | Pitch Deck | — | Document, không bán |
| subscription | Software Subscription | 45 | P2 |
| enterprise_license | Enterprise License | 120 | P2 |
| ai_platform | AI Platform | 350 | P3 |
| receipt | Receipt | — | Taxable record |
| ledger_folder | Ledger Folder | — | Gộp 10 Receipt |

## Leads & Hazards
| id | Name | Notes |
|---|---|---|
| freelance_contract | Freelance Contract | Consume, trả $8 qua recipe |
| difficult_client | Difficult Client | Trả $15, stress +2 |
| emergency_client | Emergency Client | Floor income (file 01 mục 10) |
| bug | Bug | hp 3, xem 02 |
| burnout | Burnout | |
| lawsuit | Lawsuit | −$20/cycle |
| inspector | Inspector | hp 12 |
| strike | Strike | |
| eviction_notice | Eviction Notice | Strike thuê nhà |
| hospitalized | Hospitalized | |

## Cash, Docs & Finance
`usd_1, usd_5, usd_20, usd_100` (stack_max 10) · `payroll_invoice, rent_invoice, tax_notice, fine, term_sheet` · `investor` · `stock_price` · `weakened_rival` ($ giá mua = 20× lợi nhuận quý hiện tại của bạn, tối thiểu $3,000) · `subsidiary` (+$150/cycle).

## Buildings (Office upgrade)
`garage` (Start) · `coworking` · `office_floor` · `hq_tower`. Là điều kiện cap, không phải thẻ trên bàn.

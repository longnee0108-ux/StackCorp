$ErrorActionPreference = 'Stop'
$iconDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\icons'
New-Item -ItemType Directory -Path $iconDir -Force | Out-Null
$glyphs = @{
    laptop_old = '<path d="M28 30q35-5 72 0l-2 49H29z" fill="#d1daca"/><path d="M36 38h55v33H36z" fill="#f9efd4"/><path d="m19 87 11-8h68l11 9-3 6H23z" fill="#bbbca7"/><path d="M57 86h16M50 48l-7 7 7 7m27-14 7 7-7 7" fill="none"/>'
    whiteboard = '<path d="M22 20h85v61H22z" fill="#fff5de"/><path d="M43 82 34 108m49-26 10 26M29 72h72" fill="none"/><path d="m36 45 17-9 16 15 23-18m-7-1 8 1-1 9" fill="none" stroke="#739780"/><path d="M37 59h21m12 0h18" fill="none"/>'
    founder = '<path d="M34 111v-20q0-21 30-24 29 3 30 24v20" fill="#7f9f93"/><path d="m51 72 13 22 14-22M62 94l-3 17h11l-3-17" fill="#f7edcf"/><ellipse cx="64" cy="43" rx="22" ry="27" fill="#ecd3ad"/><path d="M43 42V29q5-20 26-14 21 3 17 28l-9-14q-17 10-34 13" fill="#445345"/><path d="M54 47h1m19 0h1m-17 12q7 4 13-1" fill="none"/>'
    dev = '<path d="M30 112V94q0-22 34-23 34 1 34 23v18" fill="#91adb0"/><ellipse cx="64" cy="43" rx="22" ry="27" fill="#ecd3ad"/><path d="M42 39q-5-24 22-27 24 1 23 26l-14-12q-11 13-31 13" fill="#435247"/><path d="M44 43h18v12H44zm23 0h18v12H67zM62 47h5m-9 15q6 3 12-1" fill="none"/><path d="M43 91h42v24H43z" fill="#f7edcf"/><path d="m56 97-5 5 5 5m16-10 5 5-5 5" fill="none"/>'
    designer = '<path d="M30 112V94q0-21 34-23 34 1 34 23v18" fill="#d4a892"/><path d="M41 49q-8-39 23-39 32 1 25 47l-10 21H48z" fill="#665b48"/><ellipse cx="64" cy="44" rx="21" ry="26" fill="#ecd3ad"/><path d="M42 35q29-2 40-14M55 47h1m17 0h1m-16 13q7 3 13-1" fill="none"/><path d="m78 87 8 2-13 28-8-3z" fill="#f5d283"/>'
    sales = '<path d="M29 111V94q0-22 35-23 35 1 35 23v17" fill="#d8b47f"/><ellipse cx="64" cy="43" rx="22" ry="27" fill="#ecd3ad"/><path d="M42 36q-3-24 22-24 23 0 23 25-18-16-45-1" fill="#5f6049"/><path d="M54 46h1m19 0h1m-19 12q8 9 17 0m-21 17 12 14 13-14" fill="none"/><path d="M43 91h43v23H43zm13 0v-6h17v6" fill="#f1e4c5"/>'
    accountant = '<path d="M28 112V94q0-21 36-23 36 2 36 23v18" fill="#a7b19e"/><ellipse cx="64" cy="43" rx="22" ry="27" fill="#ecd3ad"/><path d="M43 34q3-23 23-22 18 1 21 22M45 43h17v12H45zm22 0h17v12H67zM62 47h5" fill="none"/><path d="M47 86h35v32H47z" fill="#f4e8c8"/><path d="M53 93h23m-23 8h4m6 0h4m6 0h3m-23 9h4m6 0h4m6 0h3" fill="none"/>'
    lawyer = '<path d="M27 112V94q0-22 37-23 36 1 36 23v18" fill="#7f9997"/><ellipse cx="64" cy="43" rx="22" ry="27" fill="#ecd3ad"/><path d="M42 39q-4-26 22-27 26 3 23 27l-16-15q-7 12-29 15" fill="#5d5f4f"/><path d="m51 75 13 16 13-16M64 91v21M55 46h1m18 0h1" fill="none"/><path d="m78 90 17-17m-6-6 12 12m-8-16 12 12M76 103h30" fill="none"/>'
    coffee = '<path d="M28 48h61l-6 43q-21 13-49 0z" fill="#f7edcf"/><path d="M89 53q27-2 20 22-5 12-23 9M23 101q40 12 73 0M44 35q-8-9 0-18m20 18q-8-9 0-18m20 18q-8-9 0-18" fill="none"/><path d="M45 58q12-10 24 0" fill="none" stroke="#b88560"/>'
    concept = '<path d="M43 77q-23-24-5-46 22-26 46-6 28 20 1 51l-5 9H49z" fill="#f4d588"/><path d="m49 85 31 1-3 15H53zm7 17h18m-15-5-3-36m16 36 3-36m-19 0 9 6 10-6M64 7V1m39 25 8-7M22 25l-9-7m1 40H4m111 0h9" fill="none"/>'
    prototype = '<path d="m21 49 43-22 43 22v49l-43 22-43-22z" fill="#e9b785"/><path d="m21 49 43 23 43-23M64 72v48M43 38l43 23v19l-17 8V69L43 55z" fill="#f2d69a"/><path d="M31 87 46 95m-15 0 12 6" fill="none"/>'
    polished_prototype = '<path d="m21 49 43-22 43 22v49l-43 22-43-22z" fill="#e7ac78"/><path d="m21 49 43 23 43-23M64 72v48M43 38l43 23v19l-17 8V69L43 55z" fill="#f3d7a0"/><path d="m101 6 3 9 10 4-10 4-3 9-4-9-9-4 9-4z" fill="#f2dfb2"/>'
    document = '<path d="M29 13h52l20 21v79H29z" fill="#fff2d1"/><path d="M80 13v23h21M42 49h44M42 62h44M42 75h33M42 88h19m15 12 8-8 8 8" fill="none"/>'
    signed_deal = '<path d="M29 13h52l20 21v79H29z" fill="#fff2d1"/><path d="M80 13v23h21M42 49h44M42 62h44M42 75h20m5 17q6-21 10-11t10-6m-4 24 21-35" fill="none"/>'
    pitch_deck = '<path d="M22 27h84v64H22z" fill="#f8edcf"/><path d="M31 91h65M64 91v23M40 114h49m-49-32V63h11v19m8 0V52h11v30m8 0V41h11v41" fill="none"/><path d="m35 51 23-13 14 4 18-16" fill="none" stroke="#7f9b7e"/>'
    cash = '<path d="m15 40 92-8 7 55-93 9z" fill="#b5c397"/><path d="m18 33 92-8 7 55-93 9z" fill="#d0dba5"/><path d="m26 42 74-6 3 34-73 7z" fill="none"/><ellipse cx="65" cy="56" rx="15" ry="18" fill="#e8e8b9"/><path d="M65 44v25m7-21q-19-6-14 5l12 6q5 9-12 6" fill="none"/>'
    bank_card = '<rect x="14" y="29" width="101" height="68" rx="9" fill="#9ebfa8"/><path d="M15 45h99v14H15z" fill="#4d6655"/><rect x="26" y="67" width="19" height="15" rx="3" fill="#eed69b"/><path d="M57 77h13m9 0h22" fill="none"/>'
    bank_counter = '<path d="M17 53h95v53H17z" fill="#d1d1b0"/><path d="m12 44 52-27 52 27z" fill="#f1dfb4"/><path d="M25 53v42m22-42v42m23-42v42m22-42v42M12 107h105" fill="none"/><circle cx="64" cy="32" r="5" fill="#a3b798"/>'
    office_safe = '<rect x="25" y="20" width="79" height="89" rx="9" fill="#a4b1a0"/><rect x="35" y="30" width="59" height="68" rx="5" fill="#ced1b2"/><circle cx="65" cy="63" r="15" fill="#eae2bf"/><path d="M65 49v8m0 12v9m-14-15h9m10 0h9m16-25h7m-7 49h7" fill="none"/>'
    bug = '<ellipse cx="65" cy="72" rx="25" ry="30" fill="#b88973"/><circle cx="64" cy="36" r="17" fill="#dbc19a"/><path d="M55 22 47 9m24 13 8-13M40 54 23 42m17 30H19m22 17-18 17m66-51 16-13M90 72h20m-21 17 16 17M65 48v52" fill="none"/><circle cx="58" cy="34" r="2"/><circle cx="70" cy="34" r="2"/>'
    burnout = '<path d="M49 111q-39-18-20-55 7 19 16 12-6-38 19-61 0 26 17 41 4-15 15-18-3 20 8 41 13 30-22 40z" fill="#d89975"/><path d="M55 110q-26-16-3-43-1 19 13 26 4-12 10-15 16 22 0 32" fill="#f5d693"/>'
    inspector = '<path d="M28 112V94q0-21 36-23 36 2 36 23v18" fill="#a9b29d"/><ellipse cx="64" cy="43" rx="22" ry="27" fill="#ecd3ad"/><path d="M37 29h55l-7-16H46z" fill="#6a7b67"/><path d="M54 45h1m19 0h1m-18 17h15" fill="none"/><circle cx="83" cy="89" r="16" fill="#e5ead1"/><path d="m95 102 14 14" fill="none"/>'
    pantry = '<path d="M20 46h88v62H20z" fill="#c9c4a1"/><path d="M14 46h100v10H14z" fill="#f4e9ca"/><path d="M26 65h33v33H26zm43 0h33v33H69zM40 77h6m35 0h6" fill="none"/><path d="M31 19h26v25H31z" fill="#b4c3a3"/><path d="M57 22q18-1 13 13-2 7-13 7" fill="none"/><path d="m85 44-3-24m0 11q-18 0-12-13 13-2 12 13m1-6q2-17 14-13 4 11-14 13" fill="#92ae81"/>'
    server_cloud = '<path d="M30 18h69v94H30z" fill="#a8bdb0"/><path d="M37 26h55v19H37zm0 28h55v19H37zm0 28h55v19H37z" fill="#e1dfc4"/><path d="M44 34h24m-24 28h24m-24 28h24" fill="none"/><circle cx="82" cy="35" r="3"/><circle cx="82" cy="63" r="3"/><circle cx="82" cy="91" r="3"/>'
    ai_agent = '<path d="M37 32h56v52H37z" fill="#c6d3b6"/><path d="M49 88h32v25H49zM37 49H24v25h13m56-25h13v25H93M65 32V18" fill="none"/><circle cx="65" cy="14" r="5" fill="#d7af7f"/><circle cx="51" cy="54" r="5"/><circle cx="79" cy="54" r="5"/><path d="M51 70h28m-30 35-15 8m47-8 15 8" fill="none"/>'
    stock_price = '<path d="M21 104V20m0 84h88" fill="none"/><path d="m29 89 22-24 17 9 35-43m-20 1 21-2-2 21" fill="none" stroke="#719473" stroke-width="7"/><path d="M37 100V86m23 14V80m23 20V64m22 36V56" fill="none" stroke="#b3b98e"/>'
    subsidiary = '<path d="M17 108V57h34v51m-8 0V24h44v84m-9 0V48h34v60M11 111h107" fill="#c6d0b2"/><path d="M54 38h8m9 0h8M54 53h8m9 0h8M54 68h8m9 0h8M54 83h8m9 0h8M26 72h14m-14 15h14m48-23h14m-14 15h14m-14 15h14" fill="none"/>'
    plane_ticket = '<path d="M12 33h104v22q-15 8 0 17v23H12V72q15-9 0-17z" fill="#f3e6c3"/><path d="M83 35v59m-33-52 8 20 21 6-2 6-21-1-15 15-5-3 8-18-15-10 3-5 17 6z" fill="#a9c4b4"/>'
    truck = '<path d="M13 42h62v53H13zm62 13h22l17 20v20H75z" fill="#e1cda0"/><path d="M83 61h11l12 15H83z" fill="#a4bcaf"/><circle cx="37" cy="98" r="13" fill="#7b8d7b"/><circle cx="94" cy="98" r="13" fill="#7b8d7b"/><circle cx="37" cy="98" r="5" fill="#e9dcb9"/><circle cx="94" cy="98" r="5" fill="#e9dcb9"/>'
    marker = '<path d="m35 103 47-79 17 10-47 80z" fill="#c5d1b1"/><path d="m82 24 7-12 17 10-7 12M35 103l-4 17 17-8m-3-25 17 10" fill="#eee1bd"/>'
    coffee_beans = '<path d="M29 30h70l6 82H22z" fill="#d0b490"/><path d="M34 17h59l6 13H29z" fill="#f1dbb4"/><ellipse cx="64" cy="71" rx="16" ry="24" transform="rotate(30 64 71)" fill="#9a8067"/><path d="M70 51q-16 22-12 41" fill="none"/>'
    ergo_chair = '<path d="M43 17h45v48H43z" fill="#91aa99"/><path d="M34 66h61v14H34z" fill="#acc0a4"/><path d="M64 80v27m-26 6 26-6 27 6M30 48v24m68-24v24M20 48h20m48 0h20" fill="none"/>'
    ledger_folder = '<path d="M15 33h39l9 12h50v65H15z" fill="#d9c78e"/><path d="M22 27h76v66H22z" fill="#fff0cc"/><path d="M30 40h59m-59 13h59m-59 13h59M50 32v54m22-54v54" fill="none"/><path d="M15 64h102l-8 46H15z" fill="#d9c78e"/>'
    insurance = '<path d="m64 14 39 15v35q0 29-39 51-39-22-39-51V29z" fill="#a8bea2"/><path d="m46 64 13 14 26-31" fill="none" stroke-width="7"/>'
    event = '<path d="m64 12 13 29 32 4-24 23 7 33-28-16-28 16 6-33-24-23 32-4z" fill="#e6cb89"/>'
    shredder = '<path d="M32 18h64v42H32z" fill="#f7e9c8"/><path d="M23 51h82v53H23z" fill="#a6b29b"/><path d="M33 63h62M43 84v32m14-32v32m14-32v32m14-32v32M43 32h41m-41 10h27" fill="none"/>'
}
$aliases = @{
    person='founder'; intern='dev'; senior_dev='dev'; marketing='sales'; team_leader='founder'; hr='designer'; lobbyist='lawyer'; investor='sales'; candidate='founder';
    equipment='laptop_old'; laptop='laptop_old'; desk='ergo_chair'; coffee_machine='pantry'; assembly_line='server_cloud'; power_backup='server_cloud';
    product='prototype'; resource='concept'; idea='concept'; subscription='laptop_old'; enterprise_license='signed_deal'; ai_platform='ai_agent';
    container='office_safe'; hazard='bug'; ai_hallucination='bug'; lawsuit='document'; strike='burnout'; hospitalized='insurance';
    receipt='document'; payroll_invoice='document'; rent_invoice='document'; tax_notice='document'; fine='document'; term_sheet='signed_deal';
    freelance_contract='signed_deal'; difficult_client='signed_deal'; emergency_client='signed_deal'; pitch_template='pitch_deck';
    usd_1='cash'; usd_5='cash'; usd_20='cash'; usd_100='cash'; black_fund='cash'; stock_option='stock_price';
    weakened_rival='subsidiary'; gateway='plane_ticket'; building='subsidiary'; garage='subsidiary'; coworking='subsidiary'; office_floor='subsidiary'; hq_tower='subsidiary';
    team_building_ticket='plane_ticket'; perk='event'; bonus='cash'; eviction_notice='document'; inspection_portal='inspector';
    buggy_product='prototype'; million_contract='signed_deal'; factory_permit='document'; overseas_branch_doc='document'; lease_office_floor='document'
}
foreach ($entry in $glyphs.GetEnumerator()) {
    $svg = '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#35463b" stroke-width="3.3" stroke-linejoin="round" stroke-linecap="round">' + $entry.Value + '</g></svg>'
    [IO.File]::WriteAllText((Join-Path $iconDir ($entry.Key + '.svg')), $svg, [Text.UTF8Encoding]::new($false))
}
foreach ($entry in $aliases.GetEnumerator()) {
    Copy-Item -LiteralPath (Join-Path $iconDir ($entry.Value + '.svg')) -Destination (Join-Path $iconDir ($entry.Key + '.svg'))
}
Write-Host "Created $($glyphs.Count + $aliases.Count) bundled original card illustrations."

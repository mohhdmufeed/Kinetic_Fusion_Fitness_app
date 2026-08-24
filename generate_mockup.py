# -*- coding: utf-8 -*-
import base64
import pathlib

def b64(path):
    p = pathlib.Path(path)
    if not p.exists():
        return ''
    mime = 'image/jpeg' if path.endswith(('.jpg', '.jpeg')) else 'image/png'
    return f'data:{mime};base64,' + base64.b64encode(p.read_bytes()).decode('utf-8')

gym = b64('getfit_flutter/assets/images/gym_bg.png')
torso = b64('getfit_flutter/assets/images/athlete_torso.png')
curl = b64('getfit_flutter/assets/images/athlete_curl.png')
female_sil = b64('getfit_flutter/assets/images/female_silhouette.png')
oh_press = b64('getfit_flutter/assets/images/overhead_press.png')
bench = b64('getfit_flutter/assets/images/bench_press.jpg')
focus = b64('getfit_flutter/assets/images/athlete_focus.png')
panoramic = b64('getfit_flutter/assets/images/gym_panoramic.png')
iron_db = b64('getfit_flutter/assets/images/iron_dumbbells.png')
textured_db = b64('getfit_flutter/assets/images/textured_dumbbells.jpg')
hex_floor = b64('getfit_flutter/assets/images/hex_dumbbells_floor.png')

html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Kinetic Precision — 19-Screen Fitness Mobile Mockup</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/tabler-icons/2.44.0/iconfont/tabler-icons.min.css">
<style>
  :root {{
    --bg: #0d0e0f;
    --card: #161719;
    --border: #222326;
    --accent: #859463;
    --text: #f5f5f0;
    --text-dim: #8e9094;
    --text-faint: #55575c;
    --img-gym: url('{gym}');
    --img-torso: url('{torso}');
    --img-curl: url('{curl}');
    --img-female: url('{female_sil}');
    --img-overhead: url('{oh_press}');
    --img-bench: url('{bench}');
    --img-focus: url('{focus}');
    --img-panoramic: url('{panoramic}');
    --img-iron-db: url('{iron_db}');
    --img-textured-db: url('{textured_db}');
    --img-hex-floor: url('{hex_floor}');
  }}
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    background:
      radial-gradient(ellipse 900px 500px at 50% 100%, rgba(140,190,20,0.16), transparent 70%),
      radial-gradient(ellipse 600px 400px at 15% 0%, rgba(60,90,10,0.10), transparent 60%),
      #050505;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    padding: 40px 20px;
    display: flex;
    flex-wrap: wrap;
    gap: 24px;
    justify-content: center;
    color: var(--text);
  }}
  .row-label {{
    width: 100%;
    color: var(--accent);
    font-size: 13px;
    font-weight: 800;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    margin: 20px 0 -8px 8px;
    display: flex;
    align-items: center;
    gap: 8px;
  }}
  .row-label::after {{
    content: '';
    flex: 1;
    height: 1px;
    background: linear-gradient(90deg, var(--border), transparent);
  }}
  .phone {{
    width: 270px;
    background: #000;
    border: 1px solid #2a2a2a;
    border-radius: 32px;
    padding: 12px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.8), 0 0 20px rgba(200,255,61,0.04);
    transition: transform 0.2s ease, border-color 0.2s ease;
  }}
  .phone:hover {{
    transform: translateY(-4px);
    border-color: rgba(200,255,61,0.3);
  }}
  .screen {{
    background: var(--bg);
    border-radius: 22px;
    padding: 18px 16px 14px;
    min-height: 540px;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    position: relative;
  }}
  /* Photography backgrounds with dark moody overlays */
  .screen.bg-gym {{
    background: linear-gradient(180deg, rgba(10,10,10,0.70) 0%, rgba(10,10,10,0.96) 80%), var(--img-gym) center/cover no-repeat;
  }}
  .screen.bg-panoramic {{
    background: linear-gradient(180deg, rgba(10,10,10,0.65) 0%, rgba(10,10,10,0.95) 85%), var(--img-panoramic) center/cover no-repeat;
  }}
  .screen.bg-torso {{
    background: linear-gradient(180deg, rgba(10,10,10,0.65) 0%, rgba(10,10,10,0.96) 85%), var(--img-torso) center/cover no-repeat;
  }}
  .screen.bg-curl {{
    background: linear-gradient(180deg, rgba(10,10,10,0.60) 0%, rgba(10,10,10,0.95) 85%), var(--img-curl) center/cover no-repeat;
  }}
  .screen.bg-female {{
    background: linear-gradient(180deg, rgba(10,10,10,0.65) 0%, rgba(10,10,10,0.96) 85%), var(--img-female) center/cover no-repeat;
  }}
  .screen.bg-overhead {{
    background: linear-gradient(180deg, rgba(10,10,10,0.60) 0%, rgba(10,10,10,0.95) 85%), var(--img-overhead) center/cover no-repeat;
  }}
  .screen.bg-focus {{
    background: linear-gradient(180deg, rgba(10,10,10,0.65) 0%, rgba(10,10,10,0.96) 85%), var(--img-focus) center/cover no-repeat;
  }}
  .screen.bg-iron-db {{
    background: linear-gradient(180deg, rgba(10,10,10,0.65) 0%, rgba(10,10,10,0.96) 85%), var(--img-iron-db) center/cover no-repeat;
  }}
  .screen.bg-textured-db {{
    background: linear-gradient(180deg, rgba(10,10,10,0.65) 0%, rgba(10,10,10,0.96) 85%), var(--img-textured-db) center/cover no-repeat;
  }}
  .screen.bg-hex-floor {{
    background: linear-gradient(180deg, rgba(10,10,10,0.65) 0%, rgba(10,10,10,0.96) 85%), var(--img-hex-floor) center/cover no-repeat;
  }}
  .status {{
    display: flex;
    justify-content: space-between;
    font-size: 11px;
    color: var(--text-dim);
    margin-bottom: 14px;
  }}
  .topbar {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 14px;
  }}
  .icon-btn {{
    width: 30px;
    height: 30px;
    border-radius: 50%;
    border: 1px solid var(--border);
    background: rgba(20,20,20,0.7);
    backdrop-filter: blur(8px);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text);
    font-size: 14px;
    flex-shrink: 0;
    cursor: pointer;
  }}
  .eyebrow {{
    font-size: 10px;
    letter-spacing: 1px;
    color: var(--accent);
    font-weight: 700;
    text-transform: uppercase;
    margin-bottom: 6px;
  }}
  h1 {{
    font-size: 22px;
    font-weight: 800;
    color: var(--text);
    line-height: 1.15;
    margin-bottom: 4px;
    letter-spacing: -0.5px;
  }}
  .sub {{
    font-size: 12px;
    color: var(--text-dim);
    margin-bottom: 16px;
    line-height: 1.5;
  }}
  .field {{
    background: rgba(20,20,20,0.8);
    backdrop-filter: blur(10px);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 11px 12px;
    font-size: 12px;
    color: var(--text-faint);
    margin-bottom: 10px;
    display: flex;
    align-items: center;
    gap: 8px;
  }}
  .field i {{ font-size: 15px; color: var(--accent); opacity: 0.7; }}
  .btn {{
    background: var(--accent);
    color: #0a0a0a;
    border: none;
    border-radius: 11px;
    padding: 14px;
    font-size: 14px;
    font-weight: 800;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    cursor: pointer;
    box-shadow: 0 4px 14px rgba(200,255,61,0.25);
  }}
  .btn-outline {{
    background: rgba(20,20,20,0.6);
    backdrop-filter: blur(8px);
    color: var(--text);
    border: 1px solid var(--border);
    border-radius: 11px;
    padding: 11px;
    font-size: 12px;
    font-weight: 600;
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
  }}
  .oauth-row {{ display: flex; gap: 8px; margin-top: 10px; }}
  .divider-text {{
    text-align: center;
    font-size: 10px;
    color: var(--text-faint);
    margin: 14px 0;
    position: relative;
  }}
  .foot-link {{
    text-align: center;
    font-size: 11px;
    color: var(--text-dim);
    margin-top: 14px;
  }}
  .foot-link b {{ color: var(--accent); font-weight: 700; }}
  
  /* Photo blocks styled with dark overlay and glow */
  .ph-block {{
    border-radius: 16px;
    height: 160px;
    position: relative;
    overflow: hidden;
    margin-bottom: 16px;
    border: 1px solid rgba(200,255,61,0.25);
    display: flex;
    align-items: flex-end;
    padding: 12px;
  }}
  .ph-block.bg-female {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-female) center/cover no-repeat;
  }}
  .ph-block.bg-overhead {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-overhead) center/cover no-repeat;
  }}
  .ph-block.bg-focus {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-focus) center/cover no-repeat;
  }}
  .ph-block.bg-bench {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-bench) center/cover no-repeat;
  }}
  .ph-block.bg-torso {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-torso) center/cover no-repeat;
  }}
  .ph-block.bg-curl {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-curl) center/cover no-repeat;
  }}
  .ph-block.bg-gym {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-gym) center/cover no-repeat;
  }}
  .ph-block.bg-iron-db {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-iron-db) center/cover no-repeat;
  }}
  .ph-block.bg-textured-db {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-textured-db) center/cover no-repeat;
  }}
  .ph-block.bg-hex-floor {{
    background: linear-gradient(180deg, rgba(10,10,10,0.15) 0%, rgba(10,10,10,0.85) 100%), var(--img-hex-floor) center/cover no-repeat;
  }}
  .ph-block .badge {{
    position: absolute;
    bottom: 10px;
    right: 10px;
    z-index: 2;
    width: 26px;
    height: 26px;
    border-radius: 50%;
    background: rgba(0,0,0,0.7);
    border: 1px solid var(--accent);
    display: flex;
    align-items: center;
    justify-content: center;
  }}
  .ph-block .badge i {{ font-size: 13px; color: var(--accent); }}
  .ph-block.tall {{
    height: 230px;
    margin-bottom: 0;
    border-radius: 22px 22px 0 0;
    border: none;
  }}
  
  .dots {{ display: flex; gap: 6px; justify-content: center; margin: 16px 0; }}
  .dots span {{ width: 6px; height: 6px; border-radius: 50%; background: var(--border); }}
  .dots span.on {{ background: var(--accent); width: 18px; border-radius: 3px; box-shadow: 0 0 8px var(--accent); }}
  .otp-row {{ display: flex; gap: 6px; margin-bottom: 16px; }}
  .otp {{
    flex: 1;
    aspect-ratio: 1;
    border: 1px solid var(--border);
    border-radius: 9px;
    background: rgba(20,20,20,0.7);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text);
    font-weight: 700;
    font-size: 15px;
  }}
  .card {{
    background: rgba(20,20,20,0.75);
    backdrop-filter: blur(10px);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 13px 14px;
    margin-bottom: 10px;
  }}
  .pill {{
    font-size: 10px;
    font-weight: 700;
    padding: 5px 10px;
    border-radius: 20px;
    border: 1px solid var(--border);
    color: var(--text-dim);
    white-space: nowrap;
    background: rgba(20,20,20,0.6);
  }}
  .pill.on {{
    background: var(--accent);
    color: #0a0a0a;
    border-color: var(--accent);
    box-shadow: 0 0 10px rgba(200,255,61,0.2);
  }}
  .pill-row {{ display: flex; gap: 6px; overflow: hidden; margin-bottom: 14px; }}
  .stat3 {{ display: flex; justify-content: space-between; margin-bottom: 6px; }}
  .stat3 .n {{ font-size: 17px; font-weight: 800; color: var(--text); }}
  .stat3 .l {{ font-size: 9px; color: var(--text-faint); text-transform: uppercase; letter-spacing: 0.5px; font-weight: 700; }}
  .section-head {{ display: flex; justify-content: space-between; align-items: baseline; margin: 14px 0 8px; }}
  .section-head h3 {{ font-size: 13px; font-weight: 700; color: var(--text); }}
  .section-head span {{ font-size: 10px; color: var(--accent); font-weight: 700; }}
  .thumb-row {{ display: flex; gap: 8px; }}
  .thumb {{
    flex: 1;
    border-radius: 12px;
    overflow: hidden;
    border: 1px solid var(--border);
    background: #101010;
  }}
  .thumb .ph-block {{ height: 80px; margin: 0; border-radius: 0; border: none; }}
  .thumb .meta {{ padding: 8px; background: rgba(16,16,16,0.9); }}
  .thumb .meta .t {{ font-size: 11px; font-weight: 700; color: var(--text); }}
  .thumb .meta .m {{ font-size: 9px; color: var(--text-faint); margin-top: 2px; }}
  .list-row {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 2px;
    border-bottom: 1px solid rgba(255,255,255,0.06);
  }}
  .list-row:last-child {{ border-bottom: none; }}
  .lr-icon {{
    width: 34px;
    height: 34px;
    border-radius: 9px;
    background: rgba(25,25,25,0.8);
    border: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--accent);
    font-size: 16px;
    flex-shrink: 0;
    margin-right: 10px;
  }}
  .lr-title {{ font-size: 12px; font-weight: 700; color: var(--text); }}
  .lr-sub {{ font-size: 10px; color: var(--text-faint); margin-top: 2px; }}
  .search {{
    display: flex;
    align-items: center;
    gap: 8px;
    background: rgba(20,20,20,0.8);
    border: 1px solid var(--border);
    border-radius: 11px;
    padding: 10px 12px;
    margin-bottom: 14px;
    color: var(--text-faint);
    font-size: 11px;
  }}
  .avatar {{
    width: 68px;
    height: 68px;
    border-radius: 50%;
    margin: 0 auto 10px;
    border: 2px solid var(--accent);
    background: var(--img-torso) center/cover no-repeat;
    box-shadow: 0 0 16px rgba(200,255,61,0.25);
  }}
  .center {{ text-align: center; }}
  .tabbar {{
    display: flex;
    justify-content: space-around;
    padding-top: 12px;
    margin-top: auto;
    border-top: 1px solid var(--border);
    background: rgba(10,10,10,0.85);
    backdrop-filter: blur(10px);
  }}
  .tab {{
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 3px;
    font-size: 9px;
    color: var(--text-faint);
    font-weight: 700;
  }}
  .tab i {{ font-size: 18px; }}
  .tab.active {{ color: var(--accent); }}
  .bars {{ display: flex; align-items: flex-end; gap: 6px; height: 60px; margin: 10px 0; }}
  .bars div {{ flex: 1; background: var(--accent); border-radius: 4px 4px 0 0; box-shadow: 0 0 8px rgba(200,255,61,0.2); }}
  .bars div.off {{ background: var(--border); box-shadow: none; }}
  .spark {{ width: 100%; height: 36px; }}
  .chat-bubble {{
    max-width: 82%;
    border-radius: 14px;
    padding: 10px 12px;
    font-size: 11px;
    line-height: 1.45;
    margin-bottom: 8px;
  }}
  .chat-bubble.bot {{
    background: rgba(20,20,20,0.85);
    border: 1px solid var(--border);
    color: var(--text);
    align-self: flex-start;
  }}
  .chat-bubble.user {{
    background: var(--accent);
    color: #0a0a0a;
    align-self: flex-end;
    font-weight: 700;
  }}
  .chat-col {{ display: flex; flex-direction: column; flex: 1; overflow: hidden; }}
  .chat-cta {{
    display: inline-flex;
    align-items: center;
    gap: 4px;
    background: #0a0a0a;
    color: var(--accent);
    border: 1px solid var(--accent);
    border-radius: 8px;
    padding: 5px 9px;
    font-size: 10px;
    font-weight: 700;
    margin-top: 6px;
  }}
  .chat-input {{
    display: flex;
    align-items: center;
    gap: 8px;
    background: rgba(20,20,20,0.85);
    border: 1px solid var(--border);
    border-radius: 20px;
    padding: 8px 10px;
    margin-top: 10px;
  }}
  .chat-input input {{ flex: 1; }}
  .send-btn {{
    width: 26px;
    height: 26px;
    border-radius: 50%;
    background: var(--accent);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #0a0a0a;
    font-size: 13px;
    flex-shrink: 0;
    cursor: pointer;
  }}
</style>
</head>
<body>

<div class="row-label"><i class="ti ti-sparkles"></i> Onboarding Flow</div>

<!-- 1. Splash -->
<div class="phone"><div class="screen bg-panoramic center" style="justify-content:center;">
  <div style="margin:auto 0;">
    <i class="ti ti-triangle" style="font-size:56px;color:var(--accent);filter:drop-shadow(0 0 16px rgba(200,255,61,0.5));"></i>
    <h1 style="margin-top:14px;letter-spacing:1px;">KINETIC</h1>
    <div style="font-size:11px;letter-spacing:4px;color:var(--accent);margin-top:2px;font-weight:800;">PRECISION</div>
    <div style="font-size:10px;color:var(--text-faint);margin-top:24px;letter-spacing:1.5px;">TRAIN WITH INTENTION</div>
  </div>
</div></div>

<!-- 2. Onboarding 1 -->
<div class="phone"><div class="screen">
  <div class="topbar"><span></span><span style="font-size:11px;color:var(--text-faint);font-weight:600;">Skip</span></div>
  <div class="ph-block bg-female"><div class="badge"><i class="ti ti-target"></i></div></div>
  <h1>Set & crush your goals</h1>
  <p class="sub">Define your fitness targets and let Kinetic calibrate your progressive overload and bio-recovery in real-time.</p>
  <div class="dots"><span class="on"></span><span></span><span></span></div>
  <button class="btn" style="margin-top:auto;">Next <i class="ti ti-arrow-right"></i></button>
</div></div>

<!-- 3. Onboarding 2 -->
<div class="phone"><div class="screen">
  <div class="topbar"><span></span><span style="font-size:11px;color:var(--text-faint);font-weight:600;">Skip</span></div>
  <div class="ph-block bg-overhead"><div class="badge"><i class="ti ti-flame"></i></div></div>
  <h1>Track every workout</h1>
  <p class="sub">Log reps, RPE, velocity, and tonnage with zero friction — completely offline-capable with instant cloud sync.</p>
  <div class="dots"><span></span><span class="on"></span><span></span></div>
  <button class="btn" style="margin-top:auto;">Next <i class="ti ti-arrow-right"></i></button>
</div></div>

<!-- 4. Onboarding 3 -->
<div class="phone"><div class="screen">
  <div class="topbar"><span></span><span style="font-size:11px;color:var(--text-faint);"></span></div>
  <div class="ph-block bg-focus"><div class="badge"><i class="ti ti-trending-up"></i></div></div>
  <h1>Monitor your progress</h1>
  <p class="sub">Track lean body mass, HRV readiness, and unlock elite milestones along your transformation trajectory.</p>
  <div class="dots"><span></span><span></span><span class="on"></span></div>
  <button class="btn" style="margin-top:auto;">Get started <i class="ti ti-arrow-right"></i></button>
</div></div>

<div class="row-label"><i class="ti ti-lock"></i> Authentication</div>

<!-- 5. Login -->
<div class="phone"><div class="screen bg-gym">
  <div class="center" style="margin-bottom:18px;">
    <i class="ti ti-triangle" style="font-size:26px;color:var(--accent);"></i>
    <div style="font-size:13px;font-weight:800;color:var(--text);margin-top:4px;letter-spacing:1px;">KINETIC</div>
  </div>
  <h1>Welcome back</h1>
  <p class="sub">Login to access your personalized dashboard.</p>
  <div class="field"><i class="ti ti-mail"></i>Email address</div>
  <div class="field"><i class="ti ti-lock"></i>Password</div>
  <div style="text-align:right;font-size:10px;color:var(--text-dim);margin-bottom:14px;">Forgot password?</div>
  <button class="btn">Login</button>
  <div class="divider-text">or continue with</div>
  <div class="oauth-row">
    <div class="btn-outline"><i class="ti ti-brand-google"></i> Google</div>
    <div class="btn-outline"><i class="ti ti-brand-apple"></i> Apple</div>
  </div>
  <div class="foot-link">Don't have an account? <b>Sign up</b></div>
</div></div>

<!-- 6. Register -->
<div class="phone"><div class="screen bg-torso">
  <h1>Create account</h1>
  <p class="sub">Start your performance journey with Kinetic.</p>
  <div style="display:flex;gap:8px;">
    <div class="field" style="flex:1;">First name</div>
    <div class="field" style="flex:1;">Last name</div>
  </div>
  <div class="field"><i class="ti ti-mail"></i>Email address</div>
  <div class="field"><i class="ti ti-lock"></i>Password</div>
  <div class="field"><i class="ti ti-lock"></i>Confirm password</div>
  <p style="font-size:9px;color:var(--text-faint);margin-bottom:12px;">By registering, you agree to the Terms & Privacy Policy.</p>
  <button class="btn">Create account</button>
  <div class="divider-text">or continue with</div>
  <div class="oauth-row">
    <div class="btn-outline"><i class="ti ti-brand-google"></i> Google</div>
    <div class="btn-outline"><i class="ti ti-brand-apple"></i> Apple</div>
  </div>
  <div class="foot-link">Already have an account? <b>Login</b></div>
</div></div>

<!-- 7. Verification -->
<div class="phone"><div class="screen bg-curl">
  <div class="icon-btn" style="margin-bottom:20px;"><i class="ti ti-arrow-left"></i></div>
  <h1>Verification</h1>
  <p class="sub">We sent a 6-digit security code to your email.</p>
  <div class="otp-row"><div class="otp">1</div><div class="otp">3</div><div class="otp">5</div><div class="otp">8</div><div class="otp">7</div><div class="otp">6</div></div>
  <button class="btn">Verify code</button>
</div></div>

<div class="row-label"><i class="ti ti-key"></i> Password Recovery</div>

<!-- 8. Forgot Password -->
<div class="phone"><div class="screen bg-hex-floor">
  <div class="icon-btn" style="margin-bottom:20px;"><i class="ti ti-arrow-left"></i></div>
  <h1>Forgot password</h1>
  <p class="sub">Enter your email address to reset access.</p>
  <div class="field"><i class="ti ti-mail"></i>Email address</div>
  <button class="btn">Continue</button>
</div></div>

<!-- 9. Enter Passcode -->
<div class="phone"><div class="screen bg-textured-db">
  <div class="icon-btn" style="margin-bottom:20px;"><i class="ti ti-arrow-left"></i></div>
  <h1>Enter passcode</h1>
  <p class="sub">Check your inbox for the reset code.</p>
  <div class="otp-row"><div class="otp">2</div><div class="otp">8</div><div class="otp">9</div><div class="otp">0</div><div class="otp">4</div><div class="otp">1</div></div>
  <button class="btn">Verify</button>
</div></div>

<!-- 10. Set New Password -->
<div class="phone"><div class="screen bg-iron-db">
  <div class="icon-btn" style="margin-bottom:20px;"><i class="ti ti-arrow-left"></i></div>
  <h1>Set new password</h1>
  <p class="sub">Enter a secure password for your account.</p>
  <div class="field"><i class="ti ti-lock"></i>New password</div>
  <div class="field"><i class="ti ti-lock"></i>Confirm password</div>
  <button class="btn">Save password</button>
</div></div>

<div class="row-label"><i class="ti ti-home"></i> Core App Experience</div>

<!-- 11. Home Screen -->
<div class="phone"><div class="screen bg-panoramic">
  <div class="topbar">
    <div><div style="font-size:10px;color:var(--text-faint);">Good morning</div><div style="font-size:15px;font-weight:800;color:var(--text);">Alex Morgan</div></div>
    <div class="icon-btn"><i class="ti ti-bell"></i></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;">
      <span style="font-size:11px;font-weight:700;color:var(--text);">Today's Telemetry</span>
      <span class="pill on" style="font-size:9px;">Optimal 89%</span>
    </div>
    <div class="stat3">
      <div><div class="n">320</div><div class="l">Kcal</div></div>
      <div><div class="n">6,240</div><div class="l">Steps</div></div>
      <div><div class="n">48m</div><div class="l">Active</div></div>
    </div>
    <div style="height:4px;background:var(--border);border-radius:2px;margin-top:8px;overflow:hidden;">
      <div style="width:64%;height:100%;background:var(--accent);box-shadow:0 0 8px var(--accent);"></div>
    </div>
  </div>
  <div class="card" onclick="document.querySelectorAll('.phone')[15].scrollIntoView({{behavior:'smooth'}})" style="display:flex;align-items:center;gap:10px;cursor:pointer;border-color:rgba(133,148,99,0.4);">
    <div class="lr-icon" style="margin:0;background:rgba(133,148,99,0.18);color:var(--accent);"><i class="ti ti-message-chatbot"></i></div>
    <div style="flex:1;"><div class="lr-title">Kinetic AI Coach (Offline)</div><div class="lr-sub">Prescription: Hypertrophy Chest Day</div></div>
    <span class="pill on" style="font-size:9px;">Ask AI &rarr;</span>
  </div>
  <div class="pill-row"><span class="pill on">All</span><span class="pill">Chest</span><span class="pill">Arms</span><span class="pill">Legs</span><span class="pill">Back</span></div>
  <div class="section-head"><h3>Suggested Workouts</h3><span>See all</span></div>
  <div class="thumb-row">
    <div class="thumb"><div class="ph-block bg-bench"><div class="badge" style="width:18px;height:18px;bottom:5px;right:5px;"><i class="ti ti-barbell" style="font-size:9px;"></i></div></div><div class="meta"><div class="t">Chest Heavy</div><div class="m">8 exercises · 45m</div></div></div>
    <div class="thumb"><div class="ph-block bg-overhead"><div class="badge" style="width:18px;height:18px;bottom:5px;right:5px;"><i class="ti ti-flame" style="font-size:9px;"></i></div></div><div class="meta"><div class="t">Overhead Power</div><div class="m">10 exercises · 60m</div></div></div>
  </div>
  <div class="tabbar">
    <div class="tab active"><i class="ti ti-bolt"></i>Today</div>
    <div class="tab"><i class="ti ti-barbell"></i>Train</div>
    <div class="tab"><i class="ti ti-activity"></i>Body</div>
    <div class="tab"><i class="ti ti-user"></i>You</div>
  </div>
</div></div>

<!-- 12. Explore Screen -->
<div class="phone"><div class="screen bg-gym">
  <div class="topbar"><h1 style="font-size:20px;">Explore</h1><div class="icon-btn"><i class="ti ti-adjustments"></i></div></div>
  <div class="search"><i class="ti ti-search"></i>Search routines, trainers...</div>
  <div class="pill-row"><span class="pill on">All</span><span class="pill">Trainers</span><span class="pill">Classes</span><span class="pill">Exercises</span></div>
  <div class="section-head"><h3>Trending Now</h3><span>See all</span></div>
  <div class="thumb-row" style="margin-bottom:6px;">
    <div class="thumb"><div class="ph-block bg-female"><div class="badge" style="width:18px;height:18px;bottom:5px;right:5px;"><i class="ti ti-barbell" style="font-size:9px;"></i></div></div><div class="meta"><div class="t">Conditioning</div><div class="m">45m</div></div></div>
    <div class="thumb"><div class="ph-block bg-curl"><div class="badge" style="width:18px;height:18px;bottom:5px;right:5px;"><i class="ti ti-flame" style="font-size:9px;"></i></div></div><div class="meta"><div class="t">Bicep Peak</div><div class="m">60m</div></div></div>
  </div>
  <div class="section-head"><h3>Popular Exercises</h3><span>See all</span></div>
  <div class="list-row"><div style="display:flex;align-items:center;"><div class="lr-icon"><i class="ti ti-barbell"></i></div><div><div class="lr-title">Barbell Bench Press</div><div class="lr-sub">Chest · 1RM: 110 kg</div></div></div><span style="font-size:10px;color:var(--accent);font-weight:800;">4.9</span></div>
  <div class="list-row"><div style="display:flex;align-items:center;"><div class="lr-icon"><i class="ti ti-weight"></i></div><div><div class="lr-title">Barbell Squat</div><div class="lr-sub">Legs · 1RM: 150 kg</div></div></div><span style="font-size:10px;color:var(--accent);font-weight:800;">4.8</span></div>
  <div class="tabbar">
    <div class="tab"><i class="ti ti-bolt"></i>Today</div>
    <div class="tab active"><i class="ti ti-barbell"></i>Train</div>
    <div class="tab"><i class="ti ti-activity"></i>Body</div>
    <div class="tab"><i class="ti ti-user"></i>You</div>
  </div>
</div></div>

<!-- 13. Workout Detail -->
<div class="phone"><div class="screen" style="padding:0;">
  <div style="position:relative;">
    <div class="ph-block tall bg-bench"><div class="badge" style="width:30px;height:30px;bottom:12px;right:12px;"><i class="ti ti-barbell" style="font-size:15px;"></i></div></div>
    <div style="position:absolute;top:16px;left:16px;" class="icon-btn"><i class="ti ti-arrow-left"></i></div>
    <div style="position:absolute;top:16px;right:16px;" class="icon-btn"><i class="ti ti-bookmark"></i></div>
  </div>
  <div style="padding:16px;">
    <h1>Chest Day Heavy</h1>
    <div style="display:flex;gap:12px;font-size:10px;color:var(--text-faint);margin:6px 0 12px;">
      <span><i class="ti ti-clock"></i> 45 min</span><span><i class="ti ti-flame"></i> 320 kcal</span><span><i class="ti ti-list"></i> 8 exercises</span>
    </div>
    <div style="font-size:11px;font-weight:700;color:var(--text);margin-bottom:4px;">About</div>
    <p class="sub">High-intensity chest workout optimized for mechanical tension and progressive volume overload.</p>
    <div style="font-size:11px;font-weight:700;color:var(--text);margin-bottom:2px;">Exercises</div>
    <div class="list-row"><div style="display:flex;align-items:center;"><div class="lr-icon"><i class="ti ti-barbell"></i></div><div><div class="lr-title">Eleiko Bench Press</div><div class="lr-sub">4 sets · 12 reps · 80 kg</div></div></div></div>
    <div class="list-row"><div style="display:flex;align-items:center;"><div class="lr-icon"><i class="ti ti-barbell"></i></div><div><div class="lr-title">Incline DB Press</div><div class="lr-sub">3 sets · 10 reps · 28 kg</div></div></div></div>
  </div>
</div></div>

<!-- 14. Profile Screen -->
<div class="phone"><div class="screen bg-torso">
  <div class="topbar"><div class="icon-btn"><i class="ti ti-arrow-left"></i></div><div class="icon-btn"><i class="ti ti-settings"></i></div></div>
  <div class="center">
    <div class="avatar"></div>
    <div style="font-size:16px;font-weight:800;color:var(--text);">Alex Morgan</div>
    <div style="font-size:10px;color:var(--text-dim);margin-bottom:14px;">Kinetic Precision Athlete · Member since 2025</div>
  </div>
  <div class="stat3" style="margin-bottom:16px;">
    <div class="center" style="flex:1;"><div class="n">24</div><div class="l">Workouts</div></div>
    <div class="center" style="flex:1;"><div class="n">7</div><div class="l">Goals Hit</div></div>
    <div class="center" style="flex:1;"><div class="n">8,450</div><div class="l">Kcal Total</div></div>
  </div>
  <div class="section-head" style="margin-top:0;"><h3>Active Goals</h3><span>Edit</span></div>
  <div class="list-row"><div><div class="lr-title">Hypertrophy Focus</div><div class="lr-sub">Target 78 kg · Current 76.5 kg</div></div></div>
  <div class="list-row"><div><div class="lr-title">Bench Press 1RM</div><div class="lr-sub">Target 120 kg · Current 110 kg</div></div></div>
  <div class="list-row" onclick="window.scrollTo({{top:0,behavior:'smooth'}})" style="cursor:pointer;border-color:rgba(239,68,68,0.3);margin-top:8px;">
    <div style="display:flex;align-items:center;">
      <div class="lr-icon" style="background:rgba(239,68,68,0.15);color:#ef4444;"><i class="ti ti-logout"></i></div>
      <div><div class="lr-title" style="color:#ef4444;">Log Out</div><div class="lr-sub">Return to Login Screen</div></div>
    </div>
  </div>
  <div class="tabbar">
    <div class="tab"><i class="ti ti-bolt"></i>Today</div>
    <div class="tab"><i class="ti ti-barbell"></i>Train</div>
    <div class="tab"><i class="ti ti-activity"></i>Body</div>
    <div class="tab active"><i class="ti ti-user"></i>You</div>
  </div>
</div></div>

<!-- 15. Activity Telemetry Screen -->
<div class="phone"><div class="screen bg-hex-floor">
  <div class="topbar">
    <h1 style="font-size:22px;font-weight:800;letter-spacing:-0.5px;">Activity</h1>
    <div style="display:flex;gap:6px;align-items:center;">
      <div class="icon-btn" style="width:28px;height:28px;font-size:14px;color:var(--accent);"><i class="ti ti-circle-plus"></i></div>
      <div class="avatar" style="width:26px;height:26px;border:1.5px solid var(--accent);margin:0;"></div>
    </div>
  </div>
  <p class="sub" style="font-size:10px;margin-bottom:12px;">Comprehensive 24/7 movement, training & biological metrics</p>

  <!-- 1. Steps Telemetry -->
  <div class="card" style="margin-bottom:10px;cursor:pointer;border-color:rgba(133,148,99,0.3);">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
      <div style="display:flex;align-items:center;gap:8px;">
        <div style="padding:4px 6px;border-radius:8px;background:rgba(133,148,99,0.18);color:var(--accent);font-size:14px;"><i class="ti ti-walk"></i></div>
        <span style="font-size:12px;font-weight:800;color:var(--text);">Steps Telemetry</span>
      </div>
      <span style="font-size:10px;font-weight:800;color:var(--accent);">84% of Goal</span>
    </div>
    <div style="display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px;">
      <div><span style="font-size:20px;font-weight:900;color:var(--text);">8,420</span> <span style="font-size:10px;color:var(--text-dim);">/ 10,000 steps</span></div>
      <span style="font-size:10px;color:var(--text-dim);">6.2 km · 420 kcal</span>
    </div>
    <div style="height:6px;background:var(--border);border-radius:3px;overflow:hidden;">
      <div style="width:84%;height:100%;background:var(--accent);box-shadow:0 0 6px var(--accent);"></div>
    </div>
  </div>

  <!-- 2. Workouts Volume -->
  <div class="card" style="margin-bottom:10px;cursor:pointer;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
      <div style="display:flex;align-items:center;gap:8px;">
        <div style="padding:4px 6px;border-radius:8px;background:rgba(255,107,53,0.18);color:#FF6B35;font-size:14px;"><i class="ti ti-barbell"></i></div>
        <span style="font-size:12px;font-weight:800;color:var(--text);">Workouts Volume</span>
      </div>
      <span style="font-size:10px;font-weight:700;color:#FF6B35;">Logs</span>
    </div>
    <div class="stat3">
      <div><div class="l">Tonnage (Wk)</div><div class="n" style="font-size:12px;">28,450 kg</div></div>
      <div><div class="l">Sets Logged</div><div class="n" style="font-size:12px;">48 sets</div></div>
      <div><div class="l">Active Time</div><div class="n" style="font-size:12px;">3h 45m</div></div>
    </div>
  </div>

  <!-- 3. Sleep & Autonomic Recovery -->
  <div class="card" style="margin-bottom:10px;cursor:pointer;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
      <div style="display:flex;align-items:center;gap:8px;">
        <div style="padding:4px 6px;border-radius:8px;background:rgba(180,99,255,0.18);color:#B463FF;font-size:14px;"><i class="ti ti-moon"></i></div>
        <span style="font-size:12px;font-weight:800;color:var(--text);">Sleep & Recovery</span>
      </div>
      <span style="font-size:10px;font-weight:800;color:var(--accent);">Recovery: 91%</span>
    </div>
    <div style="display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px;">
      <div><span style="font-size:18px;font-weight:900;color:var(--text);">7h 38m</span> <span style="font-size:10px;color:var(--text-dim);">Sleep duration</span></div>
      <span style="font-size:9px;color:var(--text-dim);">Deep: 1h 45m · REM: 2h 10m</span>
    </div>
  </div>

  <!-- 4. Weight Trend -->
  <div class="card" style="margin-bottom:10px;cursor:pointer;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
      <div style="display:flex;align-items:center;gap:8px;">
        <div style="padding:4px 6px;border-radius:8px;background:rgba(0,210,180,0.18);color:#00D2B4;font-size:14px;"><i class="ti ti-scale"></i></div>
        <span style="font-size:12px;font-weight:800;color:var(--text);">Weight Trend (kg)</span>
      </div>
      <span style="font-size:10px;font-weight:800;color:var(--accent);">-1.4 kg (30d)</span>
    </div>
    <div style="display:flex;justify-content:space-between;align-items:baseline;">
      <div><span style="font-size:18px;font-weight:900;color:var(--text);">78.4</span> <span style="font-size:10px;color:var(--text-dim);">kg · Goal: 76.0 kg</span></div>
      <span style="font-size:9px;color:var(--text-dim);">OLS: -0.35 kg/wk</span>
    </div>
  </div>

  <!-- 5. Energy Burned -->
  <div class="card" style="margin-bottom:10px;cursor:pointer;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
      <div style="display:flex;align-items:center;gap:8px;">
        <div style="padding:4px 6px;border-radius:8px;background:rgba(255,190,0,0.18);color:#FFBE00;font-size:14px;"><i class="ti ti-flame"></i></div>
        <span style="font-size:12px;font-weight:800;color:var(--text);">Energy Burned (Kcal)</span>
      </div>
      <span style="font-size:10px;font-weight:700;color:#FFBE00;">Active: 790 kcal</span>
    </div>
    <div style="display:flex;justify-content:space-between;align-items:baseline;">
      <span style="font-size:18px;font-weight:900;color:var(--text);">2,640</span> <span style="font-size:10px;color:var(--text-dim);">kcal total · Deficit: -270 kcal</span>
    </div>
  </div>

  <div class="tabbar">
    <div class="tab"><i class="ti ti-bolt"></i>Today</div>
    <div class="tab"><i class="ti ti-barbell"></i>Train</div>
    <div class="tab active"><i class="ti ti-activity"></i>Activity</div>
    <div class="tab"><i class="ti ti-user"></i>Profile</div>
  </div>
</div></div>

<!-- 16. AI Coach Screen -->
<div class="phone"><div class="screen bg-focus" style="padding-bottom:12px;">
  <div class="topbar">
    <div class="icon-btn"><i class="ti ti-arrow-left"></i></div>
    <div class="center"><div style="font-size:13px;font-weight:700;color:var(--text);">Kinetic Coach</div><div style="font-size:9px;color:var(--accent);">AI Health Copilot</div></div>
    <div class="icon-btn"><i class="ti ti-dots"></i></div>
  </div>
  <div class="chat-col">
    <div class="chat-bubble bot">HRV readiness is 89 ms (high). Optimal state for heavy compound lifting.</div>
    <div class="chat-bubble bot">Hey Alex, I suggest proceeding with Chest Day Heavy. 4x8 on Bench Press at 85 kg.<br><span class="chat-cta"><i class="ti ti-player-play"></i>Start workout</span></div>
    <div class="chat-bubble user">Should I add drop sets today?</div>
    <div class="chat-bubble bot">Recovery score allows 1 back-off set at 65 kg to failure. Avoid excessive fatigue before tomorrow's deadlifts.</div>
  </div>
  <div class="pill-row" style="margin-top:6px;"><span class="pill on">Start workout</span><span class="pill">Diet advice</span><span class="pill">Rest check</span></div>
  <div class="chat-input"><input placeholder="Ask your coach..." style="background:none;border:none;color:var(--text);font-size:11px;outline:none;width:100%;"><div class="send-btn"><i class="ti ti-arrow-up"></i></div></div>
</div></div>

</body>
</html>"""

pathlib.Path('app_mockup.html').write_text(html_content, encoding='utf-8')
pathlib.Path('C:/Users/mohdm/.gemini/antigravity-ide/brain/b71317a1-a90e-4dc4-8f3a-f568d5691d70/app_mockup.html').write_text(html_content, encoding='utf-8')
print('Updated app_mockup.html with all 11 photography assets!')

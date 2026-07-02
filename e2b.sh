#!/bin/bash
# E2B VPS — Made By NafiGamer
cd "$(dirname "$0")"

R='\033[91m' G='\033[92m' Y='\033[93m' C='\033[96m' W='\033[97m' D='\033[2m' B='\033[1m' X='\033[0m'

if ! command -v python3 &>/dev/null; then
    echo -e "${R}✗ python3 not found${X}"
    echo -e "  Install: ${C}sudo apt install python3 python3-pip${X}"
    exit 1
fi

if ! python3 -c "import e2b" 2>/dev/null; then
    echo -e "${Y}! e2b SDK not found${X}"
    echo
    echo -e "  Install with:"
    echo -e "    ${C}pip install e2b${X}"
    echo -e "    ${C}pip3 install e2b${X}"
    echo
    read -p "  Install now? (y/N): " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        echo
        echo -e "${C}› installing e2b...${X}"
        pip3 install e2b 2>/dev/null || pip install e2b 2>/dev/null || {
            echo -e "${R}✗ install failed${X}"
            echo -e "  Run manually: ${C}pip install e2b${X}"
            exit 1
        }
        echo -e "${G}✓ e2b installed${X}"
        sleep 1
    else
        exit 1
    fi
fi                                                                                                                                                                  export E2B_API_KEY="${E2B_API_KEY}"

TMP=$(mktemp /tmp/e2b_XXXXXX.py)
trap 'rm -f "$TMP"' EXIT

cat > "$TMP" << 'PYEOF'
from __future__ import annotations
import base64, getpass, json, os, shlex, shutil, signal, subprocess, sys, time
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
try:
    from e2b import Sandbox
except Exception:
    Sandbox = None
APP_DIR = Path.home() / ".e2b_ssh"
CONFIG_FILE = APP_DIR / "config.json"
DEFAULT_CWD = "/home/user"
OWNER = "NafiGamer"
class C:
    reset="\033[0m"; bold="\033[1m"; dim="\033[2m"; red="\033[91m"; green="\033[92m"
    yellow="\033[93m"; blue="\033[94m"; magenta="\033[95m"; cyan="\033[96m"; white="\033[97m"
def color(t, c):
    return t if os.environ.get("NO_COLOR") else c + t + C.reset
def _print(p, c, m):
    codes = {"red":"\033[91m","green":"\033[92m","yellow":"\033[93m","cyan":"\033[96m","dim":"\033[2m","bold":"\033[1m","reset":"\033[0m"}
    col = codes.get(c, "")
    print(f"{col}{p}{C.reset}{m}" if not os.environ.get("NO_COLOR") else f"{p}{m}")
def ok(m): _print("✓ ", "green", m)
def warn(m): _print("! ", "yellow", m)
def bad(m): _print("✗ ", "red", m)
def info(m): _print("› ", "cyan", m)
def pause():
    try: input(color("  Press Enter to continue...", C.dim))
    except (EOFError, KeyboardInterrupt): pass
def clear_screen(): os.system("cls" if os.name == "nt" else "clear")
def banner():
    clear_screen()
    print(f"""{C.cyan}{C.bold}
  ('-. .-.   ('-.
  ( OO )  / _(  OO)
 ,--. ,--.(,------.,--.      ,--.      .-'),-----.
 |  | |  | |  .---'|  |.-')  |  |.-') ( OO'  .-.  '
 |   .|  | |  |    |  | OO ) |  | OO )/   |  | |  |
 |       |(|  '--. |  |`-' | |  |`-' |\\_) |  |\\|  |
 |  .-.  | |  .--'(|  '---.'(|  '---.'  \\ |  | |  |
 |  | |  | |  `---.|      |  |      |    `'  '-'  '
 `--' `--' `------'`------'  `------'      `-----'{C.reset}
  {C.dim}Made By {OWNER}{C.reset}
""")
def load_config():
    try: return json.loads(CONFIG_FILE.read_text())
    except: return {}
def save_config(cfg):
    APP_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2))
    try: CONFIG_FILE.chmod(0o600)
    except: pass
def require_sdk():
    if Sandbox is not None: return True
    bad("e2b SDK not installed")
    print()
    info("Install it:")
    print(f"    {C.cyan}pip install e2b{C.reset}")
    print(f"    {C.cyan}pip3 install e2b{C.reset}")
    return False
def setup_api_key():
    cfg = load_config()
    if cfg.get("api_key"):
        try: return base64.b64decode(cfg["api_key"].encode()).decode()
        except: return str(cfg["api_key"])
    if os.environ.get("E2B_API_KEY"):
        cfg["api_key"] = base64.b64encode(os.environ["E2B_API_KEY"].encode()).decode()
        save_config(cfg)
        return os.environ["E2B_API_KEY"]
    banner()
    warn("No API key found")
    print("Paste your E2B API key.")
    try: key = getpass.getpass("E2B API key: ").strip()
    except (EOFError, KeyboardInterrupt): return ""
    if not key: bad("API key required"); return ""
    cfg["api_key"] = base64.b64encode(key.encode()).decode()
    save_config(cfg)
    ok("API key saved.")
    return key
def get_api_key():
    cfg = load_config()
    raw = cfg.get("api_key", "")
    if raw:
        try: return base64.b64decode(raw.encode()).decode()
        except: return raw
    return raw
def change_api_key():
    cfg = load_config()
    current = get_api_key()
    banner()
    print(color("╔══════════════════════════════════════════════════════════════════╗", C.cyan))
    print(color("║                   API KEY MANAGEMENT                            ║", C.bold + C.cyan))
    print(color("╚══════════════════════════════════════════════════════════════════╝", C.cyan))
    print()
    if current:
        masked = current[:8] + "•" * 12 + current[-4:] if len(current) > 12 else "•" * len(current)
        print(color("  Current key:", C.bold))
        print(f"  {color(masked, C.dim)}")
        print()
    else:
        warn("No API key currently set.")
        print()
    print("Options:")
    print(f"  {color('1', C.cyan)}) update key")
    print(f"  {color('2', C.cyan)}) view full key")
    print(f"  {color('3', C.cyan)}) clear key")
    print(f"  {color('4', C.cyan)}) test key")
    print(f"  {color('0', C.cyan)}) back")
    print()
    try:
        choice = input(color("  Choose: ", C.bold)).strip()
    except (EOFError, KeyboardInterrupt): return
    if choice == "0" or not choice: return
    elif choice == "1":
        print()
        print(color("  Paste your E2B API key (empty to cancel):", C.dim))
        try: new_key = getpass.getpass("  E2B API key: ").strip()
        except (EOFError, KeyboardInterrupt): warn("cancelled"); return
        if not new_key: warn("cancelled"); return
        print()
        info("validating key...")
        try:
            os.environ["E2B_API_KEY"] = new_key
            from e2b import Sandbox as S
            boxes = []
            paginator = S.list()
            while paginator.has_next: boxes.extend(paginator.next_items())
            ok(f"key valid — {len(boxes)} sandbox(es) found")
        except Exception as e:
            warn(f"could not validate: {e}")
            try: confirm = input("  Save anyway? (y/N): ").strip().lower()
            except (EOFError, KeyboardInterrupt): warn("cancelled"); return
            if confirm != "y": warn("cancelled"); return
        cfg["api_key"] = base64.b64encode(new_key.encode()).decode()
        save_config(cfg)
        ok("API key updated successfully")
    elif choice == "2":
        if not current: warn("no key set")
        else: print(); print(color("  Your full API key:", C.bold)); print(f"  {current}"); print()
    elif choice == "3":
        try: confirm = input("  Clear API key permanently? (y/N): ").strip().lower()
        except (EOFError, KeyboardInterrupt): warn("cancelled"); return
        if confirm == "y": cfg.pop("api_key", None); save_config(cfg); ok("API key cleared")
        else: warn("cancelled")
    elif choice == "4":
        if not current: warn("no key to test"); return
        print()
        info("testing key...")
        try:
            os.environ["E2B_API_KEY"] = current
            from e2b import Sandbox as S
            paginator = S.list()
            count = 0
            while paginator.has_next: count += len(paginator.next_items())
            ok(f"key working — {count} sandbox(es) accessible")
        except Exception as e: bad(f"key failed: {e}")
    else: warn("invalid choice")
def sid_of(sb): return str(getattr(sb, "sandbox_id", None) or getattr(sb, "id", None) or "unknown")
def val(obj, k, d=""):
    return obj.get(k, d) if isinstance(obj, dict) else getattr(obj, k, d)
def connect(api_key, sandbox_id=None):
    if not require_sdk(): return None
    sid = sandbox_id or get_current()
    if not sid:
        print(color("  Enter sandbox ID:", C.dim))
        try: sid = input(color("  › ", C.bold)).strip()
        except (EOFError, KeyboardInterrupt): return None
    if not sid: return None
    info(f"connecting to {sid[:16]}...")
    os.environ["E2B_API_KEY"] = api_key
    sb = Sandbox.connect(sid)
    set_current(sid_of(sb))
    ok("connected")
    return sb
def set_current(sid):
    cfg = load_config()
    cfg["current_sandbox"] = sid
    cfg.setdefault("cwd", {})[sid] = cfg.setdefault("cwd", {}).get(sid, DEFAULT_CWD)
    save_config(cfg)
def get_current(): return str(load_config().get("current_sandbox", ""))
def get_cwd(sid): return str(load_config().get("cwd", {}).get(sid, DEFAULT_CWD))
def set_cwd(sid, cwd):
    cfg = load_config()
    cfg.setdefault("cwd", {})[sid] = cwd
    save_config(cfg)
def ensure_template(api_key):
    os.environ["E2B_API_KEY"] = api_key
    try:
        from e2b import Template, default_build_logger
        try:
            test = Sandbox.create(template="vps-max", timeout=5)
            test.kill()
            return "vps-max"
        except:
            info("template vps-max not found, building...")
        template = Template().from_base_image().set_start_cmd("sleep infinity", None)
        Template.build(template, "vps-max", cpu_count=8, memory_mb=8192, on_build_logs=default_build_logger())
        ok("template vps-max built (8 CPU, 8GB RAM)")
        return "vps-max"
    except Exception as e:
        bad(f"failed to build template: {e}")
        return "base"
def create_sandbox(api_key):
    if not require_sdk(): return None
    os.environ["E2B_API_KEY"] = api_key
    template = ensure_template(api_key)
    print()
    info(f"creating sandbox with template={template} ...")
    sb = Sandbox.create(template=template, timeout=0)
    set_current(sid_of(sb))
    print()
    ok("sandbox created successfully")
    print()
    print(f"    {color('ID:', C.bold):<16} {sid_of(sb)}")
    print(f"    {color('Template:', C.bold):<16} {template}")
    print(f"    {color('Timeout:', C.bold):<16} unlimited")
    print()
    show_info(sb)
    return sb
def list_sandboxes(api_key):
    if not require_sdk(): return []
    os.environ["E2B_API_KEY"] = api_key
    info("fetching sandboxes...")
    try:
        paginator = Sandbox.list()
        boxes = []
        while paginator.has_next: items = paginator.next_items(); boxes.extend(items)
    except: boxes = []
    if not boxes: warn("No sandboxes found"); return []
    print()
    print(color("  ┌──────────────────────────────────────────────────────────────┐", C.cyan))
    print(color("  │", C.cyan) + color("                    AVAILABLE SANDBOXES", C.bold + C.white) + color("                       │", C.cyan))
    print(color("  └──────────────────────────────────────────────────────────────┘", C.cyan))
    print()
    print(color("    #    Sandbox ID                          Status       Template", C.bold))
    print(color("    ────────────────────────────────────────────────────────────────", C.dim))
    for i, sb in enumerate(boxes, 1):
        try: inf = sb.get_info()
        except: inf = {}
        sid = sid_of(sb)
        status = str(val(inf, "state", "?")).ljust(12)
        template = str(val(inf, "template_id", ""))[:20]
        mark = color("*", C.green) if sid == get_current() else " "
        print(f"    {mark}{i:<5} {sid:<34} {status} {template}")
    print()
    return boxes
def choose_sandbox(api_key):
    boxes = list_sandboxes(api_key)
    if not boxes: return None
    print(color("  Enter sandbox # or paste full sandbox ID", C.dim))
    try: choice = input(color("  › ", C.bold)).strip()
    except (EOFError, KeyboardInterrupt): return None
    if not choice: return None
    if choice.isdigit():
        idx = int(choice) - 1
        if 0 <= idx < len(boxes):
            sid = sid_of(boxes[idx])
            set_current(sid)
            ok(f"selected sandbox {sid[:16]}...")
            return sid
    set_current(choice)
    ok(f"selected sandbox {choice[:16]}...")
    return choice
def show_info(sb):
    try: inf = sb.get_info()
    except Exception as e: bad(f"could not get info: {e}"); return
    print()
    print(color("  ┌──────────────────────────────────────────────────────────────┐", C.cyan))
    print(color("  │", C.cyan) + color("                    SANDBOX DETAILS", C.bold + C.white) + color("                         │", C.cyan))
    print(color("  └──────────────────────────────────────────────────────────────┘", C.cyan))
    print()
    for k in ["sandbox_id", "template_id", "name", "state", "started_at", "end_at", "cpu_count", "memory_mb", "template"]:
        v = val(inf, k, None)
        if v: print(f"    {color(k + ':', C.bold):<20} {v}")
    print()
def action(api_key, name):
    sb = connect(api_key)
    if not sb: bad("no sandbox selected"); return
    sid = sid_of(sb)
    if name == "start":
        info(f"starting sandbox {sid[:16]}..."); sb.start(); ok("sandbox started")
    elif name == "stop":
        info(f"stopping sandbox {sid[:16]}..."); sb.stop(); ok("sandbox stopped")
    elif name == "delete":
        print()
        print(color("  ┌──────────────────────────────────────────────────────────────┐", C.red))
        print(color("  │", C.red) + color("                    ⚠  DELETE SANDBOX", C.bold + C.white) + color("                        │", C.red))
        print(color("  └──────────────────────────────────────────────────────────────┘", C.red))
        print()
        print(f"    Sandbox: {color(sid, C.yellow)}")
        print()
        try: confirm = input("    Type DELETE to confirm: ").strip()
        except (EOFError, KeyboardInterrupt): warn("cancelled"); return
        if confirm != "DELETE": warn("cancelled"); return
        sb.kill()
        ok("sandbox deleted permanently")
        cfg = load_config()
        if cfg.get("current_sandbox") == sid: cfg.pop("current_sandbox", None)
        cfg.get("cwd", {}).pop(sid, None)
        save_config(cfg)
    elif name == "pause":
        info(f"pausing sandbox {sid[:16]}..."); sb.pause(); ok("sandbox paused")
    elif name == "resume":
        info(f"resuming sandbox {sid[:16]}..."); sb.resume(); ok("sandbox resumed")
class VPSTerminal:
    def __init__(self, sb, api_key):
        self.sb = sb; self.api_key = api_key; self.sid = sid_of(sb)
        self.cwd = get_cwd(self.sid); self.running = True
        self._cmd_history = []; self._history_file = APP_DIR / "history" / self.sid; self._load_history()
    def _load_history(self):
        try:
            if self._history_file.exists(): self._cmd_history = self._history_file.read_text().strip().split("\n")
        except: pass
    def _save_history(self, cmd):
        try:
            self._cmd_history.append(cmd); self._history_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self._history_file, "a") as f: f.write(cmd + "\n")
        except: pass
    def run(self): banner(); info(f"Connecting to sandbox {self.sid} ..."); self._interactive_loop()
    def _run_cmd(self, command, timeout=300):
        marker = "__E2B_END__"; safe_cwd = shlex.quote(self.cwd)
        wrapped = f"cd {safe_cwd} 2>/dev/null || cd /home/user 2>/dev/null || cd /\n{command}\n__e2b_ret=$?\nprintf '\\n{marker}:%s:%d\\n' \"$PWD\" $__e2b_ret\nexit $__e2b_ret\n"
        res = self.sb.commands.run(wrapped, timeout=timeout)
        stdout = str(getattr(res, "stdout", "") or ""); stderr = str(getattr(res, "stderr", "") or "")
        code_raw = getattr(res, "exit_code", 0); code = int(code_raw if code_raw is not None else 0)
        if marker in stdout:
            before, _, after = stdout.rpartition(marker + ":")
            stdout = before.rstrip("\n") + ("\n" if before.rstrip("\n") else "")
            parts = after.splitlines()[0].split(":")
            if len(parts) >= 2: self.cwd = parts[0].strip() or self.cwd; code = int(parts[1]) if parts[1].strip().isdigit() else code
        set_cwd(self.sid, self.cwd); return stdout, stderr, code
    def _interactive_loop(self):
        clear_screen(); ok(f"Terminal connected to {self.sid}")
        print(color("Type 'help' for commands, 'exit' to close.\n", C.dim))
        signal.signal(signal.SIGINT, self._sigint_handler)
        while self.running:
            try: cmd = input(f"{C.cyan}{C.bold}{self.sid[:10]}:{self.cwd}{C.reset}$ ")
            except (KeyboardInterrupt, EOFError): print(); break
            cmd = cmd.strip()
            if not cmd: continue
            if cmd in {"exit", "quit"}: break
            if cmd == "help": self._terminal_help(); continue
            if cmd == "clear": clear_screen(); continue
            if cmd == "info": show_info(self.sb); continue
            if cmd.startswith("files"):
                parts = shlex.split(cmd); path = parts[1] if len(parts) > 1 else self.cwd
                try:
                    entries = self.sb.files.list(path)
                    print(color(f"\n  Directory: {path}\n", C.bold))
                    for f in entries:
                        name = val(f, "name", str(f)); size = str(val(f, "size", "?"))
                        print(f"  {color(name, C.cyan):<40} {size:>10} bytes")
                    print()
                except Exception as e: bad(str(e))
                continue
            if cmd.startswith("cat "):
                path = shlex.split(cmd)[1]
                try: print(self.sb.files.read(path))
                except Exception as e: bad(str(e))
                continue
            if cmd.startswith("upload "):
                _, local, remote = shlex.split(cmd)
                try: data = Path(local).read_text(errors="replace"); self.sb.files.write(remote, data); ok(f"uploaded {local} -> {remote}")
                except Exception as e: bad(str(e))
                continue
            if cmd.startswith("download "):
                _, remote, local = shlex.split(cmd)
                try: data = self.sb.files.read(remote); Path(local).write_text(str(data)); ok(f"downloaded {remote} -> {local}")
                except Exception as e: bad(str(e))
                continue
            if cmd.startswith("preview"):
                parts = shlex.split(cmd); port = int(parts[1]) if len(parts) > 1 else 8000
                try:
                    inf = self.sb.get_info(); host = str(val(inf, "sandbox_domain", "")).rstrip("/")
                    if host: ok(f"Preview URL: https://{port}-{host}")
                    else: warn("No public URL available")
                except: warn("No public URL available")
                continue
            if cmd == "metrics":
                try:
                    out, _, _ = self._run_cmd("top -bn1 | head -5; echo '---'; free -h; echo '---'; df -h /")
                    print()
                    print(color("  ┌──────────────────────────────────────────────────────────────┐", C.cyan))
                    print(color("  │", C.cyan) + color("                    SYSTEM METRICS", C.bold + C.white) + color("                          │", C.cyan))
                    print(color("  └──────────────────────────────────────────────────────────────┘", C.cyan))
                    print(); print(out)
                except Exception as e: bad(str(e))
                continue
            if cmd == "history":
                for i, h in enumerate(self._cmd_history[-20:], 1): print(f"  {color(str(i), C.dim):>4}  {h}")
                continue
            if cmd == "delete":
                try: confirm = input(color("Delete sandbox permanently? type DELETE: ", C.red)).strip()
                except (EOFError, KeyboardInterrupt): warn("cancelled"); continue
                if confirm == "DELETE": self.sb.kill(); ok("deleted"); return
                warn("cancelled"); continue
            self._save_history(cmd); start = time.time()
            try:
                stdout, stderr, code = self._run_cmd(cmd)
                if stdout: print(stdout.rstrip("\n"))
                if stderr: print(color(stderr.rstrip("\n"), C.red), file=sys.stderr)
                elapsed = time.time() - start
                if code == 0: print(color(f"  exit {code} · {elapsed:.2f}s", C.dim))
                else: print(color(f"  exit {code} · {elapsed:.2f}s", C.red))
            except Exception as e: bad(str(e))
        warn("Terminal closed. Sandbox is still running.")
    def _terminal_help(self):
        print()
        print(color("  ┌──────────────────────────────────────────────────────────────┐", C.cyan))
        print(color("  │", C.cyan) + color("                    TERMINAL COMMANDS", C.bold + C.white) + color("                        │", C.cyan))
        print(color("  └──────────────────────────────────────────────────────────────┘", C.cyan))
        print()
        print(color("    Shell", C.bold + C.white))
        print(f"      {color('help', C.cyan):<24} show this help")
        print(f"      {color('exit / quit', C.cyan):<24} close terminal")
        print(f"      {color('clear', C.cyan):<24} clear screen")
        print(f"      {color('<any command>', C.cyan):<24} run shell command")
        print()
        print(color("    Sandbox", C.bold + C.white))
        print(f"      {color('info', C.cyan):<24} show sandbox details")
        print(f"      {color('metrics', C.cyan):<24} live CPU, memory, disk")
        print(f"      {color('preview [port]', C.cyan):<24} show public URL")
        print()
        print(color("    Files", C.bold + C.white))
        print(f"      {color('files [path]', C.cyan):<24} list directory")
        print(f"      {color('cat <file>', C.cyan):<24} read file contents")
        print(f"      {color('upload <local> <rem>', C.cyan):<24} upload file")
        print(f"      {color('download <rem> <local>', C.cyan):<24} download file")
        print()
        print(color("    History", C.bold + C.white))
        print(f"      {color('history', C.cyan):<24} show command history")
        print(f"      {color('delete', C.cyan):<24} delete sandbox & exit")
        print()
    def _sigint_handler(self, sig, frame): print("^C")
def menu(api_key):
    while True:
        banner(); current = get_current()
        print(color("┌─────────────────────────────────────────────────────────────────┐", C.dim))
        print(color("│", C.dim) + color("  Active Sandbox: ", C.bold) + (color(current, C.cyan) if current else color("none", C.yellow)) + color(" " * (44 - len(current or "none")), "") + color("│", C.dim))
        print(color("└─────────────────────────────────────────────────────────────────┘", C.dim))
        print()
        print(color("  Core Operations", C.bold + C.white))
        print(f"    {color('1', C.cyan)}  create sandbox")
        print(f"    {color('2', C.cyan)}  stop sandbox")
        print(f"    {color('3', C.cyan)}  start sandbox")
        print(f"    {color('4', C.cyan)}  delete sandbox")
        print(f"    {color('5', C.cyan)}  launch terminal")
        print()
        print(color("  Management", C.bold + C.white))
        print(f"    {color('6', C.cyan)}  list / select sandbox")
        print(f"    {color('7', C.cyan)}  sandbox info")
        print(f"    {color('8', C.cyan)}  pause sandbox")
        print(f"    {color('9', C.cyan)}  resume sandbox")
        print()
        print(color("  Settings", C.bold + C.white))
        print(f"    {color('0', C.cyan)}  exit")
        print(f"    {color('k', C.cyan)}  manage API key")
        print()
        try:
            choice = input(color("  › ", C.bold)).strip().lower()
        except (EOFError, KeyboardInterrupt):
            print(); print(); ok(f"bye {OWNER}"); print(); break
        if not choice: continue
        try:
            if choice == "1": create_sandbox(api_key); pause()
            elif choice == "2": action(api_key, "stop"); pause()
            elif choice == "3": action(api_key, "start"); pause()
            elif choice == "4": action(api_key, "delete"); pause()
            elif choice == "5":
                sb = connect(api_key)
                if sb: VPSTerminal(sb, api_key).run()
                pause()
            elif choice == "6": choose_sandbox(api_key); pause()
            elif choice == "7":
                sb = connect(api_key)
                if sb: show_info(sb)
                pause()
            elif choice == "8": action(api_key, "pause"); pause()
            elif choice == "9": action(api_key, "resume"); pause()
            elif choice in ("0", "exit", "q"):
                print(); ok(f"bye {OWNER}"); print(); break
            elif choice == "k": change_api_key(); api_key = get_api_key(); pause()
            else: warn("invalid choice"); time.sleep(0.8)
        except (EOFError, KeyboardInterrupt):
            print(); print(); ok(f"bye {OWNER}"); print(); break
        except Exception as e: bad(str(e)); pause()
def main():
    if not require_sdk(): return
    api_key = get_api_key()
    if not api_key: api_key = setup_api_key()
    if not api_key: bad("no API key — cannot start"); return
    menu(api_key)
if __name__ == "__main__": main()
PYEOF

python3 "$TMP"

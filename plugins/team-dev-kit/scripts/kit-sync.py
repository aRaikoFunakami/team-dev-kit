#!/usr/bin/env python3
# 概要: team-dev-kit の Plane B 同期エンジン(v2)。framework(共通・触禁止)と config(プロジェクト設定)を
#       物理ファイル単位で分離して扱う。kit-init/update/contribute/doctor skill から明示的に呼ばれる。
#   framework … consumer に commit するが編集しない。update が常に「置換」する(3-way 不要)。
#               配置先: .team-dev-kit/contract.md, .team-dev-kit/base.gitleaks.toml, .githooks/pre-commit
#   config    … プロジェクトが書く。init で雛形を1回だけ置き、update は触らない(install-once)。
#               配置先: AGENTS.md(@import で contract を取り込む), .gitleaks.toml(base を extend), .github/*
# provenance: 消費側ルートの .team-dev-kit.lock(version + framework hash + config 一覧)。
# 注意: settings.json(plugin 有効化)は管理対象外(marketplace + enabledPlugins で行う)。
import sys, os, json, hashlib, subprocess, argparse, difflib

LOCK = ".team-dev-kit.lock"
MARKETPLACE = "aRaikoFunakami/team-dev-kit"

# framework: <plugin 相対 src> -> <consumer 配置先>
FRAMEWORK = {
    "framework/contract.md":       ".team-dev-kit/contract.md",
    "framework/base.gitleaks.toml": ".team-dev-kit/base.gitleaks.toml",
    "framework/pre-commit":        ".githooks/pre-commit",
}
EXEC_DEST = {".githooks/pre-commit"}
# config-starters の第1パス要素のリネーム(consumer 側へ)
CONFIG_RENAME = {"gitleaks.toml": ".gitleaks.toml", "github": ".github"}

def plugin_root():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def kit_version():
    with open(os.path.join(plugin_root(), ".claude-plugin", "plugin.json"), encoding="utf-8") as f:
        return json.load(f).get("version", "0.0.0")

def sha(text): return hashlib.sha256(text.encode("utf-8")).hexdigest()

def read(p):
    with open(p, encoding="utf-8") as f: return f.read()

def write(p, text):
    os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
    with open(p, "w", encoding="utf-8") as f: f.write(text)

def fw_map():
    """framework: consumer 配置先 -> src 絶対パス"""
    pr = plugin_root()
    return {dest: os.path.join(pr, src) for src, dest in FRAMEWORK.items()}

def cfg_map():
    """config-starters を走査し consumer 配置先 -> src 絶対パス を返す。"""
    base = os.path.join(plugin_root(), "config-starters")
    out = {}
    for root, _, files in os.walk(base):
        for fn in files:
            ab = os.path.join(root, fn)
            rel = os.path.relpath(ab, base)
            parts = rel.split(os.sep)
            parts[0] = CONFIG_RENAME.get(parts[0], parts[0])
            out["/".join(parts)] = ab
    return out

def lock_path(t): return os.path.join(t, LOCK)
def load_lock(t):
    p = lock_path(t)
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else None

def git(t, *a, check=True):
    return subprocess.run(["git", "-C", t, *a], capture_output=True, text=True, check=check)
def is_git(t):
    return git(t, "rev-parse", "--is-inside-work-tree", check=False).returncode == 0

# ---------------- init ----------------
def cmd_init(args):
    t = args.target
    if not is_git(t):
        print("✋ git リポジトリではありません。先に git init してください。", file=sys.stderr); return 1
    dry, force = args.dry_run, args.force
    print(f"== kit-init (v{kit_version()}) target={t} ==" + ("  (dry-run)" if dry else ""))
    lock = {"version": kit_version(), "marketplace": MARKETPLACE, "framework": {}, "config": []}

    print(" [framework] 共通・置換管理")
    for dest, src in sorted(fw_map().items()):
        text = read(src)
        if not dry:
            write(os.path.join(t, dest), text)
            if dest in EXEC_DEST: os.chmod(os.path.join(t, dest), 0o755)
        lock["framework"][dest] = {"sha": sha(text)}
        print(f"   write {dest}" + (" (+x)" if dest in EXEC_DEST else ""))

    print(" [config] プロジェクト設定・install-once")
    for dest, src in sorted(cfg_map().items()):
        d = os.path.join(t, dest)
        if os.path.exists(d) and not force:
            print(f"   skip (exists) {dest}")
        else:
            if not dry: write(d, read(src))
            print(f"   write {dest}")
        lock["config"].append(dest)

    cur = git(t, "config", "--local", "core.hooksPath", check=False).stdout.strip()
    if not cur:
        if not dry: git(t, "config", "--local", "core.hooksPath", ".githooks")
        print("   git config core.hooksPath .githooks")
    elif cur == ".githooks":
        print("   core.hooksPath = .githooks (already)")
    else:
        print(f"   ⚠ core.hooksPath は既に '{cur}'。上書きしません。.githooks/pre-commit を手動統合してください。")

    if not dry: write(lock_path(t), json.dumps(lock, ensure_ascii=False, indent=2) + "\n")
    print(f"   {'(dry) ' if dry else ''}write {LOCK}")
    print("✅ dry-run 完了" if dry else "✅ kit-init 完了。AGENTS.md / .gitleaks.toml を確認し commit。")
    return 0

# ---------------- update ----------------
def cmd_update(args):
    t = args.target
    lock = load_lock(t)
    if not lock:
        print(f"✋ {LOCK} なし。先に /kit-init。", file=sys.stderr); return 1
    old, new = lock.get("version"), kit_version()
    dry, force = args.dry_run, args.force
    print(f"== kit-update {old} -> {new} target={t} ==" + ("  (dry-run)" if dry else ""))
    if old == new and not force:
        print("  既に最新(--force で再同期)"); return 0

    fw_lock = lock.get("framework", {})
    replaced, drift_skipped = [], []
    print(" [framework] 置換")
    for dest, src in sorted(fw_map().items()):
        text = read(src); d = os.path.join(t, dest)
        prev = fw_lock.get(dest, {}).get("sha")
        if os.path.exists(d) and prev and sha(read(d)) != prev and not force:
            print(f"   ⚠ drift skip {dest}(ローカル編集あり。--force で置換 / 改善なら /kit-contribute)")
            drift_skipped.append(dest)
        else:
            if not dry:
                write(d, text)
                if dest in EXEC_DEST: os.chmod(d, 0o755)
            print(f"   replace {dest}"); replaced.append(dest)
        fw_lock[dest] = {"sha": sha(text)}

    print(" [config] install-once(既存は触らない・新規 starter のみ追加)")
    cfg = set(lock.get("config", []))
    for dest, src in sorted(cfg_map().items()):
        d = os.path.join(t, dest)
        if not os.path.exists(d):
            if not dry: write(d, read(src))
            print(f"   add {dest}(新規 starter)")
        cfg.add(dest)

    if not dry:
        lock["version"] = new; lock["framework"] = fw_lock; lock["config"] = sorted(cfg)
        write(lock_path(t), json.dumps(lock, ensure_ascii=False, indent=2) + "\n")
    print(f"  置換 {len(replaced)} 件" + (f" / drift skip {len(drift_skipped)} 件" if drift_skipped else ""))
    if drift_skipped:
        print("⚠ drift により未更新あり。内容確認のうえ --force か /kit-contribute。")
    print("✅ dry-run 完了" if dry else "✅ kit-update 完了。差分を feature ブランチで PR。")
    return 0

# ---------------- doctor ----------------
def cmd_doctor(args):
    t = args.target
    print(f"== kit-doctor target={t} ==")
    problems = 0
    import shutil
    for tool in ("gitleaks", "git", "python3"):
        ok = shutil.which(tool) is not None
        print(f"  dep {tool}: {'ok' if ok else 'MISSING'}")
        if not ok and tool != "python3": problems += 1
    if not is_git(t): print("  ✋ git リポジトリでない"); return 1
    cur = git(t, "config", "--local", "core.hooksPath", check=False).stdout.strip()
    print(f"  core.hooksPath: {cur or '(unset)'}" + ("" if cur == ".githooks" else "  ⚠ .githooks 推奨"))
    if cur != ".githooks": problems += 1
    lock = load_lock(t)
    if not lock:
        print(f"  ✋ {LOCK} なし。/kit-init 未実行。"); return 1
    print(f"  version lock={lock.get('version')} installed={kit_version()}"
          + ("  ⚠ /kit-update 検討" if lock.get("version") != kit_version() else ""))
    drifted = 0
    print("  [framework]")
    for dest, meta in sorted(lock.get("framework", {}).items()):
        d = os.path.join(t, dest)
        if not os.path.exists(d):
            print(f"   {dest}: MISSING"); problems += 1
        elif sha(read(d)) != meta.get("sha"):
            print(f"   {dest}: DRIFTED(編集禁止。/kit-update --force か /kit-contribute)"); drifted += 1
        else:
            print(f"   {dest}: ok")
    print("  [config] (プロジェクト所有。drift 判定しない)")
    for dest in sorted(lock.get("config", [])):
        print(f"   {dest}: {'present' if os.path.exists(os.path.join(t, dest)) else 'absent'}")
    if problems: print(f"⚠ 問題 {problems} 件")
    elif drifted: print(f"ℹ framework drift {drifted} 件(/kit-contribute 候補)。健全性は OK")
    else: print("✅ 健全")
    return 1 if problems else 0

# ---------------- contribute ----------------
def cmd_contribute(args):
    t = args.target
    lock = load_lock(t)
    if not lock:
        print(f"✋ {LOCK} なし。先に /kit-init。", file=sys.stderr); return 1
    print(f"== kit-contribute target={t} (kit v{kit_version()}) ==")
    dest_to_src = {dest: src for src, dest in FRAMEWORK.items()}  # 配置先 -> plugin 相対 src
    fwmap = fw_map()
    candidates = []
    for dest, meta in sorted(lock.get("framework", {}).items()):
        d = os.path.join(t, dest)
        if not os.path.exists(d) or sha(read(d)) == meta.get("sha"):
            continue  # 改変なし
        candidates.append(dest)
        diff = difflib.unified_diff(
            read(fwmap[dest]).splitlines(), read(d).splitlines(),
            fromfile=f"kit/{dest_to_src[dest]}", tofile=f"local/{dest}", lineterm="")
        print(f"\n--- 候補: {dest} ---\n" + "\n".join(list(diff)[:40]))
    if not candidates:
        print("  framework に改変なし → 上流候補なし(config はプロジェクト固有のため対象外)"); return 0
    if args.staging:
        for dest in candidates:
            sp = os.path.join(args.staging, dest_to_src[dest])  # kit の framework/ レイアウトへ
            if args.apply: write(sp, read(os.path.join(t, dest)))
        print(f"\n  {'(dry) ' if not args.apply else ''}staged {len(candidates)} 件 -> {args.staging}/framework/ (--apply で書出し)")
    print(f"\n候補 {len(candidates)} 件: {', '.join(candidates)}")
    print("次: kit を fork/branch し staging を plugins/team-dev-kit/framework/ へ反映 → kit へ draft PR")
    return 0

def main():
    ap = argparse.ArgumentParser(prog="kit-sync.py")
    sub = ap.add_subparsers(dest="cmd", required=True)
    P = {}
    for name in ("init", "doctor", "update", "contribute"):
        sp = sub.add_parser(name)
        sp.add_argument("--dry-run", action="store_true")
        sp.add_argument("--force", action="store_true")
        sp.add_argument("--target", default=os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
        P[name] = sp
    P["contribute"].add_argument("--staging", default=None)
    P["contribute"].add_argument("--apply", action="store_true")
    args = ap.parse_args()
    return {"init": cmd_init, "doctor": cmd_doctor,
            "update": cmd_update, "contribute": cmd_contribute}[args.cmd](args)

if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
# 概要: team-dev-kit の Plane B(リポジトリに commit するファイル)同期エンジン。
#       kit-init/kit-update/kit-contribute/kit-doctor skill から明示的に呼ばれる。
#       テンプレの真実は同梱の templates/、バージョンは .claude-plugin/plugin.json。
#       消費側ルートに .team-dev-kit.lock(version + 管理ファイル hash)を置き、
#       provenance により drift 検出・3-way 更新・改善検出を可能にする。
# 使い方: kit-sync.py <init|doctor|update|contribute> [--dry-run] [--force] [--target DIR]
#   init     : テンプレを配置(非破壊・冪等) + lock 生成 + core.hooksPath 設定
#   doctor   : lock↔作業ツリーの drift・依存・git 設定を診断(read-only)
#   update   : 新バージョンのテンプレを 3-way merge で取り込み lock 更新 (M3)
#   contribute: 作業ツリーの改変を上流候補として抽出 (M4)
# 注意: settings.json(plugin 有効化)は管理対象外。それは marketplace+enabledPlugins で行う。
import sys, os, json, hashlib, subprocess, argparse, shutil

LOCK = ".team-dev-kit.lock"
MARKETPLACE = "aRaikoFunakami/team-dev-kit"
BLOCK_START = "<!-- team-dev-kit:start"
BLOCK_END = "<!-- team-dev-kit:end"
# policy: managed-block のファイルだけ列挙。残りは replace 既定。
BLOCK_FILES = {"AGENTS.md"}
EXEC_FILES = {".githooks/pre-commit"}

def plugin_root():
    # このスクリプトは <plugin>/scripts/kit-sync.py
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def kit_version():
    p = os.path.join(plugin_root(), ".claude-plugin", "plugin.json")
    with open(p, encoding="utf-8") as f:
        return json.load(f).get("version", "0.0.0")

def templates_dir():
    return os.path.join(plugin_root(), "templates")

def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()

def managed_files():
    """templates/ 配下を走査し、消費側 rel パス -> 絶対 src のマップを返す。"""
    base = templates_dir()
    out = {}
    for root, _, files in os.walk(base):
        for fn in files:
            ab = os.path.join(root, fn)
            rel = os.path.relpath(ab, base)
            out[rel] = ab
    return out

def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

def write(path, text):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)

def extract_block(text):
    """managed-block(マーカー含む)を抜き出す。無ければ None。"""
    lines = text.splitlines(keepends=True)
    s = e = None
    for i, ln in enumerate(lines):
        if s is None and BLOCK_START in ln:
            s = i
        elif s is not None and BLOCK_END in ln:
            e = i
            break
    if s is None or e is None:
        return None
    return "".join(lines[s:e + 1])

def apply_block(existing, template_text):
    """existing の managed-block を template の block で置換。無ければ追記。
    戻り値: (new_text, note)"""
    tpl_block = extract_block(template_text)
    if tpl_block is None:
        raise SystemExit("テンプレ AGENTS.md に managed-block マーカーがありません")
    cur_block = extract_block(existing)
    if cur_block is None:
        return existing.rstrip() + "\n\n" + tpl_block, "markers-missing-appended"
    return existing.replace(cur_block, tpl_block), "block-replaced"

def lock_path(target):
    return os.path.join(target, LOCK)

def load_lock(target):
    p = lock_path(target)
    if os.path.exists(p):
        return json.load(open(p, encoding="utf-8"))
    return None

def policy_of(rel):
    return "managed-block" if rel in BLOCK_FILES else "replace"

def managed_sha(rel, src):
    """lock に書く hash。managed-block は block 部分だけ、他は全体。"""
    text = read(src)
    if policy_of(rel) == "managed-block":
        b = extract_block(text)
        return sha(b if b is not None else text)
    return sha(text)

def consumer_block_or_full(rel, path):
    text = read(path)
    if policy_of(rel) == "managed-block":
        b = extract_block(text)
        return b if b is not None else text
    return text

# ---- git helpers ----
def git(target, *args, check=True):
    return subprocess.run(["git", "-C", target, *args],
                          capture_output=True, text=True, check=check)

def is_git(target):
    r = git(target, "rev-parse", "--is-inside-work-tree", check=False)
    return r.returncode == 0

# ---- subcommands ----
def cmd_init(args):
    target = args.target
    if not is_git(target):
        print("✋ git リポジトリではありません。先に git init してください。", file=sys.stderr)
        return 1
    dry, force = args.dry_run, args.force
    print(f"== kit-init (v{kit_version()}) target={target} ==")
    if dry: print("(dry-run)")
    files = managed_files()
    lock_managed = {}
    for rel in sorted(files):
        src = files[rel]
        dst = os.path.join(target, rel)
        pol = policy_of(rel)
        exists = os.path.exists(dst)
        if pol == "managed-block" and exists:
            new, note = apply_block(read(dst), read(src))
            if not dry:
                write(dst, new)
            print(f"  block: {rel} ({note})")
        elif exists and not force:
            print(f"  skip (exists): {rel}")
        else:
            if not dry:
                write(dst, read(src))
                if rel in EXEC_FILES:
                    os.chmod(dst, 0o755)
            print(f"  write: {rel}{' (+x)' if rel in EXEC_FILES else ''}")
        lock_managed[rel] = {"sha": managed_sha(rel, src), "policy": pol}

    # core.hooksPath
    cur = git(target, "config", "--local", "core.hooksPath", check=False).stdout.strip()
    if not cur:
        if not dry:
            git(target, "config", "--local", "core.hooksPath", ".githooks")
        print("  git config core.hooksPath .githooks")
    elif cur == ".githooks":
        print("  core.hooksPath = .githooks (already)")
    else:
        print(f"  ⚠ core.hooksPath は既に '{cur}'。上書きしません。.githooks/pre-commit を手動統合してください。")

    # lock
    lock = {"version": kit_version(), "marketplace": MARKETPLACE, "managed": lock_managed}
    if not dry:
        write(lock_path(target), json.dumps(lock, ensure_ascii=False, indent=2) + "\n")
    print(f"  {'(dry) ' if dry else ''}write {LOCK} (version {kit_version()}, {len(lock_managed)} files)")
    print("✅ dry-run 完了" if dry else "✅ kit-init 完了。次: AGENTS.md を確認し commit。")
    return 0

def cmd_doctor(args):
    target = args.target
    print(f"== kit-doctor target={target} ==")
    problems = 0
    # deps
    for tool in ("gitleaks", "python3", "git"):
        ok = shutil.which(tool) is not None
        print(f"  dep {tool}: {'ok' if ok else 'MISSING'}")
        if not ok and tool != "python3":
            problems += 1
    if not is_git(target):
        print("  ✋ git リポジトリでない"); return 1
    # hooksPath
    cur = git(target, "config", "--local", "core.hooksPath", check=False).stdout.strip()
    print(f"  core.hooksPath: {cur or '(unset)'}" + ("" if cur == ".githooks" else "  ⚠ .githooks 推奨"))
    if cur != ".githooks":
        problems += 1
    # lock + drift
    lock = load_lock(target)
    if not lock:
        print(f"  ✋ {LOCK} なし。/kit-init 未実行。"); return 1
    print(f"  kit version (lock): {lock.get('version')}  installed: {kit_version()}")
    if lock.get("version") != kit_version():
        print("  ⚠ バージョン差あり。/kit-update を検討。")
    drifted = 0
    for rel, meta in sorted(lock.get("managed", {}).items()):
        dst = os.path.join(target, rel)
        if not os.path.exists(dst):
            print(f"  drift {rel}: MISSING"); problems += 1; continue
        cur_sha = sha(consumer_block_or_full(rel, dst))
        if cur_sha == meta["sha"]:
            print(f"  drift {rel}: same")
        else:
            print(f"  drift {rel}: DRIFTED(local 改変)"); drifted += 1
    if problems:
        print(f"⚠ 問題 {problems} 件")
    elif drifted:
        print(f"ℹ drift {drifted} 件(意図的な上書き or /kit-contribute 候補)。健全性は OK")
    else:
        print("✅ 健全")
    return 1 if problems else 0

def cmd_update(args):
    print("kit-update は M3 で実装予定", file=sys.stderr); return 3

def cmd_contribute(args):
    print("kit-contribute は M4 で実装予定", file=sys.stderr); return 3

def main():
    ap = argparse.ArgumentParser(prog="kit-sync.py")
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("init", "doctor", "update", "contribute"):
        sp = sub.add_parser(name)
        sp.add_argument("--dry-run", action="store_true")
        sp.add_argument("--force", action="store_true")
        sp.add_argument("--target", default=os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
    args = ap.parse_args()
    return {"init": cmd_init, "doctor": cmd_doctor,
            "update": cmd_update, "contribute": cmd_contribute}[args.cmd](args)

if __name__ == "__main__":
    sys.exit(main())

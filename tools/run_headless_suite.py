#!/usr/bin/env python3
"""Run Cyber City Platformer's headless Godot validation suite.

The runner deliberately invokes production-facing test scripts one process at a
time. This makes failures attributable, gives every command a meaningful exit
code, and prevents one test's SceneTree or autoload state from masking another.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
ENGINE_ERROR_PREFIXES = ("SCRIPT ERROR:", "ERROR:")

TEST_GROUPS: dict[str, tuple[str, ...]] = {
    "import": ("@import",),
    "resource": (
        "tests/integration/CleanCloneGate.gd",
        "scripts/AssetRegistrySmokeTest.gd",
    ),
    "unit": (
        "tests/unit/StateSchemaTest.gd",
        "tests/integration/PlayerStateTest.gd",
    ),
    "systems": (
        "scripts/SystemsSmokeTest.gd",
        "scripts/GoalSmokeTest.gd",
        "scripts/BossSystemsSmokeTest.gd",
        "tests/integration/StageMechanicsTest.gd",
        "tests/integration/EncounterLifecycleTest.gd",
        "tests/integration/PerformanceBudgetTest.gd",
    ),
    "campaign": (
        "scripts/CampaignSceneSmokeTest.gd",
        "tests/campaign/CampaignRuntimeTest.gd",
        "tests/campaign/CampaignContentTest.gd",
        "tests/campaign/CampaignTraversalTest.gd",
    ),
    "shell": (
        "tests/integration/SaveSettingsTest.gd",
        "tests/integration/ShellFlowTest.gd",
        "tests/integration/MissingAudioFallbackTest.gd",
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--godot",
        default=os.environ.get("GODOT_BIN", "godot"),
        help="Godot executable (default: GODOT_BIN or godot on PATH)",
    )
    parser.add_argument(
        "--group",
        action="append",
        choices=("all", *TEST_GROUPS),
        default=[],
        help="Test group; repeat to combine groups (default: all)",
    )
    parser.add_argument(
        "--log-dir",
        type=Path,
        help="Directory for one UTF-8 log per command",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=120,
        help="Per-command timeout in seconds (default: 120)",
    )
    return parser.parse_args()


def resolve_godot(value: str) -> str:
    candidate = Path(value).expanduser()
    if candidate.exists():
        found = str(candidate.resolve())
    else:
        found = shutil.which(value)
    if found:
        path = Path(found)
        if os.name == "nt" and path.suffix.lower() in {".cmd", ".bat"}:
            launcher = path.read_text(encoding="utf-8", errors="replace")
            match = re.search(r'"([^"\r\n]+\.exe)"', launcher, re.IGNORECASE)
            if match:
                expanded = Path(os.path.expandvars(match.group(1)))
                if expanded.exists():
                    path = expanded
        # Official Windows downloads ship a small *_console.exe launcher that
        # starts the real executable. Launch the real process so timeouts can
        # terminate it reliably; --log-file below preserves all test output.
        if os.name == "nt" and path.stem.lower().endswith("_console"):
            direct = path.with_name(path.name.replace("_console.exe", ".exe"))
            if direct.exists():
                path = direct
        return str(path.resolve())
    raise FileNotFoundError(
        f"Godot executable not found: {value!r}. Set GODOT_BIN or pass --godot."
    )


def command_for(godot: str, test: str) -> list[str]:
    if test == "@import":
        return [godot, "--headless", "--path", str(ROOT), "--import"]
    return [
        godot,
        "--headless",
        "--path",
        str(ROOT),
        "--script",
        f"res://{test}",
    ]


def run_command(
    command: list[str],
    test_name: str,
    timeout: int,
    log_dir: Path | None,
    save_root: Path,
) -> bool:
    env = os.environ.copy()
    if "SaveSettingsTest" in test_name or "ShellFlowTest" in test_name:
        safe_name = Path(test_name).stem.lower()
        test_save_dir = save_root / safe_name
        test_save_dir.mkdir(parents=True, exist_ok=True)
        env["CCP_TEST_SAVE_DIR"] = str(test_save_dir)
    if "MissingAudioFallbackTest" in test_name:
        env["CCP_TEST_AUDIO_MISSING"] = "1"

    label = "import" if test_name == "@import" else Path(test_name).stem
    engine_log = save_root / f"{label}.godot.log"
    command.extend(["--log-file", str(engine_log)])
    print(f"\n=== {label} ===", flush=True)
    started = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            env=env,
            text=True,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            check=False,
        )
        output = completed.stdout or ""
        exit_code = completed.returncode
    except subprocess.TimeoutExpired as exc:
        partial = exc.stdout or ""
        output = partial.decode("utf-8", "replace") if isinstance(partial, bytes) else partial
        output += f"\nTIMEOUT after {timeout} seconds\n"
        exit_code = 124
    except OSError as exc:
        output = f"PROCESS_START_FAILED: {exc}\n"
        exit_code = 127

    if engine_log.exists():
        logged = engine_log.read_text(encoding="utf-8", errors="replace")
        if logged and logged not in output:
            output += logged

    engine_errors = [
        line.strip()
        for line in output.splitlines()
        if line.lstrip().startswith(ENGINE_ERROR_PREFIXES)
    ]
    if engine_errors and exit_code == 0:
        exit_code = 1
        output += (
            "\nHEADLESS_RUNNER_ERROR: Godot emitted engine errors despite a zero "
            f"process exit code (count={len(engine_errors)}).\n"
        )
    print(output, end="" if output.endswith("\n") else "\n", flush=True)
    elapsed = time.monotonic() - started
    result_line = f"RESULT {label}: exit={exit_code} elapsed={elapsed:.2f}s\n"
    print(result_line, end="", flush=True)

    if log_dir is not None:
        log_dir.mkdir(parents=True, exist_ok=True)
        (log_dir / f"{label}.log").write_text(
            output + result_line, encoding="utf-8", newline="\n"
        )
    return exit_code == 0


def selected_tests(groups: list[str]) -> list[str]:
    requested = groups or ["all"]
    names = list(TEST_GROUPS) if "all" in requested else requested
    tests: list[str] = []
    for name in names:
        for test in TEST_GROUPS[name]:
            if test not in tests:
                tests.append(test)
    return tests


def main() -> int:
    args = parse_args()
    try:
        godot = resolve_godot(args.godot)
    except FileNotFoundError as exc:
        print(f"HEADLESS_SUITE_ERROR: {exc}", file=sys.stderr)
        return 127

    tests = selected_tests(args.group)
    failures: list[str] = []
    with tempfile.TemporaryDirectory(prefix="ccp-headless-saves-") as temp_dir:
        save_root = Path(temp_dir)
        for test in tests:
            if not run_command(
                command_for(godot, test), test, args.timeout, args.log_dir, save_root
            ):
                failures.append(test)

    if failures:
        print(f"\nHEADLESS_SUITE_FAILED failures={len(failures)} tests={len(tests)}")
        for failure in failures:
            print(f" - {failure}")
        return 1
    print(f"\nHEADLESS_SUITE_OK tests={len(tests)} godot={godot}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

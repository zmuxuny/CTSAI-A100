"""Check the production GOCA/SOCA factors against independent noise draws."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess

import numpy as np

PROJECT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--alpha-log", type=Path,
                        help="reuse CALIBRATED_* factors printed by run_sector_threshold_tests")
    args = parser.parse_args()
    if args.alpha_log:
        output = args.alpha_log.read_text(encoding="utf-8")
    else:
        functions = str(PROJECT / "functions").replace("'", "''")
        command = (
            f"addpath('{functions}');"
            "g=sector_cfar_alpha([26 26 12 12],0.01,'GOCA');"
            "s=sector_cfar_alpha([26 26 12 12],0.01,'SOCA');"
            "fprintf('CALIBRATED_GOCA=%.15g\\nCALIBRATED_SOCA=%.15g\\n',g,s);"
        )
        output = subprocess.run(
            ["octave", "--no-gui", "--quiet", "--eval", command],
            check=True, capture_output=True, text=True,
        ).stdout
    factors = {
        mode: float(re.search(rf"CALIBRATED_{mode}=([0-9.eE+-]+)", output).group(1))
        for mode in ("GOCA", "SOCA")
    }
    counts = np.array([26, 26, 12, 12])
    trials, pfa, seed = 200_000, 0.01, 20261005
    rng = np.random.default_rng(seed)
    before = dict.fromkeys(factors, 0)
    after = dict.fromkeys(factors, 0)
    for start in range(0, trials, 2000):
        n = min(2000, trials - start)
        means = rng.gamma(counts, 1 / counts, size=(n, len(counts)))
        cut = rng.exponential(size=n)
        for mode, alpha in factors.items():
            winner = means.argmax(axis=1) if mode == "GOCA" else means.argmin(axis=1)
            noise = means[np.arange(n), winner]
            winning_counts = counts[winner]
            old_alpha = winning_counts * (pfa ** (-1 / winning_counts) - 1)
            before[mode] += int((cut > old_alpha * noise).sum())
            after[mode] += int((cut > alpha * noise).sum())
    tolerance = 5 * np.sqrt(pfa * (1 - pfa) / trials)
    for mode in factors:
        assert abs(after[mode] / trials - pfa) < tolerance, (mode, after[mode])
    report = {
        "model": "independent unit-mean exponential CUT and training powers",
        "sector_counts": counts.tolist(), "seed": seed,
        "trials": trials, "nominal_pfa": pfa, "five_sigma_tolerance": float(tolerance),
        "results": [
            {"mode": mode, "alpha": alpha, "before_pfa": before[mode] / trials,
             "after_pfa": after[mode] / trials}
            for mode, alpha in factors.items()
        ],
    }
    results = PROJECT / "tests" / "results"
    results.mkdir(exist_ok=True)
    (results / "sector_false_alarm.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8",
    )
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()

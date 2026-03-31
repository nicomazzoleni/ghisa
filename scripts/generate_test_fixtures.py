#!/usr/bin/env python3
"""
Generate JSON test fixtures for GHISA correlation engine statistical tests.
Cross-validates against scipy.stats to ensure Swift implementations are correct.

Usage:
    pip install scipy statsmodels numpy
    python scripts/generate_test_fixtures.py

Output:
    ios/GHISATests/Fixtures/SpearmanFixtures.json
    ios/GHISATests/Fixtures/MannWhitneyFixtures.json
    ios/GHISATests/Fixtures/KruskalWallisFixtures.json
    ios/GHISATests/Fixtures/BenjaminiHochbergFixtures.json
"""

import json
import os
import numpy as np
from scipy.stats import spearmanr, mannwhitneyu, kruskal
from statsmodels.stats.multitest import multipletests

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "ios", "GHISATests", "Fixtures")


def generate_spearman_fixtures():
    fixtures = []
    np.random.seed(42)

    # 1. Strong positive correlation, n=50
    x = np.random.normal(0, 1, 50)
    y = x * 0.9 + np.random.normal(0, 0.3, 50)
    rho, p = spearmanr(x, y)
    fixtures.append({
        "name": "strong_positive_n50",
        "x": x.tolist(),
        "y": y.tolist(),
        "expected_rho": round(rho, 10),
        "expected_p": round(p, 10),
    })

    # 2. Strong negative correlation, n=30
    x = np.random.normal(0, 1, 30)
    y = -x * 0.8 + np.random.normal(0, 0.4, 30)
    rho, p = spearmanr(x, y)
    fixtures.append({
        "name": "strong_negative_n30",
        "x": x.tolist(),
        "y": y.tolist(),
        "expected_rho": round(rho, 10),
        "expected_p": round(p, 10),
    })

    # 3. No correlation, n=100
    x = np.random.normal(0, 1, 100)
    y = np.random.normal(0, 1, 100)
    rho, p = spearmanr(x, y)
    fixtures.append({
        "name": "no_correlation_n100",
        "x": x.tolist(),
        "y": y.tolist(),
        "expected_rho": round(rho, 10),
        "expected_p": round(p, 10),
    })

    # 4. Weak positive, n=200
    x = np.random.normal(0, 1, 200)
    y = x * 0.2 + np.random.normal(0, 1, 200)
    rho, p = spearmanr(x, y)
    fixtures.append({
        "name": "weak_positive_n200",
        "x": x.tolist(),
        "y": y.tolist(),
        "expected_rho": round(rho, 10),
        "expected_p": round(p, 10),
    })

    # 5. Perfect positive, n=20 (minimum)
    x = list(range(1, 21))
    y = list(range(1, 21))
    rho, p = spearmanr(x, y)
    fixtures.append({
        "name": "perfect_positive_n20",
        "x": [float(v) for v in x],
        "y": [float(v) for v in y],
        "expected_rho": round(rho, 10),
        "expected_p": round(p, 10),
    })

    # 6. With many ties, n=40
    x = np.repeat([1.0, 2.0, 3.0, 4.0], 10)
    y = np.repeat([10.0, 20.0, 30.0, 40.0], 10) + np.random.normal(0, 2, 40)
    rho, p = spearmanr(x, y)
    fixtures.append({
        "name": "many_ties_n40",
        "x": x.tolist(),
        "y": y.tolist(),
        "expected_rho": round(rho, 10),
        "expected_p": round(p, 10),
    })

    # 7. Medium correlation, n=25
    x = np.random.normal(0, 1, 25)
    y = x * 0.5 + np.random.normal(0, 0.8, 25)
    rho, p = spearmanr(x, y)
    fixtures.append({
        "name": "medium_correlation_n25",
        "x": x.tolist(),
        "y": y.tolist(),
        "expected_rho": round(rho, 10),
        "expected_p": round(p, 10),
    })

    return fixtures


def generate_mann_whitney_fixtures():
    fixtures = []
    np.random.seed(123)

    # 1. Clear difference, n=30 per group
    a = np.random.normal(10, 2, 30)
    b = np.random.normal(14, 2, 30)
    u, p = mannwhitneyu(a, b, alternative="two-sided")
    fixtures.append({
        "name": "clear_difference_n30",
        "group_a": a.tolist(),
        "group_b": b.tolist(),
        "expected_u": round(float(u), 10),
        "expected_p": round(float(p), 10),
    })

    # 2. No difference, n=50 per group
    a = np.random.normal(10, 2, 50)
    b = np.random.normal(10, 2, 50)
    u, p = mannwhitneyu(a, b, alternative="two-sided")
    fixtures.append({
        "name": "no_difference_n50",
        "group_a": a.tolist(),
        "group_b": b.tolist(),
        "expected_u": round(float(u), 10),
        "expected_p": round(float(p), 10),
    })

    # 3. Small difference, n=20 per group
    a = np.random.normal(10, 3, 20)
    b = np.random.normal(11, 3, 20)
    u, p = mannwhitneyu(a, b, alternative="two-sided")
    fixtures.append({
        "name": "small_difference_n20",
        "group_a": a.tolist(),
        "group_b": b.tolist(),
        "expected_u": round(float(u), 10),
        "expected_p": round(float(p), 10),
    })

    # 4. Unequal group sizes, n1=15, n2=40
    a = np.random.normal(10, 2, 15)
    b = np.random.normal(13, 2, 40)
    u, p = mannwhitneyu(a, b, alternative="two-sided")
    fixtures.append({
        "name": "unequal_groups_n15_n40",
        "group_a": a.tolist(),
        "group_b": b.tolist(),
        "expected_u": round(float(u), 10),
        "expected_p": round(float(p), 10),
    })

    # 5. With ties, n=25 per group
    a = np.round(np.random.normal(5, 1, 25))
    b = np.round(np.random.normal(7, 1, 25))
    u, p = mannwhitneyu(a, b, alternative="two-sided")
    fixtures.append({
        "name": "with_ties_n25",
        "group_a": a.tolist(),
        "group_b": b.tolist(),
        "expected_u": round(float(u), 10),
        "expected_p": round(float(p), 10),
    })

    # 6. Large n, n=100 per group
    a = np.random.normal(50, 10, 100)
    b = np.random.normal(55, 10, 100)
    u, p = mannwhitneyu(a, b, alternative="two-sided")
    fixtures.append({
        "name": "large_n100",
        "group_a": a.tolist(),
        "group_b": b.tolist(),
        "expected_u": round(float(u), 10),
        "expected_p": round(float(p), 10),
    })

    return fixtures


def generate_kruskal_wallis_fixtures():
    fixtures = []
    np.random.seed(456)

    # 1. Three groups, clear difference
    g1 = np.random.normal(10, 2, 20).tolist()
    g2 = np.random.normal(15, 2, 20).tolist()
    g3 = np.random.normal(20, 2, 20).tolist()
    h, p = kruskal(g1, g2, g3)
    fixtures.append({
        "name": "three_groups_clear_diff",
        "groups": {"morning": g1, "afternoon": g2, "evening": g3},
        "expected_h": round(float(h), 10),
        "expected_p": round(float(p), 10),
    })

    # 2. Three groups, no difference
    g1 = np.random.normal(10, 2, 25).tolist()
    g2 = np.random.normal(10, 2, 25).tolist()
    g3 = np.random.normal(10, 2, 25).tolist()
    h, p = kruskal(g1, g2, g3)
    fixtures.append({
        "name": "three_groups_no_diff",
        "groups": {"morning": g1, "afternoon": g2, "evening": g3},
        "expected_h": round(float(h), 10),
        "expected_p": round(float(p), 10),
    })

    # 3. Two groups (degenerates to ~Mann-Whitney)
    g1 = np.random.normal(8, 2, 30).tolist()
    g2 = np.random.normal(12, 2, 30).tolist()
    h, p = kruskal(g1, g2)
    fixtures.append({
        "name": "two_groups",
        "groups": {"low": g1, "high": g2},
        "expected_h": round(float(h), 10),
        "expected_p": round(float(p), 10),
    })

    # 4. Unequal group sizes
    g1 = np.random.normal(10, 2, 10).tolist()
    g2 = np.random.normal(14, 2, 30).tolist()
    g3 = np.random.normal(12, 2, 20).tolist()
    h, p = kruskal(g1, g2, g3)
    fixtures.append({
        "name": "unequal_sizes",
        "groups": {"small": g1, "medium": g3, "large": g2},
        "expected_h": round(float(h), 10),
        "expected_p": round(float(p), 10),
    })

    # 5. With ties (rounded values)
    g1 = np.round(np.random.normal(5, 1, 20)).tolist()
    g2 = np.round(np.random.normal(7, 1, 20)).tolist()
    g3 = np.round(np.random.normal(6, 1, 20)).tolist()
    h, p = kruskal(g1, g2, g3)
    fixtures.append({
        "name": "with_ties",
        "groups": {"a": g1, "b": g2, "c": g3},
        "expected_h": round(float(h), 10),
        "expected_p": round(float(p), 10),
    })

    return fixtures


def generate_bh_fixtures():
    fixtures = []

    # 1. Mixed significance
    pvals = [0.001, 0.01, 0.03, 0.04, 0.05, 0.10, 0.20, 0.50]
    reject, adjusted, _, _ = multipletests(pvals, method="fdr_bh")
    fixtures.append({
        "name": "mixed_significance",
        "p_values": pvals,
        "expected_adjusted": [round(float(v), 10) for v in adjusted],
        "expected_significant": [bool(v) for v in reject],
    })

    # 2. All significant
    pvals = [0.001, 0.002, 0.003, 0.004, 0.005]
    reject, adjusted, _, _ = multipletests(pvals, method="fdr_bh")
    fixtures.append({
        "name": "all_significant",
        "p_values": pvals,
        "expected_adjusted": [round(float(v), 10) for v in adjusted],
        "expected_significant": [bool(v) for v in reject],
    })

    # 3. None significant
    pvals = [0.10, 0.20, 0.30, 0.40, 0.50]
    reject, adjusted, _, _ = multipletests(pvals, method="fdr_bh")
    fixtures.append({
        "name": "none_significant",
        "p_values": pvals,
        "expected_adjusted": [round(float(v), 10) for v in adjusted],
        "expected_significant": [bool(v) for v in reject],
    })

    # 4. Single test
    pvals = [0.03]
    reject, adjusted, _, _ = multipletests(pvals, method="fdr_bh")
    fixtures.append({
        "name": "single_test",
        "p_values": pvals,
        "expected_adjusted": [round(float(v), 10) for v in adjusted],
        "expected_significant": [bool(v) for v in reject],
    })

    # 5. Large set (40 tests, simulating real use)
    np.random.seed(789)
    pvals = sorted(np.random.uniform(0, 1, 40).tolist())
    # Make some deliberately small
    pvals[0] = 0.0001
    pvals[1] = 0.001
    pvals[2] = 0.005
    reject, adjusted, _, _ = multipletests(pvals, method="fdr_bh")
    fixtures.append({
        "name": "large_set_n40",
        "p_values": [round(v, 10) for v in pvals],
        "expected_adjusted": [round(float(v), 10) for v in adjusted],
        "expected_significant": [bool(v) for v in reject],
    })

    # 6. Edge case: very small p-values
    pvals = [1e-10, 1e-8, 1e-5, 0.001, 0.05]
    reject, adjusted, _, _ = multipletests(pvals, method="fdr_bh")
    fixtures.append({
        "name": "very_small_pvalues",
        "p_values": pvals,
        "expected_adjusted": [round(float(v), 10) for v in adjusted],
        "expected_significant": [bool(v) for v in reject],
    })

    return fixtures


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    fixtures = {
        "SpearmanFixtures.json": generate_spearman_fixtures(),
        "MannWhitneyFixtures.json": generate_mann_whitney_fixtures(),
        "KruskalWallisFixtures.json": generate_kruskal_wallis_fixtures(),
        "BenjaminiHochbergFixtures.json": generate_bh_fixtures(),
    }

    for filename, data in fixtures.items():
        path = os.path.join(OUTPUT_DIR, filename)
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
        print(f"  Written {path} ({len(data)} fixtures)")

    print("Done! All fixtures generated.")


if __name__ == "__main__":
    main()

"""
Figure 1: Severity distribution by phase (stacked bar, six features aggregated).
Companion artifact to the SES 2026 practice paper.

Source: evidence-extract-2026-05-20.md sections 1-6.
Paired caption: fig1-caption.md (kept in the same directory).

Design rules (aligned with Figure 2):
- Labels are in English; no in-figure explanation.
- Caption carries the longer notes (e.g., severity vocabulary unification,
  N=2 caveat for the Design rework column).
"""

import matplotlib.pyplot as plt
from matplotlib import rcParams
import os

# Use English-only fonts; avoid Japanese fonts for consistency with caption rule.
rcParams['font.family'] = ['Helvetica', 'Arial', 'sans-serif']
rcParams['axes.unicode_minus'] = False

# Phases (left to right). Design rework column applies only to 2 features.
phases = [
    'Requirements',
    'Design',
    'Design rework\n(N=2)',
    'Tasks',
    'Conformance\npre',
    'Conformance\npost',
]

# Counts aggregated across the six features.
high = [29, 46, 0,  0, 26, 0]
mid  = [60, 74, 4, 15, 16, 1]
low  = [40, 40, 6, 28,  7, 4]

# Color palette (high = red, medium = orange, low = light green).
color_high = '#dc2626'
color_mid  = '#f59e0b'
color_low  = '#84cc16'

fig, ax = plt.subplots(figsize=(9, 5), dpi=120)

x = list(range(len(phases)))
ax.bar(x, high, color=color_high, label='High', edgecolor='white', linewidth=0.5)
ax.bar(x, mid, bottom=high, color=color_mid, label='Medium',
       edgecolor='white', linewidth=0.5)
ax.bar(x, low, bottom=[h + m for h, m in zip(high, mid)], color=color_low,
       label='Low', edgecolor='white', linewidth=0.5)

ax.set_xticks(x)
ax.set_xticklabels(phases, fontsize=13, color='black')
ax.set_ylabel('Count (six features aggregated)', fontsize=13, color='black')
ax.tick_params(axis='y', labelsize=12, labelcolor='black')

# Per-segment counts (shown inside each colored block). Use white on
# red/orange (High/Medium) for contrast; use black on light green (Low).
for i in range(len(phases)):
    if high[i] > 0:
        ax.text(i, high[i] / 2, str(high[i]), ha='center', va='center',
                color='white', fontsize=12, fontweight='bold')
    if mid[i] > 0:
        ax.text(i, high[i] + mid[i] / 2, str(mid[i]), ha='center', va='center',
                color='white', fontsize=12, fontweight='bold')
    if low[i] > 0:
        ax.text(i, high[i] + mid[i] + low[i] / 2, str(low[i]), ha='center',
                va='center', color='black', fontsize=12, fontweight='bold')
    # Stack total above each bar, in black.
    total = high[i] + mid[i] + low[i]
    if total > 0:
        ax.text(i, total + 2, str(total), ha='center', va='bottom',
                fontsize=13, color='black', fontweight='bold')

# Legend top-right, framed lightly, in black.
legend = ax.legend(loc='upper right', fontsize=13, framealpha=0.9)
for text in legend.get_texts():
    text.set_color('black')

# Extend y-axis a bit so the totals do not collide with the top border.
ax.set_ylim(0, max(h + m + l for h, m, l in zip(high, mid, low)) * 1.15)

# Light horizontal grid only.
ax.yaxis.grid(True, linestyle='--', alpha=0.4)
ax.set_axisbelow(True)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.tight_layout()

out_dir = os.path.dirname(os.path.abspath(__file__))
plt.savefig(os.path.join(out_dir, 'fig1-severity-distribution.svg'),
            format='svg', bbox_inches='tight')
plt.savefig(os.path.join(out_dir, 'fig1-severity-distribution.png'),
            format='png', dpi=200, bbox_inches='tight')
print('Saved: fig1-severity-distribution.{svg,png}')

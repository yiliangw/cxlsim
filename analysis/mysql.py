import matplotlib.pyplot as plt

import numpy as np

# Example data
labels = ['BASELINE', 'CXL', 'SWAP']
metrics = ['min', 'avg', 'p95', 'max']
data = [
    [84.99, 125.11, 227.40, 241.96],
    [231.88, 354.54, 511.33, 512.34],   # C
    [327.20, 525.85, 802.05, 804.05],
]

data = np.array(data)
x = np.arange(len(metrics))  # label locations
width = 0.2  # width of each bar

fig, ax = plt.subplots()
for i, label in enumerate(labels):
    ax.bar(x + i * width, data[i, :], width, label=label)

ax.set_xlabel('Metric')
ax.set_ylabel('Latency (ms)')
ax.set_title('OLTP Latency Benchmark')
ax.set_xticks(x + width)
ax.set_xticklabels(metrics)
ax.legend(title='Configuration')

plt.tight_layout()
plt.savefig('result.png', format='png')

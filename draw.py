import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

def clean_value(x):
    """Clean data by extracting percentage value or handling special cases"""
    if isinstance(x, str):
        # Extract percentage if exists
        if '(' in x and ')' in x:
            try:
                percentage = float(x.split('(')[1].split(')')[0].strip('%'))
                return percentage
            except:
                return np.nan
        # Handle normal case
        value = x.strip().split(' ')[0]
        try:
            return float(value)
        except:
            return np.nan
    return x

def determine_scale(data):
    """Determine the best scale for data distribution"""
    if data.empty:
        return 'linear'

    # Remove non-positive values
    data = data[data > 0]
    if data.empty:
        return 'linear'
        
    # Calculate distribution metrics
    range_ratio = data.max() / data.min()
    std = data.std()
    mean = data.mean()
    cv = std / mean if mean != 0 else 0
    
    if range_ratio > 1000:
        return 'log'
    elif cv > 1.5:  # High variance
        return 'symlog'
    else:
        return 'linear'

# Read and clean data
data = pd.read_csv('xml_summary.txt', sep='\t')
data.columns = data.columns.str.strip()
# Filter out rows containing three or more consecutive dashes
data = data[~data['Benchmark'].str.contains('---+', regex=True)]

# Handle special values
data['RATE'] = data['RATE'].replace(-1, 110)
data['Latency'] = data['Latency'].replace(-1, np.nan)

# Clean numeric data
for col in data.columns:
    if col != 'Benchmark':
        data[col] = data[col].map(clean_value)
        if col != 'Latency' and col != 'RATE':  # Keep percentage values for resource columns
            data[col] = pd.to_numeric(data[col], errors='coerce')

# Clean data by removing duplicates and sorting
data = data.drop_duplicates(subset=['Benchmark', 'RATE']).sort_values(['Benchmark', 'RATE'])

# Get unique benchmarks and resources
benchmarks = sorted(data['Benchmark'].unique())
resources = ['Latency', 'BRAM_18K', 'DSP', 'FF', 'LUT', 'URAM']

# Print detailed information
print("\n=== Analysis Summary ===")
print(f"1.Total number of benchmarks: {len(benchmarks)}")
print("2.Available resources:", end=' ')
print(' '.join(resources))
print("3.Benchmarks:", end=' ')
# Clean benchmark names by removing spaces and print in a space-separated format
cleaned_benchmarks = [b.replace(' ', '') for b in benchmarks]
print(' '.join(cleaned_benchmarks))

print("\nStarting plot generation...")

# Plot configuration
n_benchmarks = len(benchmarks)
n_cols = 5  # Keep 5 columns
n_rows = int(np.ceil(n_benchmarks / n_cols))

# Set style for academic publication
plt.style.use('seaborn-v0_8-paper')

# Update plot style for better academic appearance
plt.rcParams.update({
    'font.family': 'DejaVu Serif',
    # Other fonts is good:
    # 'font.family': 'Liberation Serif',
    # 'font.family': 'Nimbus Roman',
    'font.size': 8,
    'axes.titlesize': 10,
    'axes.labelsize': 9,
    'xtick.labelsize': 8,
    'ytick.labelsize': 8,
    'lines.linewidth': 1.8,
    'grid.linestyle': ':',  # Dotted grid lines
    'grid.alpha': 0.3,
    'axes.grid': True,
    'axes.facecolor': 'white',
    'figure.facecolor': 'white',
    'figure.autolayout': True
})

# Define professional academic color scheme
resource_colors = [
    '#2077B4',  # Steel blue
    '#FF7F0E',  # Orange
    '#2CA02C',  # Green
    '#9467BD',  # Purple
    '#8C564B',  # Brown
]  # Scientific paper style colors

# Deep navy blue for Latency - more academic and professional looking
latency_color = '#08519C'  # Deep navy blue

# Create figure with larger size
plt.figure(figsize=(n_cols * 5.5, n_rows * 4 + 2))  # Added extra space for legend

# Store all legends from all subplots
all_legend_lines = []
all_legend_labels = []

# Create subplots for each benchmark 
for idx, benchmark in enumerate(benchmarks):
    benchmark_data = data[data['Benchmark'] == benchmark]
    
    ax1 = plt.subplot(n_rows, n_cols, idx + 1)
    ax2 = ax1.twinx()
    
    # Track current subplot's legend elements
    current_legend_lines = []
    current_legend_labels = []
    
    # Plot Latency first (left y-axis) with solid line
    latency_data = benchmark_data['Latency']
    valid_latency = latency_data.dropna()
    if not valid_latency.empty:
        latency_line = ax1.plot(benchmark_data['RATE'], latency_data,
                color=latency_color, label='Latency',
                linestyle='-', linewidth=1.5,  # Back to normal width
                marker='o', markersize=4, markerfacecolor='white',
                zorder=10)
        current_legend_lines.extend(latency_line)
        current_legend_labels.append('Latency')
        
        latency_scale = determine_scale(valid_latency)
        ax1.set_yscale(latency_scale)
        
        # Set y-axis limits with safety check
        if latency_scale == 'linear':
            y_min = valid_latency.min()
            y_max = valid_latency.max()
            if y_min != y_max:
                margin = (y_max - y_min) * 0.1
                ax1.set_ylim([y_min - margin, y_max + margin])
    
    # Plot resources utilization (right y-axis)
    primary_metrics = ['BRAM_18K', 'DSP', 'FF', 'LUT', 'URAM']
    resource_data = benchmark_data[primary_metrics].dropna()
    if not resource_data.empty:
        resource_scale = determine_scale(resource_data.max())
        ax2.set_yscale(resource_scale)
        
        for metric, color in zip(primary_metrics, resource_colors):
            line = ax2.plot(benchmark_data['RATE'], benchmark_data[metric],
                    marker='s', color=color, label=metric,
                    linestyle='--', linewidth=1.2,
                    markersize=3, markerfacecolor='white',
                    zorder=5)[0]
            current_legend_lines.append(line)
            current_legend_labels.append(metric)

    # Store this subplot's legend if it has more elements than previous ones
    if len(current_legend_lines) > len(all_legend_lines):
        all_legend_lines = current_legend_lines
        all_legend_labels = current_legend_labels

    # Customize axis appearance
    ax1.set_title(benchmark, fontsize=10, pad=5, 
                 fontfamily='DejaVu Serif', fontweight='bold')
    ax1.set_xlabel('RATE', fontsize=9)
    ax1.set_ylabel('Latency (cycles)', fontsize=9)
    ax2.set_ylabel('Resource Utilization (%)', fontsize=9)
    
    # Set x-axis range and ticks with custom labels
    ax1.set_xlim([-5, 115])
    ax1.set_xticks([0, 25, 50, 75, 100, 110])
    ax1.set_xticklabels(['0', '25', '50', '75', '100', 'org'])

    # Customize spine visibility
    ax1.spines['top'].set_visible(False)
    ax2.spines['top'].set_visible(False)
    ax2.spines['right'].set_visible(True)  # Show right spine
    
    # Set spine colors
    ax2.spines['right'].set_color('gray')
    ax1.spines['left'].set_color('black')
    
    # Enhanced grid appearance
    ax1.grid(True, linestyle=':', alpha=0.3, color='gray')
    
    # Format axis ticks
    if 'latency_scale' in locals() and latency_scale != 'linear':
        ax1.yaxis.set_major_formatter(plt.ScalarFormatter())
    if 'resource_scale' in locals() and resource_scale != 'linear':
        ax2.yaxis.set_major_formatter(plt.ScalarFormatter())

    # Enhanced tick parameters
    ax1.tick_params(axis='both', which='major', labelsize=8, direction='out')
    ax2.tick_params(axis='y', which='major', labelsize=8, direction='out', right=True)  # Show right ticks

# After all subplots are created, add the legend at the bottom
fig = plt.gcf()
# Calculate the legend position dynamically
legend = fig.legend(all_legend_lines, all_legend_labels,
                   loc='center',
                   bbox_to_anchor=(0.5, -0.02),  # Moved below plots
                   ncol=6, 
                   fontsize=9,
                   frameon=True,
                   fancybox=False,
                   edgecolor='black')

# Get the legend height for proper spacing
legend_height = legend.get_window_extent().height / fig.dpi
# Adjust bottom margin based on legend height
plt.subplots_adjust(bottom=0.1 + legend_height/fig.get_figheight())

# Save figure with tight layout
plt.savefig('result.png', dpi=300, bbox_inches='tight', pad_inches=0.2)
print("Plot saved as result.png")
plt.close()

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
    elif cv > 1.5:
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
data['Latency(Syn)'] = data['Latency(Syn)'].replace(-1, np.nan)
data['Latency(Sim)'] = data['Latency(Sim)'].replace(-1, np.nan)

# Clean numeric data
for col in data.columns:
    if col != 'Benchmark':
        data[col] = data[col].map(clean_value)
        if col != 'Latency(Syn)' and col != 'Latency(Sim)' and col != 'RATE':
            data[col] = pd.to_numeric(data[col], errors='coerce')

# Clean data by removing duplicates and sorting
data = data.drop_duplicates(subset=['Benchmark', 'RATE']).sort_values(['Benchmark', 'RATE'])

# Get unique benchmarks and resources
benchmarks = sorted(data['Benchmark'].unique())
resources = ['Latency(Syn)', 'Latency(Sim)', 'BRAM_18K', 'DSP', 'FF', 'LUT', 'URAM']

# Print detailed information
print("\n=== Analysis Summary ===")
print(f"1.Total number of benchmarks: {len(benchmarks)}")
print("2.Available resources:", end=' ')
print(' '.join(resources))
print("3.Benchmarks:", end=' ')
# Clean benchmark names by removing spaces and print in a space-separated format
cleaned_benchmarks = [b.replace(' ', '') for b in benchmarks]
print(' '.join(cleaned_benchmarks))

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
    'grid.linestyle': ':',
    'grid.alpha': 0.3,
    'axes.grid': True,
    'axes.facecolor': 'white',
    'figure.facecolor': 'white',
    'figure.autolayout': True
})

# Define professional academic color scheme
resource_colors = [
    '#9ECAE1',  # Light Blue (Fresh and Academic)
    '#B2ABD2',  # Light Purple (Soft and Academic)
    '#A1D99B',  # Light Green (Subtle and Calm)
    '#C49C94',  # Light Brown (Neutral and Academic)
    '#E377C2',  # Light Magenta (Soft and Elegant)
]  # Scientific paper style colors

# Define styles for two types of latency
latency_styles = {
    'Latency(Syn)': {
        'color': '#D62728',  # Bright Red (Strong and Distinct)
        'linestyle': '-',
        'label': 'Latency (Synthesis)',
        'zorder': 10
    },
    'Latency(Sim)': {
        'color': '#FF7F0E',  # Bright Orange (Distinct and Visible)
        'linestyle': '-',
        'label': 'Latency (Simulation)',
        'zorder': 9
    }
}

# Create figure with larger size
plt.figure(figsize=(n_cols * 5.5, n_rows * 4 + 2))

# Store all legends from all subplots
all_legend_lines = []
all_legend_labels = []

# 在主循环开始前添加一行
print("\n=== Fitting Equations ===")
print("Benchmark       Latency_type: ax² + bx + c (axis of symmetry: x = -b/2a)")

# Create subplots for each benchmark 
for idx, benchmark in enumerate(benchmarks):
    benchmark_data = data[data['Benchmark'] == benchmark]
    
    ax1 = plt.subplot(n_rows, n_cols, idx + 1)
    ax2 = ax1.twinx()
    
    # Track current subplot's legend elements
    current_legend_lines = []
    current_legend_labels = []
    
    # Process both types of latency data
    for latency_type in ['Latency(Syn)', 'Latency(Sim)']:
        latency_data = benchmark_data[latency_type]
        valid_latency = latency_data.dropna()
        if not valid_latency.empty:
            # Draw latency line
            style = latency_styles[latency_type]
            latency_line = ax1.plot(benchmark_data['RATE'], latency_data,
                    color=style['color'],
                    label=style['label'],
                    linestyle=style['linestyle'],
                    linewidth=1.8,
                    marker=None,
                    zorder=style['zorder'])

            current_legend_lines.extend(latency_line)
            current_legend_labels.append(style['label'])

            # Get available rates between 0 and 100 for this benchmark and latency type
            available_rates = benchmark_data[
                (benchmark_data['RATE'] <= 100) &
                (benchmark_data['RATE'] >= 0) &
                (~benchmark_data[latency_type].isna())
            ]['RATE'].sort_values().unique()

            # If we have enough data points, select 10 evenly distributed rates
            if len(available_rates) >= 10:
                indices = np.linspace(0, len(available_rates)-1, 10, dtype=int)
                target_rates = available_rates[indices]
            else:
                # If we don't have enough points, use all available rates
                target_rates = available_rates

            # Curve fitting section
            fit_rates = []
            fit_latencies = []
            missing_rates = []
            
            for rate in target_rates:
                rate_data = benchmark_data[benchmark_data['RATE'] == rate]
                if not rate_data.empty and not rate_data[latency_type].isna().all():
                    fit_rates.append(rate)
                    fit_latencies.append(rate_data[latency_type].iloc[0])
                else:
                    missing_rates.append(rate)

            # Print warning for missing rates
            if missing_rates:
                print(f"{benchmark} Warning: Missing RATE values {missing_rates}")

            # Fit curve if we have enough points (at least 3)
            if len(fit_rates) >= 3:
                # Generate smooth x points for the curve
                x_smooth = np.linspace(min(fit_rates), max(fit_rates), 100)
                # Fit a 2nd degree polynomial
                coeffs = np.polyfit(fit_rates, fit_latencies, 2)
                y_smooth = np.polyval(coeffs, x_smooth)

                # Calculate the axis of symmetry
                a, b, c = coeffs
                axis_of_symmetry = -b/(2*a) if a != 0 else None

                # Print equation and axis of symmetry in terminal
                eq = f"{benchmark} {latency_type}: {a:.3e}x² + {b:.3e}x + {c:.3e}"
                if axis_of_symmetry is not None:
                    eq += f" (axis: x = {axis_of_symmetry:.2f})"
                print(eq)

                # Plot the fitting curve with lighter color
                curve_color = f"{style['color']}88"
                lc_line = ax1.plot(x_smooth, y_smooth,
                        color=curve_color,
                        label=f'{style["label"]} Curve',
                        linestyle=':',
                        linewidth=1.5,
                        marker=None,
                        alpha=0.7,
                        zorder=style['zorder']-1)
                current_legend_lines.extend(lc_line)
                current_legend_labels.append(f'{style["label"]} Curve')

    # Set y-axis range
    valid_latencies = pd.concat([
        benchmark_data['Latency(Syn)'].dropna(),
        benchmark_data['Latency(Sim)'].dropna()
    ])
    if not valid_latencies.empty:
        latency_scale = determine_scale(valid_latencies)
        ax1.set_yscale(latency_scale)
        
        if latency_scale == 'linear':
            y_min = valid_latencies.min()
            y_max = valid_latencies.max()
            if y_min != y_max:
                margin = (y_max - y_min) * 0.1
                ax1.set_ylim([y_min - margin, y_max + margin])

    # Plot resources utilization (right y-axis)
    primary_metrics = ['BRAM_18K', 'DSP', 'FF', 'LUT', 'URAM']
    resource_data = benchmark_data[primary_metrics].dropna()
    if not resource_data.empty:
        resource_scale = determine_scale(resource_data.max())
        ax2.set_yscale(resource_scale)
        
        markers = ['s', '^', 'D', 'v', 'o']  # Square, triangle up, diamond, triangle down, circle
        for metric, color, marker in zip(primary_metrics, resource_colors, markers):
            line = ax2.plot(benchmark_data['RATE'], benchmark_data[metric],
                    marker=marker, color=color, label=metric,
                    linestyle='--', linewidth=1.2,
                    markersize=4,
                    markerfacecolor=color,
                    markeredgecolor=color,
                    markeredgewidth=1,
                    alpha=0.8,
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
    ax2.spines['right'].set_visible(True)
    
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
    ax2.tick_params(axis='y', which='major', labelsize=8, direction='out', right=True)

# After all subplots are created, add the legend at the bottom
fig = plt.gcf()
# Calculate the legend position dynamically
legend = fig.legend(all_legend_lines, all_legend_labels,
                   loc='center',
                   bbox_to_anchor=(0.5, -0.02),
                   ncol=7,
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
print("\nRun Over! Plot saved as result.png.")
plt.close()

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import os
import argparse
from pathlib import Path

# parse command line arguments
def parse_args():
    parser = argparse.ArgumentParser(description='Process and plot benchmark data.')
    parser.add_argument('--input', '-i', type=str, default='xml_summary.txt',
                      help='Input file path (default: xml_summary.txt in current directory)')
    parser.add_argument('--output', '-o', type=str,
                      help='Output file path (default: result.png in the same directory as input file)')
    return parser.parse_args()

# Hardware resource configuration
AVAILABLE_RESOURCES = {
    'BRAM_18K': 270,
    'DSP': 240,
    'FF': 126800,
    'LUT': 63400,
    'URAM': 0
}

def clean_values(x, column_name=None):
    """Clean data by extracting actual resource values or handling special cases"""
    if isinstance(x, str):
        # Extract percentage if exists
        if '(' in x and ')' in x:
            try:
                raw_value = float(x.split()[0])  # Get the actual value before parentheses
                percentage = int(float(x.split('(')[1].split(')')[0].strip('%')))
                
                # Verify percentage if it's a resource column (only check integer part)
                if column_name in AVAILABLE_RESOURCES:
                    expected_percentage = int((raw_value / AVAILABLE_RESOURCES[column_name]) * 100)
                    if expected_percentage != percentage:
                        print(f"Warning: {column_name} percentage mismatch - "
                              f"Reported: {percentage}%, Calculated: {expected_percentage}%")
                
                return raw_value  # Return actual value instead of percentage
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
    
    if range_ratio > 100:
        return 'log'
    elif cv > 1.5:
        return 'symlog'
    else:
        return 'linear'

def calculate_axis_limits(data_series, padding=0.1):
    """Calculate appropriate axis limits with padding"""
    if data_series.empty:
        return 0, 1
    
    min_val = data_series.min()
    max_val = data_series.max()
    
    # Handle case where min and max are equal
    if min_val == max_val:
        if min_val == 0:
            return 0, 0.1
        else:
            # Set range to ±10% of the value
            delta = abs(min_val * 0.1)
            return max(0, min_val - delta), max_val + delta
    
    # Normal case
    range_val = max_val - min_val
    padding_val = max(range_val * padding, abs(max_val * 0.01))
    
    # Ensure minimum values are not negative for log scale
    return max(0, min_val - padding_val), max_val + padding_val

def set_axis_scale_and_limits(ax, data_series, is_primary_axis=True):
    """Set appropriate scale and limits for an axis"""
    if data_series.empty:
        return
    
    scale = determine_scale(data_series)
    y_min, y_max = calculate_axis_limits(data_series)
    
    if scale == 'log':
        if is_primary_axis:
            ax.set_yscale('log')
        else:
            ax.set_yscale('log')
        # Adjust limits for log scale
        if y_min <= 0:
            y_min = data_series[data_series > 0].min() * 0.9
    elif scale == 'symlog':
        if is_primary_axis:
            ax.set_yscale('symlog', linthresh=1)
        else:
            ax.set_yscale('symlog', linthresh=1)
    else:
        if is_primary_axis:
            ax.set_yscale('linear')
        else:
            ax.set_yscale('linear')
    
    ax.set_ylim(y_min, y_max)

def calculate_symmetry_axis(coeffs):
    """Calculate symmetry axis position for quadratic function"""
    a, b, _ = coeffs
    if a != 0:
        return -b/(2*a)
    return None

def determine_best_fit_degree(x, y):
    """Determine whether to use linear or quadratic fit based on R-squared values"""
    # Fit both linear and quadratic
    coeffs_linear = np.polyfit(x, y, 1)
    coeffs_quad = np.polyfit(x, y, 2)
    
    # Calculate R-squared for both fits
    y_linear = np.polyval(coeffs_linear, x)
    y_quad = np.polyval(coeffs_quad, x)
    
    residuals_linear = y - y_linear
    residuals_quad = y - y_quad
    
    ss_res_linear = np.sum(residuals_linear**2)
    ss_res_quad = np.sum(residuals_quad**2)
    ss_tot = np.sum((y - np.mean(y))**2)
    
    # Handle the case where all y values are the same (ss_tot = 0)
    if ss_tot == 0:
        # If all values are identical, use linear fit
        return 1, coeffs_linear
        
    # Calculate R-squared values
    r2_linear = 1 - (ss_res_linear / ss_tot)
    r2_quad = 1 - (ss_res_quad / ss_tot)
    
    # Handle potential numerical instability
    r2_linear = max(0, min(1, r2_linear))  # Clamp between 0 and 1
    r2_quad = max(0, min(1, r2_quad))      # Clamp between 0 and 1
    
    # Compare the improvement in fit
    improvement = r2_quad - r2_linear
    
    # Use quadratic only if it provides significantly better fit
    # and both fits are valid
    if np.isfinite(improvement) and improvement > 0.1:
        return 2, coeffs_quad
    return 1, coeffs_linear

def format_equation(coeffs, degree):
    """Format the equation string based on polynomial degree"""
    if degree == 2:
        return f"{coeffs[0]:.2e}x² + {coeffs[1]:.2e}x + {coeffs[2]:.2e}"
    else:
        return f"{coeffs[0]:.2e}x + {coeffs[1]:.2e}"

def plot_fitting_curve(ax, x, y, color, label):
    """Plot fitting curve with automatic degree selection"""
    # Only use data points where RATE is between 0 and 100
    mask = (x >= 0) & (x <= 100)
    x_valid = x[mask]
    y_valid = y[mask]
    
    if len(x_valid) < 2:
        return None, None, None
    
    # Determine best fit degree and get coefficients
    degree, coeffs = determine_best_fit_degree(x_valid, y_valid)
    
    # Generate smooth curve for plotting
    x_smooth = np.linspace(0, 100, 100)
    y_smooth = np.polyval(coeffs, x_smooth)
    
    # Plot fitting curve
    fit_line = ax.plot(x_smooth, y_smooth,
                    color=color,
                    linestyle='--',
                    alpha=0.5,
                    label=label)[0]
    
    # Calculate symmetry axis for quadratic fit
    sym_axis = calculate_symmetry_axis(coeffs) if degree == 2 else None
    
    return fit_line, coeffs, degree, sym_axis

def plot_latency(data, benchmarks, output_path):
    """Plot Latency(Syn) and Latency(Sim) on separate y-axes"""
    n_benchmarks = len(benchmarks)
    n_cols = 5
    n_rows = int(np.ceil(n_benchmarks / n_cols))
    
    plt.figure(figsize=(n_cols * 6.0, n_rows * 5.0 + 2))
    
    latency_styles = {
        'Latency(Syn)': {
            'color': '#FF4500',  # Orange
            'linestyle': '-',
            'marker': 'o',
            'markersize': 4,
            'label': 'Synthesis Latency',
            'zorder': 10,
            'axis': 'left'
        },
        'Latency(Sim)': {
            'color': '#FF6347',  # Red
            'linestyle': '-',
            'marker': 's',
            'markersize': 4,
            'label': 'Simulation Latency',
            'zorder': 9,
            'axis': 'right'
        }
    }

    # Store legend elements
    all_lines = []
    all_labels = []

    print("\n=== Latency Fitting Equations ===")
    for idx, benchmark in enumerate(benchmarks):
        benchmark_data = data[data['Benchmark'] == benchmark]
        ax1 = plt.subplot(n_rows, n_cols, idx + 1)
        ax2 = ax1.twinx()
        
        # Set axes limits
        syn_data = benchmark_data['Latency(Syn)'].dropna()
        sim_data = benchmark_data['Latency(Sim)'].dropna()
        
        if not syn_data.empty:
            set_axis_scale_and_limits(ax1, syn_data, True)
        
        if not sim_data.empty:
            set_axis_scale_and_limits(ax2, sim_data, False)

        for latency_type, style in latency_styles.items():
            latency_data = benchmark_data[latency_type].dropna()
            if not latency_data.empty:
                # Plot actual data
                line = ax1.plot(benchmark_data['RATE'], latency_data,
                           color=style['color'],
                           label=style['label'],
                           linestyle=style['linestyle'],
                           marker=style['marker'],
                           markersize=style['markersize'],
                           linewidth=1.5,
                           zorder=style['zorder'])[0]
                
                # Add fitting curve
                valid_points = benchmark_data[(benchmark_data['RATE'] >= 0) & 
                                           (benchmark_data['RATE'] <= 100)][['RATE', latency_type]].dropna()
                if len(valid_points) >= 2:
                    x = valid_points['RATE'].values
                    y = valid_points[latency_type].values
                    
                    fit_line, coeffs, degree, sym_axis = plot_fitting_curve(
                        ax1, x, y, 
                        style['color'],
                        f'{style["label"]} Fit'
                    )
                    
                    if fit_line is not None:
                        eq_str = format_equation(coeffs, degree)
                        if sym_axis is not None and 0 <= sym_axis <= 100:
                            print(f"{benchmark}-{latency_type}: {eq_str}  (axis: x = {sym_axis:.1f})")
                        else:
                            print(f"{benchmark}-{latency_type}: {eq_str}")
                        
                        if idx == 0:
                            all_lines.extend([line, fit_line])
                            all_labels.extend([style['label'], f'{style["label"]} Fit'])

        # Customize plot appearance
        ax1.set_title(benchmark, fontsize=10, pad=5)
        ax1.set_xlabel('RATE', fontsize=9)
        ax1.set_ylabel('Latency(Syn) (cycles)', fontsize=9)
        ax2.set_ylabel('Latency(Sim) (cycles)', fontsize=9)
        
        # Set x-axis limits and ticks
        ax1.set_xlim([-5, 115])
        ax1.set_xticks([0, 25, 50, 75, 100, 110])
        ax1.set_xticklabels(['0', '25', '50', '75', '100', 'org'])
        
        # Customize grid and spines
        ax1.grid(True, linestyle=':', alpha=0.3)
        ax1.spines['top'].set_visible(False)
        ax2.spines['top'].set_visible(False)

    # Add unified legend
    fig = plt.gcf()
    fig.legend(all_lines, all_labels,
              loc='center',
              bbox_to_anchor=(0.5, -0.05),
              ncol=len(all_lines),
              fontsize=9)

    plt.subplots_adjust(hspace=0.4, wspace=0.4)
    plt.savefig(output_path, dpi=300, bbox_inches='tight', pad_inches=0.2)
    plt.close()

def plot_resource_pair(data, benchmarks, resource1, resource2, output_path):
    """Plot a pair of resources with similar ranges on separate y-axes"""
    n_benchmarks = len(benchmarks)
    n_cols = 5
    n_rows = int(np.ceil(n_benchmarks / n_cols))
    
    plt.figure(figsize=(n_cols * 6.0, n_rows * 5.0 + 2))
    
    resource_styles = {
        resource1: {
            'color': '#FF4500',  # Orange
            'marker': 'o',
            'markersize': 4,
            'linestyle': '-',
            'axis': 'left'
        },
        resource2: {
            'color': '#FF6347',  # Red
            'marker': 's',
            'markersize': 4,
            'linestyle': '-',
            'axis': 'right'
        } if resource2 else None
    }

    # Store legend elements
    all_lines = []
    all_labels = []

    print(f"\n=== Resource Fitting Equations ({resource1}" + 
          (f" & {resource2}" if resource2 else "") + ") ===")
    
    for idx, benchmark in enumerate(benchmarks):
        benchmark_data = data[data['Benchmark'] == benchmark]
        ax1 = plt.subplot(n_rows, n_cols, idx + 1)
        ax2 = ax1.twinx()
        
        # Set axes limits
        res1_data = benchmark_data[resource1].dropna()
        res2_data = benchmark_data[resource2].dropna() if resource2 else pd.Series()
        
        if not res1_data.empty:
            set_axis_scale_and_limits(ax1, res1_data, True)
        
        if not res2_data.empty:
            set_axis_scale_and_limits(ax2, res2_data, False)

        for resource, style in resource_styles.items():
            if not style:  # Skip if no style (happens when resource2 is None)
                continue
                
            resource_data = benchmark_data[resource].dropna()
            if not resource_data.empty:
                # Plot actual data
                line = ax1.plot(benchmark_data['RATE'], resource_data,
                           color=style['color'],
                           label=resource,
                           marker=style['marker'],
                           markersize=style['markersize'],
                           linestyle=style['linestyle'],
                           linewidth=1.5)[0]
                
                # Add fitting curve
                valid_points = benchmark_data[(benchmark_data['RATE'] >= 0) & 
                                           (benchmark_data['RATE'] <= 100)][['RATE', resource]].dropna()
                if len(valid_points) >= 2:
                    x = valid_points['RATE'].values
                    y = valid_points[resource].values
                    
                    fit_line, coeffs, degree, sym_axis = plot_fitting_curve(
                        ax1, x, y, 
                        style['color'],
                        f'{resource} Fit'
                    )
                    
                    if fit_line is not None:
                        eq_str = format_equation(coeffs, degree)
                        if sym_axis is not None and 0 <= sym_axis <= 100:
                            print(f"{benchmark}-{resource}: {eq_str}  (axis: x = {sym_axis:.1f})")
                        else:
                            print(f"{benchmark}-{resource}: {eq_str}")
                        
                        if idx == 0:
                            all_lines.extend([line, fit_line])
                            all_labels.extend([resource, f'{resource} Fit'])

        # Customize plot appearance
        ax1.set_title(benchmark, fontsize=10, pad=5)
        ax1.set_xlabel('RATE', fontsize=9)
        ax1.set_ylabel(f'{resource1} Usage', fontsize=9)
        ax2.set_ylabel(f'{resource2} Usage', fontsize=9)
        
        ax1.set_xlim([-5, 115])
        ax1.set_xticks([0, 25, 50, 75, 100, 110])
        ax1.set_xticklabels(['0', '25', '50', '75', '100', 'org'])
        
        ax1.grid(True, linestyle=':', alpha=0.3)
        ax1.spines['top'].set_visible(False)
        ax2.spines['top'].set_visible(False)

    # Add unified legend
    fig = plt.gcf()
    fig.legend(all_lines, all_labels,
              loc='center',
              bbox_to_anchor=(0.5, -0.05),
              ncol=len(all_lines),
              fontsize=9)

    plt.subplots_adjust(hspace=0.4, wspace=0.4)
    plt.savefig(output_path, dpi=300, bbox_inches='tight', pad_inches=0.2)
    plt.close()

def main():
    # Parse command line arguments
    args = parse_args()
    
    # Convert input path to absolute path
    input_path = Path(args.input)
    if not input_path.is_absolute():
        input_path = Path.cwd() / input_path
    
    # Set output path relative to input file if not specified
    if args.output:
        output_path = Path(args.output)
        if not output_path.is_absolute():
            output_path = Path.cwd() / output_path
    else:
        # Default output path is result.png in the same directory as input file
        output_path = input_path.parent / 'result.png'
    
    # Create output directory if it doesn't exist
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Check if input file exists
    if not input_path.exists():
        print(f"Error: Input file '{input_path}' does not exist!")
        return
    
    # Read and clean data
    try:
        data = pd.read_csv(input_path, sep='\t')
    except Exception as e:
        print(f"Error reading input file: {e}")
        return

    # 1. First clean column names
    data.columns = data.columns.str.strip()
    
    # 2. Filter out rows containing three or more consecutive dashes
    data = data[~data['Benchmark'].str.contains('---+', regex=True)]
    
    # 3. Clean benchmark names by removing trailing/leading spaces
    data['Benchmark'] = data['Benchmark'].str.strip()
    
    # 4. Clean numeric data before handling special values
    for col in data.columns:
        if col != 'Benchmark':
            data[col] = data[col].map(lambda x: clean_values(x, col))
            if col != 'Latency(Syn)' and col != 'Latency(Sim)' and col != 'RATE':
                data[col] = pd.to_numeric(data[col], errors='coerce')
    
    # 5. Handle special values AFTER cleaning
    # Convert -1 to 110 for RATE and handle other special cases
    data['RATE'] = data['RATE'].replace(-1, 110)
    # Don't replace Latency values with nan here since they're already handled
    
    # 6. Clean data by removing duplicates and sorting
    data = data.drop_duplicates(subset=['Benchmark', 'RATE'])
    data = data.sort_values(['Benchmark', 'RATE'])
    
    # 7. Save processed data with proper format
    csv_output_path = output_path.parent / 'xml_clean.csv'
    data.to_csv(csv_output_path, index=False, float_format='%.1f')
    print(f"Processed data saved to {csv_output_path}")

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

    # Generate separate plots
    base_output_path = output_path.parent
    
    # Plot Latency
    latency_path = base_output_path / 'result_latency.png'
    plot_latency(data, benchmarks, latency_path)
    
    # Plot BRAM and DSP
    bram_dsp_path = base_output_path / 'result_bram_dsp.png'
    plot_resource_pair(data, benchmarks, 'BRAM_18K', 'DSP', bram_dsp_path)
    
    # Plot FF and LUT
    ff_lut_path = base_output_path / 'result_ff_lut.png'
    plot_resource_pair(data, benchmarks, 'FF', 'LUT', ff_lut_path)
    
    # Check if URAM has meaningful values
    if not (data['URAM'] == -1).all() and not data['URAM'].isna().all():
        uram_path = base_output_path / 'result_uram.png'
        plot_resource_pair(data, benchmarks, 'URAM', None, uram_path)
    
    print(f"\nRun Over! Plots saved in {base_output_path}")

if __name__ == "__main__":
    main()

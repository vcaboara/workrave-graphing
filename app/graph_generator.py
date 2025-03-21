import matplotlib.pyplot as plt
import os
from app.utils import handle_error

# @handle_error
# def generate_graphs(data, start_date=None, end_date=None):
#     """Generates graphs from parsed Workrave data, with date range support."""
#     filtered_data = data
#     if start_date and end_date:
#         filtered_data = [row for row in data if start_date <= row['Date'] <= end_date]

#     if not filtered_data:
#         return []

#     dates = [row['Date'] for row in filtered_data]
#     clicks = [int(row['Mouse clicks']) if 'Mouse clicks' in row else 0 for row in filtered_data]
#     distances = [float(row['Mouse distance'].replace('m', '')) if 'Mouse distance' in row else 0.0 for row in filtered_data]
#     breaks = [int(row['Breaks']) if 'Breaks' in row else 0 for row in filtered_data]
#     micro_breaks = [int(row['Micro-breaks']) if 'Micro-breaks' in row else 0 for row in filtered_data]
#     rest_time = [float(row['Rest time'].replace('h', '')) if 'Rest time' in row else 0.0 for row in filtered_data]
#     active_time = [float(row['Active time'].replace('h', '')) if 'Active time' in row else 0.0 for row in filtered_data]

#     graph_paths = []

#     plt.figure(facecolor='#121212') # Dark Background
#     plt.plot(dates, clicks, label='Mouse Clicks', color='#00aaff')
#     plt.plot(dates, distances, label='Mouse Distance (m)', color='#ffaa00')
#     plt.legend(facecolor='#121212', labelcolor='white')
#     plt.xticks(rotation=45, color='white')
#     plt.yticks(color='white')
#     plt.xlabel('Date', color='white')
#     plt.ylabel('Clicks/Distance', color='white')
#     plt.title('Mouse Activity', color='white')
#     plt.grid(True, color='#333333')
#     graph1_path = 'graph1.png'
#     plt.savefig(graph1_path, facecolor='#121212')
#     graph_paths.append(graph1_path)

#     plt.figure(facecolor='#121212')
#     plt.plot(dates, breaks, label='Breaks', color='#00ff00')
#     plt.plot(dates, micro_breaks, label='Micro-breaks', color='#ff00ff')
#     plt.plot(dates, rest_time, label='Rest time (h)', color='#00ffff')
#     plt.plot(dates, active_time, label='Active time (h)', color='#ffff00')
#     plt.legend(facecolor='#121212', labelcolor='white')
#     plt.xticks(rotation=45, color='white')
#     plt.yticks(color='white')
#     plt.xlabel('Date', color='white')
#     plt.ylabel('Metrics', color='white')
#     plt.title('Other Metrics', color='white')
#     plt.grid(True, color='#333333')
#     graph2_path = 'graph2.png'
#     plt.savefig(graph2_path, facecolor='#121212')
#     graph_paths.append(graph2_path)

#     return graph_paths

def generate_graphs(data):
    """Generates graphs from parsed Workrave data."""
    dates = [row['Date'] for row in data]
    breaks = [int(row['Breaks']) for row in data]
    micro_breaks = [int(row['Micro-breaks']) for row in data]
    rest_time = [float(row['Rest time'].replace('h', '')) for row in data]
    active_time = [float(row['Active time'].replace('h', '')) for row in data]

    graph_paths = []

    plt.figure()
    plt.plot(dates, breaks, label='Breaks')
    plt.plot(dates, micro_breaks, label='Micro-breaks')
    plt.legend()
    graph1_path = 'graph1.png'
    plt.savefig(graph1_path)
    graph_paths.append(graph1_path)

    plt.figure()
    plt.plot(dates, rest_time, label='Rest time')
    plt.plot(dates, active_time, label='Active time')
    plt.legend()
    graph2_path = 'graph2.png'
    plt.savefig(graph2_path)
    graph_paths.append(graph2_path)

    return graph_paths

@handle_error
def generate_graphs(data, start_date=None, end_date=None):
    """Generates graphs from parsed Workrave data, with date range support."""
    filtered_data = data
    if start_date and end_date:
        filtered_data = [row for row in data if start_date <= row['Date'] <= end_date]

    if not filtered_data:
        return []

    dates = [row['Date'] for row in filtered_data]
    clicks = [int(row['Mouse clicks']) if 'Mouse clicks' in row else 0 for row in filtered_data]
    distances = [float(row['Mouse distance'].replace('m', '')) if 'Mouse distance' in row else 0.0 for row in filtered_data]
    breaks = [int(row['Breaks']) if 'Breaks' in row else 0 for row in filtered_data]
    micro_breaks = [int(row['Micro-breaks']) if 'Micro-breaks' in row else 0 for row in filtered_data]
    rest_time = [float(row['Rest time'].replace('h', '')) if 'Rest time' in row else 0.0 for row in filtered_data]
    active_time = [float(row['Active time'].replace('h', '')) if 'Active time' in row else 0.0 for row in filtered_data]

    graph_paths = []

    plt.figure(facecolor='#121212') # Dark Background
    plt.plot(dates, clicks, label='Mouse Clicks', color='#00aaff')
    plt.plot(dates, distances, label='Mouse Distance (m)', color='#ffaa00')
    plt.legend(facecolor='#121212', labelcolor='white')
    plt.xticks(rotation=45, color='white')
    plt.yticks(color='white')
    plt.xlabel('Date', color='white')
    plt.ylabel('Clicks/Distance', color='white')
    plt.title('Mouse Activity', color='white')
    plt.grid(True, color='#333333')
    graph1_path = 'graph1.png'
    plt.savefig(graph1_path, facecolor='#121212')
    graph_paths.append(graph1_path)

    plt.figure(facecolor='#121212')
    plt.plot(dates, breaks, label='Breaks', color='#00ff00')
    plt.plot(dates, micro_breaks, label='Micro-breaks', color='#ff00ff')
    plt.plot(dates, rest_time, label='Rest time (h)', color='#00ffff')
    plt.plot(dates, active_time, label='Active time (h)', color='#ffff00')
    plt.legend(facecolor='#121212', labelcolor='white')
    plt.xticks(rotation=45, color='white')
    plt.yticks(color='white')
    plt.xlabel('Date', color='white')
    plt.ylabel('Metrics', color='white')
    plt.title('Other Metrics', color='white')
    plt.grid(True, color='#333333')
    graph2_path = 'graph2.png'
    plt.savefig(graph2_path, facecolor='#121212')
    graph_paths.append(graph2_path)

    return graph_paths

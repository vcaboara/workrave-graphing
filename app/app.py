# from flask import Flask, render_template, request
# from parser import parse_workrave_stats
# from graph_generator import generate_graphs
# from app.utils import logging

# app = Flask(__name__)

# @app.route('/', methods=['GET', 'POST'])
# def index():
#     if request.method == 'POST':
#         stats_data = request.files['stats'].read().decode('utf-8')
#         start_date = request.form.get('start_date')
#         end_date = request.form.get('end_date')
#         parsed_data = parse_workrave_stats(stats_data)
#         if parsed_data:
#             graph_paths = generate_graphs(parsed_data, start_date, end_date)
#             if graph_paths:
#                 return render_template('graphs.html', graph_paths=graph_paths)
#             else:
#                 return "Graph Generation failed", 500
#         else:
#             return "File Parsing failed", 400

#     return render_template('index.html')
from flask import Flask, render_template, request
from parser import parse_workrave_stats
from graph_generator import generate_graphs
from app.utils import logging

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        stats_data = request.files['stats'].read().decode('utf-8')
        start_date = request.form.get('start_date')
        end_date = request.form.get('end_date')
        parsed_data = parse_workrave_stats(stats_data)
        if parsed_data:
            graph_paths = generate_graphs(parsed_data, start_date, end_date)
            if graph_paths:
                return render_template('graphs.html', graph_paths=graph_paths)
            else:
                return "Graph Generation failed", 500
        else:
            return "File Parsing failed", 400

    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

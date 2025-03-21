import csv
from io import StringIO
from app.utils import handle_error

# @handle_error
# def parse_workrave_stats(stats_data):
#     """Parses Workrave statistics from a CSV-like string."""
#     reader = csv.DictReader(StringIO(stats_data))
#     return list(reader)

def parse_workrave_stats(stats_data):
    """Parses Workrave statistics from a CSV-like string."""
    reader = csv.DictReader(StringIO(stats_data))
    return list(reader)

# Example Usage within tests
if __name__ == "__main__":
    test_data = """Date,Breaks,Micro-breaks,Rest time,Active time
2023-10-26,10,20,1h,4h
2023-10-27,12,22,1.2h,4.5h"""
    parsed_result = parse_workrave_stats(test_data)
    print(parsed_result)

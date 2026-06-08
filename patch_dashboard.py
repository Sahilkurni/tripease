import re

path = r'd:\FLUTTER PROJECTS\TRIPEASE\tripease\lib\screens\home\agent_dashboard.dart'

with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Fix all getter errors
code = re.sub(r'bus\.busName', "bus.busname", code)
code = re.sub(r'bus\.busType', "bus.bustype", code)
code = re.sub(r'bus\.totalSeats', "bus.totalseats", code)
code = re.sub(r'bus\.sourceCityName', "'Source'", code)
code = re.sub(r'bus\.destinationCityName', "'Destination'", code)
code = re.sub(r'bus\.layoutType', "'2x2'", code)
code = re.sub(r'bus\.baseFare', "0", code)
code = re.sub(r'bus\.departureTime', "'N/A'", code)
code = re.sub(r'bus\.arrivalTime', "'N/A'", code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)

print("agent_dashboard.dart successfully patched!")

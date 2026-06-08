import re

# 1. Fix bus_list_screen.dart
path_list = r'd:\FLUTTER PROJECTS\TRIPEASE\tripease\lib\screens\bus\bus_list_screen.dart'
with open(path_list, 'r', encoding='utf-8') as f:
    list_code = f.read()

# Replace fields in bus_list_screen.dart
list_code = re.sub(r'bus\.sourceCityName', "'Source'", list_code)
list_code = re.sub(r'bus\.destinationCityName', "'Destination'", list_code)
list_code = re.sub(r'bus\.busName', "bus.busname", list_code)
list_code = re.sub(r'bus\.busType', "bus.bustype", list_code)
list_code = re.sub(r'bus\.departureTime', "'N/A'", list_code)
list_code = re.sub(r'bus\.arrivalTime', "'N/A'", list_code)
list_code = re.sub(r'bus\.baseFare', "0", list_code)

with open(path_list, 'w', encoding='utf-8') as f:
    f.write(list_code)

# 2. Fix bus_seat_selection_screen.dart
path_seats = r'd:\FLUTTER PROJECTS\TRIPEASE\tripease\lib\screens\bus\bus_seat_selection_screen.dart'
with open(path_seats, 'r', encoding='utf-8') as f:
    seats_code = f.read()

seats_code = re.sub(r'widget\.bus\.sourceCityName', "'Source'", seats_code)
seats_code = re.sub(r'widget\.bus\.destinationCityName', "'Destination'", seats_code)
seats_code = re.sub(r'widget\.bus\.busName', "widget.bus.busname", seats_code)
seats_code = re.sub(r'widget\.bus\.busType', "widget.bus.bustype", seats_code)
seats_code = re.sub(r'widget\.bus\.departureTime', "'N/A'", seats_code)
seats_code = re.sub(r'widget\.bus\.arrivalTime', "'N/A'", seats_code)
seats_code = re.sub(r'widget\.bus\.baseFare', "0", seats_code)
seats_code = re.sub(r'widget\.bus\.totalSeats', "widget.bus.totalseats", seats_code)

with open(path_seats, 'w', encoding='utf-8') as f:
    f.write(seats_code)

print('Patched successfully!')


# Add NYC LL97 Fines
This project calculate NYC Local Law 97 carbon_emission and fines data using NYC Local Law 84 dataset.

### Components
- `property_type_mapping.csv` : property type mapping talbe to map LL84 property type and LL97 property type (based on Amanda Clevinger - Policy and Programs Manager's [gsheet](https://docs.google.com/spreadsheets/d/1mgs-wKk55XCZdfDy9nDcAjMfrwfJUtLlVy6z3jAshIo/edit?usp=sharing))
- `add_ll97_fines.ipynb` : jupyter notebook containing the main code

### Requirements:
```
Jupyter Notebook
```

### Install:
```
$ pip install -r requirements.txt
```

### Pre-requisite columns
- Electricity Use - Grid Purchase (kWh) <br/>
- Natural Gas Use (kBtu) <br/>
- Fuel Oil #2 Use (kBtu) <br/>
- Fuel Oil #4 Use (kBtu) <br/>
- District Steam Use (kBtu) <br/>
- Largest Property Use Type <br/>
- 2nd Largest Property Use Type <br/>
- 3rd Largest Property Use Type <br/>
- Largest Property Use Type - Gross Floor Area (ft²) <br/>
- 2nd Largest Property Use - Gross Floor Area (ft²) <br/>
- 3rd Largest Property Use Type - Gross Floor Area (ft²) <br/>
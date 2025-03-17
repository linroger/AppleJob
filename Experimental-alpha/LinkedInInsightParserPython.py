#!/usr/bin/env python3
"""
Script to extract data from LinkedIn Insights pages with enhanced detection patterns.
Combines headcount growth data into one table with 6m and 1y growth, and adds columns
for actual employee counts based on percentage changes.
"""

from bs4 import BeautifulSoup
import re
import json
import pandas as pd

### Helper Functions ###

def clean_growth_string(growth_str):
    """
    Cleans growth percentage strings by removing duplicates and handling negative values.
    Example:
    - "5%5% increase" → "5% increase"
    - "15%-15% decrease" → "-15% decrease"
    - "50% 50% increase" → "50% increase"
    """
    match = re.search(r'(-?\d+%)\s*-?\1\s*(\b.*)', growth_str)
    if match:
        percent = match.group(1)
        trend = match.group(2).strip()
        return f"{percent} {trend}" if trend else percent
    return growth_str

def parse_growth_percentage(growth_str):
    """
    Parses growth strings to extract numerical percentage.
    Example: "5% increase" → 5, "-15% decrease" → -15, "No change" → 0
    """
    if "No change" in growth_str:
        return 0
    match = re.search(r'(-?\d+)%', growth_str)
    if match:
        return int(match.group(1))
    return None

def calculate_added(current, growth_percent):
    """
    Calculates the number of employees added based on current count and growth percentage.
    Formula: added = N - (N / (1 + G/100)), rounded to nearest integer.
    """
    if growth_percent is None:
        return None
    try:
        N = int(current.replace(',', ''))
        G = growth_percent
        if G == 0:
            return 0
        previous = N / (1 + G / 100)
        added = N - previous
        return round(added)
    except Exception:
        return None

### Extraction Functions ###

def extract_employee_growth(soup):
    """Extracts employee growth data with year inference."""
    data = []
    group = soup.find('g', class_=re.compile(r'highcharts-markers'))
    if group:
        paths = group.find_all('path', attrs={'aria-label': True})
        pattern = r"^\d+\.\s+([^,]+),\s+([^,]+)\s+(\d+),\s+([^,]+),\s+([\d,]+) employees(?:, (.+))?$"
        for path in paths:
            label = path['aria-label']
            m = re.match(pattern, label)
            if m:
                data.append({
                    'day_of_week': m.group(1).strip(),
                    'month': m.group(2).strip(),
                    'day': m.group(3).strip(),
                    'time': m.group(4).strip(),
                    'employee_count': int(m.group(5).replace(',', '')),
                    'growth': m.group(6).strip() if m.group(6) else ""
                })
            else:
                data.append({'raw': label})

    if data:
        month_map = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
                     'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12}
        last_valid_idx = next((i for i in range(len(data) - 1, -1, -1) if 'month' in data[i]), -1)
        if last_valid_idx != -1:
            data[last_valid_idx]['year'] = 2025
            for i in range(last_valid_idx - 1, -1, -1):
                if 'month' not in data[i]:
                    continue
                next_month = month_map.get(data[i + 1]['month'], 1)
                next_year = data[i + 1].get('year', 2025)
                expected_year = next_year - 1 if next_month == 1 else next_year
                data[i]['year'] = expected_year
    return data

def extract_function_distribution(soup):
    """Extracts function distribution with flexible class pattern."""
    distribution = {}
    table_div = soup.find('div', class_=re.compile(r'org-function-percentage'))
    if table_div:
        rows = table_div.find_all('tr')
        for row in rows:
            td = row.find('td')
            if td and td.find('strong'):
                percentage = td.find('strong').get_text(strip=True)
                parts = td.get_text(separator=" ", strip=True).split('·')
                if len(parts) >= 2:
                    distribution[parts[1].strip()] = percentage
    return distribution

def extract_headcount_growth(soup):
    """Extracts headcount growth with flexible summary pattern."""
    growth_data = []
    table = soup.find('table', summary=re.compile(r'headcount.*growth', re.IGNORECASE))
    if table:
        rows = table.find_all('tr')[1:]
        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 5:
                growth_data.append({
                    'function': cells[0].get_text(strip=True),
                    'num_employees': cells[1].get_text(strip=True),
                    'percentage': cells[2].get_text(strip=True),
                    'growth_6m': clean_growth_string(cells[3].get_text(strip=True)),
                    'growth_1y': clean_growth_string(cells[4].get_text(strip=True))
                })
    return growth_data

def extract_new_hires(soup):
    """Extracts new hires data with flexible summary pattern."""
    hires = []
    table = soup.find('table', summary=re.compile(r'senior.*hires', re.IGNORECASE))
    if table:
        rows = table.find_all('tr')[1:]
        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 3:
                hires.append({
                    'date': cells[0].get_text(strip=True),
                    'senior_hires': cells[1].get_text(strip=True),
                    'other_hires': cells[2].get_text(strip=True)
                })
    return hires

def extract_job_openings(soup):
    """Extracts job openings data with flexible patterns."""
    result = {}
    job_module = soup.find('section', class_=re.compile(r'org-insights-jobs-module'))
    if job_module:
        # Distribution
        distribution = {}
        dist_table = job_module.find('div', class_=re.compile(r'org-function-percentage'))
        if dist_table:
            rows = dist_table.find_all('tr')
            for row in rows:
                td = row.find('td')
                if td and td.find('strong'):
                    percentage = td.find('strong').get_text(strip=True)
                    parts = td.get_text(separator=" ", strip=True).split('·')
                    if len(parts) >= 2:
                        distribution[parts[1].strip()] = percentage
        result['distribution'] = distribution

        # Openings Details
        openings = []
        details_table = job_module.find('table', id=re.compile(r'function-growth__a11y'))
        if details_table:
            rows = details_table.find_all('tr')[1:]
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 5:
                    openings.append({
                        'function': cells[0].get_text(strip=True),
                        'num_employees': cells[1].get_text(strip=True),
                        'percentage': cells[2].get_text(strip=True),
                        'growth_3m': clean_growth_string(cells[3].get_text(strip=True)),
                        'growth_6m': clean_growth_string(cells[4].get_text(strip=True))
                    })
        result['openings_details'] = openings

        # Growth Data
        growth_data = []
        growth_table = job_module.find('table', class_=re.compile(r'org-insights-functions-growth'))
        if growth_table:
            rows = growth_table.find_all('tr')[1:]
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 3:
                    growth_data.append({
                        'function': cells[0].get_text(strip=True),
                        'growth_3m': clean_growth_string(cells[1].get_text(strip=True)),
                        'growth_6m': clean_growth_string(cells[2].get_text(strip=True))
                    })
        result['job_openings_growth'] = growth_data
    return result

def extract_job_openings_plain_text(soup):
    """Extracts job openings as plain text with flexible class pattern."""
    result = []
    growth_div = soup.find('div', class_=re.compile(r'org-function-growth'))
    if growth_div:
        table = growth_div.find('table', id=re.compile(r'function-growth__a11y'))
        if table:
            rows = table.find_all('tr')[1:]
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 5:
                    result.append({
                        'function': cells[0].get_text(strip=True),
                        'num_employees': cells[1].get_text(strip=True),
                        'growth_3m': clean_growth_string(cells[3].get_text(strip=True)),
                        'growth_6m': clean_growth_string(cells[4].get_text(strip=True))
                    })
    return result

### File List ###

files = [
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/bofa.html",
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/citi.html",
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/wellington.html",
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/capital_group.html",
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/jpmorgan.html",
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/two-sigma.html",
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/citadel_html.html",
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/linkedin_insights_citadel.html",
    "/Users/rogerlin/Downloads/LinkedinPremium_InsightsScraper-master/linkedin_insights_peak6.html"
]

### Main Function ###

def main():
    for file_path in files:
        print(f"\nProcessing file: {file_path}")
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                html = f.read()
            soup = BeautifulSoup(html, 'html.parser')

            extracted_data = {
                'employee_growth': extract_employee_growth(soup),
                'function_distribution': extract_function_distribution(soup),
                'headcount_growth': extract_headcount_growth(soup),
                'new_hires': extract_new_hires(soup),
                'job_openings': extract_job_openings(soup),
                'job_openings_plain_text': extract_job_openings_plain_text(soup)
            }

            # Enhance headcount_growth with added employee counts
            for item in extracted_data['headcount_growth']:
                growth_6m_percent = parse_growth_percentage(item['growth_6m'])
                growth_1y_percent = parse_growth_percentage(item['growth_1y'])
                item['added_6m'] = calculate_added(item['num_employees'], growth_6m_percent)
                item['added_1y'] = calculate_added(item['num_employees'], growth_1y_percent)

            # Output JSON data
            print(f"\nExtracted Data from {file_path}:")
            print(json.dumps(extracted_data, indent=4))

            # Display DataFrames
            print("\nEmployee Growth Data:")
            print(pd.DataFrame(extracted_data['employee_growth']))

            print("\nFunction Distribution:")
            print(pd.DataFrame(
                list(extracted_data['function_distribution'].items()),
                columns=['Function', 'Percentage']
            ))

            print("\nHeadcount Growth with Added Employees:")
            print(pd.DataFrame(extracted_data['headcount_growth']))

            print("\nNew Hires:")
            print(pd.DataFrame(extracted_data['new_hires']))

            print("\nJob Openings Distribution:")
            print(pd.DataFrame(
                list(extracted_data['job_openings'].get('distribution', {}).items()),
                columns=['Function', 'Percentage']
            ))

            print("\nJob Openings Details:")
            print(pd.DataFrame(extracted_data['job_openings'].get('openings_details', [])))

            print("\nJob Openings Growth:")
            print(pd.DataFrame(extracted_data['job_openings'].get('job_openings_growth', [])))

            print("\nJob Openings Plain Text:")
            print(pd.DataFrame(extracted_data['job_openings_plain_text']))

        except Exception as e:
            print(f"Error processing {file_path}: {e}")

if __name__ == '__main__':

# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:light
#     text_representation:
#       extension: .py
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.12.0
#   kernelspec:
#     display_name: Python 3
#     language: python
#     name: python3
# ---

import pandas as pd
import re
import cdx_toolkit
from tqdm import tqdm
from pyprojroot import here

# # Extract archive

# Extract archived URLs from [Bundesverband Carsharing](https://carsharing.de/).

# Define url for which captures shall be extracted from web archives
url = "carsharing.de/cs-standorte"

# Instantiate cdx client
source = 'ia'
client = cdx_toolkit.CDXFetcher(source=source)       # define client for fetching data from source (ia: Internet Archive, cc: Common Crawl)
limit = 1000                                         # define maximum number of captures that is suppossed to be retrieved for each year-url from the respective archive

# A 'warcinfo' record describes the records that follow it, up through end of file, end of input, or until next 'warcinfo' record.
# Typically, this appears once and at the beginning of a WARC file. 
# For a web archive, it often contains information about the web crawl which generated the following records.
warcinfo = {
    'software': 'pypi_cdx_toolkit iter-and-warc',
    'isPartOf': 'CARSHARING_BCS',
    'description': 'warc extraction',
    'format': 'WARC file version 1.0',
}

# Define years for which web archives shall be searched for captures from the above url
years = range(2006, 2022) # years for which information of newly registered cars exist

# Set directory where to save the captrures
import os 
os.chdir(here(r'01_Data\03_Carsharing\02_BCS_Archived'))

# %%time
for year in years:
    
    # Create object for writing archive captures into .arc files
    writer = cdx_toolkit.warc.CDXToolkitWARCWriter(
        prefix='BCS_' + source,  # first part of .warc file where warc records will be stored
        subprefix=str(year),     # second part of .warc file where warc records will be stored
        info=warcinfo,           
        size=1000000000,         # once the .warc file exceeds 1 GB of size a new .warc file will be created for succeeding records
        gzip=True)
    
    capture = client.iter(url, from_ts=str(year), to=str(year), limit=limit, collapse='urlkey', verbose='v', filter=['status:200'])
    for obj in tqdm(capture):
        url = obj['url']
        status = obj['status']
        timestamp = obj['timestamp']

        try:
            record = obj.fetch_warc_record()
            writer.write_record(record)
                        
        # Single captures can run into errors:
        # Except RuntimeError
        except RuntimeError:
            print('Skipping capture for RuntimeError 404: %s %s', url, timestamp)
            continue                
                    
        # Except encoding error that typically arises if no content found on webpage
        except UnicodeEncodeError:
            print('Skipping capture for UnicodeEncodeError: %s %s', url, timestamp)
            continue
            
    print(year)

# # Analyze archive 

# Analyze whether carsharing locations can be extracted from the archived websites 

from warcio.archiveiterator import ArchiveIterator # iterate over .warc files
from bs4 import BeautifulSoup                      # html parsing

#files = [str(year) + '-000000' for year in range(2006, 2022)]
files = ['2013-000000', '2014-000000', '2015-000000', '2016-000000', '2017-000000']

source = 'ia'

# +
df_header = pd.DataFrame()

for file in files:
    with open(here(r'./01_Data/03_Carsharing/02_BCS_Archived' + '/BCS_' + source + '-' + str(file) + '.extracted.warc.gz') , 'rb') as stream:
        for record in ArchiveIterator(stream):
            if record.rec_headers['WARC-Type'] == 'warcinfo':
                pass
            else:
                temp = sorted([(i[0], [i[1]]) for i in record.rec_headers.headers if i[0] in ['WARC-Date', 'Content-Type', 'Content-Length', 'WARC-Source-URI']], key=lambda tup: tup[0], reverse=True) 
                df_temp = pd.DataFrame.from_dict(dict(temp))
                df_header = df_header.append(df_temp)
    stream.close()
df_header.reset_index(drop=True, inplace=True)
# -

df_header.shape

df_header['WARC-Source-URI'].values

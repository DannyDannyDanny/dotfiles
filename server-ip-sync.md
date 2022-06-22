## Requirements


### Env file

```python
# template .env file
token='ghp_<your gist token>'
gist_id='abc...123'
filename='<filename-in-gist>.txt'
```

### python requirements

Install [python-dotenv](https://pypi.org/project/python-dotenv/)

```
# %pip install python-dotenv
```

These imports are necessary for reading and updating gists

```python
from dotenv import load_dotenv
# in-built libraries
import requests
import json
import os
```


### Reading `.env`

```python
# read env vars
# S/O https://stackoverflow.com/a/61029741
load_dotenv()
token = os.getenv('token')
gist_id = os.getenv('gist_id')
filename = os.getenv('filename')
```


### write current machine ip address to gist file

```python
# fetch external ip address
# S/O https://stackoverflow.com/a/36205547
ip_addr = requests.get('https://api.ipify.org').content.decode('utf8')

# request gist changes
# S/O https://stackoverflow.com/a/65761251
headers = {'Authorization': f'token {token}'}
request_url = f'https://api.github.com/gists/{gist_id}'
request_data = json.dumps({'files':{filename:{"content":ip_addr}}})

r = requests.patch(
    url=request_url,
    data=request_data,
    headers=headers)
```


### Read gist file content

```python
### fetch gist file content

headers = {'Authorization': f'token {token}'}
request_url = f'https://api.github.com/gists/{gist_id}'
request_data = json.dumps({'files':{filename:{"content":ip_addr}}})
r = requests.get(
    url=request_url,
    data=request_data,
    headers=headers)
gist_content = r.json()['files'][filename.strip()]['content']
```

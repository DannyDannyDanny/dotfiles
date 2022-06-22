## Requirements

### Env file

Make rules:
* [.] add make rules python cronjob for servers
  * [.] make `.env`: `setup_server_ip_sync_dotenv_file`
  * [.] make venv and install requirements: `setup_server_ip_sync_python_env`
  * [ ] add oneliner to cron `<path-to-venv>/python server-ip-sync.py --upload`

```makefile
" https://stackoverflow.com/a/9578959
addcron:
    CRONENTRY=
    { crontab -l; echo "* * * * * path-to-venv/python >> ip.log" } | crontab -

add_github_token:
    echo "Visit github to generate new token:"
    echo "    github.com/settings/tokens/new"
    @echo "Enter github token: "; \
    read token; \
    echo "Your token is ", $$(token)
```


* [get token](https://github.com/settings/tokens/new)
* refernce [API description](https://docs.github.com/en/rest/gists#update-a-gist)

```python
# template .env file
token='ghp_<your gist token>'     # github token
gist_id='abc...123'               # gist id
filename='<filename-in-gist>'     # nickname for the server (i.e iot-hub-server)
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

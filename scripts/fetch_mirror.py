"""Fetch public GAS pages with bounded concurrency; publish only a complete set."""
import concurrent.futures
import os
from pathlib import Path
import subprocess
import sys
import time
from urllib.parse import quote

VIEWS = 'home songs board appreciate top themes hall rules more leave'.split()


def fetch_page(label, query, destination):
    for attempt in range(1, 4):
        result = subprocess.run([
            'curl', '-sL', '--max-time', '120', '-A', os.environ['UA'],
            '-o', str(destination), os.environ['EXEC'] + query,
        ], check=False)
        if result.returncode == 0 and destination.exists():
            content = destination.read_bytes()
            if len(content) > 20000 and b'userHtml' in content:
                print(f'fetched {label}: {len(content)} bytes', flush=True)
                return
        if attempt < 3:
            time.sleep(20)
    raise RuntimeError(f'Failed to fetch {label} after 3 attempts')


def main(mode):
    Path('raw').mkdir(exist_ok=True)
    Path('out').mkdir(exist_ok=True)
    if mode == 'views':
        jobs = [(v, f'?p={v}', Path('raw') / f'{v}.html') for v in VIEWS]
    elif mode == 'members':
        names = [line.strip() for line in Path('members.txt').read_text(encoding='utf-8').splitlines() if line.strip()]
        if not names:
            raise RuntimeError('No members found')
        encoded = [quote(name, safe="!'()*-._~") for name in names]
        jobs = [(f'member album {i+1}', f'?p=me&m={name}', Path('raw') / f'me-{name}.html') for i, name in enumerate(encoded)]
    else:
        raise ValueError('Expected views or members')
    # Three simultaneous requests, below GAS concurrent-execution limits.
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        futures = [pool.submit(fetch_page, *job) for job in jobs]
        for future in concurrent.futures.as_completed(futures):
            future.result()  # Any failed page fails the entire deployment.


if __name__ == '__main__':
    main(sys.argv[1])

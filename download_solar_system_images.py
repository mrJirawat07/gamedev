#!/usr/bin/env python3
"""
download_solar_system_images.py
Download images for solar system objects using NASA Images API.
Exclude items that clearly depict human-made objects (spacecraft, probes, astronauts, stations).

Usage examples:
  python download_solar_system_images.py --targets Mars Jupiter Saturn --per-target 20 --output-dir nasa_planets

"""
import argparse
import os
import re
import time
import json
import hashlib
from urllib.parse import urljoin
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

API_SEARCH = 'https://images-api.nasa.gov/search'
API_ASSET = 'https://images-api.nasa.gov/asset/'
IMG_EXT_RE = re.compile(r'\.(?:jpg|jpeg|png)(?:\?.*)?$', re.IGNORECASE)
HUMAN_MADE_KEYWORDS = [
    'iss', 'spacecraft', 'satellite', 'probe', 'lander', 'rover', 'apollo', 'shuttle', 'crew', 'astronaut',
    'capsule', 'soyuz', 'dragon', 'orbiter', 'juno', 'voyager', 'cassini', 'messenger', 'new horizons', 'sts',
]


def build_session(user_agent: str="ImageDownloader/1.0"):
    s = requests.Session()
    s.headers.update({'User-Agent': user_agent})
    retries = Retry(total=3, backoff_factor=0.5, status_forcelist=[500,502,503,504])
    s.mount('https://', HTTPAdapter(max_retries=retries))
    s.mount('http://', HTTPAdapter(max_retries=retries))
    return s


def is_human_made(text: str) -> bool:
    if not text:
        return False
    t = text.lower()
    for k in HUMAN_MADE_KEYWORDS:
        if k in t:
            return True
    return False


def sanitize_filename(url: str) -> str:
    name = url.split('/')[-1].split('?')[0]
    if not name:
        name = hashlib.sha1(url.encode('utf-8')).hexdigest() + '.jpg'
    return name


def get_search(session: requests.Session, query: str, page: int = 1):
    params = {'q': query, 'media_type': 'image', 'page': page}
    r = session.get(API_SEARCH, params=params, timeout=15)
    r.raise_for_status()
    return r.json()


def get_asset_urls(session: requests.Session, nasa_id: str):
    # returns list of candidate image urls for the given nasa_id via the asset endpoint
    try:
        r = session.get(API_ASSET + nasa_id, timeout=15)
        r.raise_for_status()
        data = r.json()
        items = data.get('collection', {}).get('items', [])
        urls = [it.get('href') for it in items if isinstance(it.get('href'), str) and IMG_EXT_RE.search(it.get('href'))]
        # prefer larger files by returning longer URLs last (often originals are last)
        return urls
    except Exception:
        return []


def download_url(session: requests.Session, url: str, dest_path: str):
    try:
        r = session.get(url, stream=True, timeout=30)
        r.raise_for_status()
        with open(dest_path, 'wb') as f:
            for chunk in r.iter_content(8192):
                if chunk:
                    f.write(chunk)
        return True
    except Exception as e:
        print(f"Failed to download {url}: {e}")
        return False


def collect_and_download(session: requests.Session, target: str, per_target: int, output_dir: str, delay: float, use_asset: bool):
    os.makedirs(output_dir, exist_ok=True)
    found = []
    page = 1
    while len(found) < per_target:
        j = get_search(session, target, page)
        items = j.get('collection', {}).get('items', [])
        if not items:
            break
        for item in items:
            # each item contains 'data' and possibly 'links'
            data = item.get('data', [{}])[0]
            title = data.get('title', '')
            description = data.get('description', '') or data.get('description_508', '') or ''
            # filter human-made
            if is_human_made(title) or is_human_made(description):
                continue

            # try to get candidate image urls
            urls = []
            links = item.get('links') or []
            for l in links:
                href = l.get('href')
                if href and IMG_EXT_RE.search(href):
                    urls.append(href)
            # if configured, try asset endpoint for higher-res
            nasa_id = data.get('nasa_id')
            if use_asset and nasa_id:
                asset_urls = get_asset_urls(session, nasa_id)
                if asset_urls:
                    urls.extend(asset_urls)

            # normalize and dedupe
            final_urls = []
            for u in urls:
                if u and u not in final_urls:
                    final_urls.append(u)

            for u in final_urls:
                if len(found) >= per_target:
                    break
                # save filename
                fname = sanitize_filename(u)
                dest = os.path.join(output_dir, fname)
                # avoid re-download if exists
                if os.path.exists(dest):
                    print(f"Already exists: {dest}")
                    found.append(dest)
                    continue
                ok = download_url(session, u, dest)
                if ok:
                    found.append(dest)
                time.sleep(delay)
        page += 1
        # safety: stop if too many pages
        if page > 50:
            break
    return found


def main():
    p = argparse.ArgumentParser(description='Download solar system images from NASA Images API (exclude human-made).')
    p.add_argument('--targets', nargs='+', default=['Sun','Mercury','Venus','Earth','Moon','Mars','Jupiter','Saturn','Uranus','Neptune','Ceres','Pluto','Eris','Haumea','Makemake'], help='List of targets to download')
    p.add_argument('--per-target', type=int, default=10, help='Number of images per target')
    p.add_argument('--output-dir', default='nasa_solar_system', help='Base output directory')
    p.add_argument('--delay', type=float, default=0.5, help='Delay between downloads (s)')
    p.add_argument('--use-asset', action='store_true', help='Use asset endpoint to try to fetch original images')
    p.add_argument('--user-agent', default='ImageDownloader/1.0', help='User-Agent header')
    args = p.parse_args()

    session = build_session(args.user_agent)

    results = {}
    for t in args.targets:
        safe_name = t.replace(' ', '_')
        folder = os.path.join(args.output_dir, safe_name)
        print(f"\n==> Collecting {args.per_target} images for: {t} -> {folder}")
        got = collect_and_download(session, t, args.per_target, folder, args.delay, args.use_asset)
        results[t] = got
        print(f"Collected {len(got)} images for {t}")

    # save metadata
    meta_path = os.path.join(args.output_dir, 'download_metadata.json')
    os.makedirs(args.output_dir, exist_ok=True)
    with open(meta_path, 'w', encoding='utf-8') as jf:
        json.dump(results, jf, indent=2)
    print(f"\nAll done. Metadata saved to {meta_path}")

if __name__ == '__main__':
    main()

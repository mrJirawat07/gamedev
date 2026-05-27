#!/usr/bin/env python3
"""
download_nasa_science_planet_images.py
Download representative NASA Science images for solar system bodies.
"""
import argparse
import os
import re
import time
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup

PLANET_PAGES = {
    'Sun': 'https://science.nasa.gov/sun/',
    'Mercury': 'https://science.nasa.gov/mercury/',
    'Venus': 'https://science.nasa.gov/venus/',
    'Earth': 'https://science.nasa.gov/earth/',
    'Moon': 'https://science.nasa.gov/moon/',
    'Mars': 'https://science.nasa.gov/mars/',
    'Jupiter': 'https://science.nasa.gov/jupiter/',
    'Saturn': 'https://science.nasa.gov/saturn/',
    'Uranus': 'https://science.nasa.gov/uranus/',
    'Neptune': 'https://science.nasa.gov/neptune/',
    'Ceres': 'https://science.nasa.gov/dwarf-planets/ceres/facts/',
    'Pluto': 'https://science.nasa.gov/dwarf-planets/pluto/facts/',
    'Haumea': 'https://science.nasa.gov/dwarf-planets/haumea/',
    'Makemake': 'https://science.nasa.gov/dwarf-planets/makemake/',
    'Eris': 'https://science.nasa.gov/dwarf-planets/eris/',
}
IMG_EXT_RE = re.compile(r"\.(?:jpg|jpeg|png|webp)(?:\?.*)?$", re.IGNORECASE)
LOGO_RE = re.compile(r'nasa[_-]?logo|logo.*nasa|nasa.*logo', re.IGNORECASE)
NASA_IMAGES_API = 'https://images-api.nasa.gov/search'


def build_session(user_agent: str = 'NASA-Science-Planet-Downloader/1.0'):
    s = requests.Session()
    s.headers.update({'User-Agent': user_agent})
    return s


def fetch_page(session: requests.Session, url: str, timeout: int = 15):
    r = session.get(url, timeout=timeout)
    r.raise_for_status()
    return r.text


def is_logo_image(url: str) -> bool:
    return bool(LOGO_RE.search(url))


def search_nasa_images(session: requests.Session, query: str):
    params = {'q': query, 'media_type': 'image'}
    try:
        r = session.get(NASA_IMAGES_API, params=params, timeout=15)
        r.raise_for_status()
        collection = r.json().get('collection', {})
        items = collection.get('items', [])
        for item in items:
            links = item.get('links', [])
            for link in links:
                href = link.get('href')
                if href and IMG_EXT_RE.search(href) and not is_logo_image(href):
                    return href
    except Exception:
        return None
    return None


def find_image_url(html: str, base_url: str, target: str):
    soup = BeautifulSoup(html, 'html.parser')
    # prefer og:image
    og = soup.find('meta', property='og:image')
    if og and og.get('content'):
        candidate = urljoin(base_url, og.get('content'))
        if not is_logo_image(candidate):
            return candidate
    twitter = soup.find('meta', attrs={'name': 'twitter:image'})
    if twitter and twitter.get('content'):
        candidate = urljoin(base_url, twitter.get('content'))
        if not is_logo_image(candidate):
            return candidate
    # fallback: first large image in page that's not a logo
    imgs = []
    for img in soup.find_all('img'):
        src = img.get('src') or img.get('data-src') or img.get('data-thumb')
        if not src:
            continue
        src = urljoin(base_url, src)
        if IMG_EXT_RE.search(src) and not is_logo_image(src):
            imgs.append(src)
    if imgs:
        return imgs[0]
    # fallback to NASA Images API search for target name
    return None


def sanitize_filename(url: str) -> str:
    parsed = urlparse(url)
    name = os.path.basename(parsed.path)
    if not name or '.' not in name:
        name = 'image' + str(hash(url)) + '.jpg'
    return name


def download_image(session: requests.Session, url: str, dest_path: str):
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    if os.path.exists(dest_path):
        print(f'Already exists: {dest_path}')
        return True
    try:
        r = session.get(url, stream=True, timeout=30)
        r.raise_for_status()
        with open(dest_path, 'wb') as f:
            for chunk in r.iter_content(8192):
                if chunk:
                    f.write(chunk)
        print(f'Downloaded: {dest_path}')
        return True
    except Exception as e:
        print(f'Failed to download {url}: {e}')
        return False


def main():
    p = argparse.ArgumentParser(description='Download NASA Science images for solar system bodies.')
    p.add_argument('--targets', nargs='+', default=list(PLANET_PAGES.keys()), help='Solar system bodies to download')
    p.add_argument('--output-dir', default='nasa_planet_science_images', help='Output directory')
    p.add_argument('--delay', type=float, default=0.5, help='Delay between requests')
    p.add_argument('--user-agent', default='NASA-Science-Planet-Downloader/1.0', help='User-Agent header')
    args = p.parse_args()

    session = build_session(args.user_agent)
    for target in args.targets:
        if target not in PLANET_PAGES:
            print(f'Skipping unknown target: {target}')
            continue
        url = PLANET_PAGES[target]
        print(f'\nFetching page for {target}: {url}')
        html = fetch_page(session, url)
        img_url = find_image_url(html, url, target)
        if not img_url:
            print(f'No valid page image found for {target}, searching NASA Images API...')
            img_url = search_nasa_images(session, target)

        if not img_url:
            print(f'No image found for {target} on {url} or via NASA Images API')
            continue

        folder = os.path.join(args.output_dir, target.replace(' ', '_'))
        filename = sanitize_filename(img_url)
        dest = os.path.join(folder, filename)
        download_image(session, img_url, dest)
        time.sleep(args.delay)
    print('\nDone.')

if __name__ == '__main__':
    main()

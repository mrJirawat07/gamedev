#!/usr/bin/env python3
"""
fetch_image_links.py
Extract image links (.jpg/.jpeg/.png) from a web page and optionally download them.
Usage example:
  python fetch_image_links.py "https://www.nasa.gov/multimedia/imagegallery" --max 30 --follow-pages --download --output nasa_images.txt
"""
import argparse
import os
import re
import time
import hashlib
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import urllib.robotparser as robotparser

IMG_EXT_RE = re.compile(r"\.(?:jpg|jpeg|png)(?:\?.*)?$", re.IGNORECASE)
URL_IN_STYLE_RE = re.compile(r'url\(([^)]+)\)', re.IGNORECASE)
URL_IN_TEXT_RE = re.compile(r'https?://[^\s\'"()<>]+(?:jpg|jpeg|png)(?:\?[^\s\'"()<>]*)?', re.IGNORECASE)


def build_session(user_agent: str, timeout: int = 10):
    s = requests.Session()
    s.headers.update({"User-Agent": user_agent})
    retries = Retry(total=3, backoff_factor=0.5, status_forcelist=[500,502,503,504])
    s.mount("https://", HTTPAdapter(max_retries=retries))
    s.mount("http://", HTTPAdapter(max_retries=retries))
    s.request_timeout = timeout
    return s


def can_fetch(url: str, ua: str) -> bool:
    parsed = urlparse(url)
    robots_url = f"{parsed.scheme}://{parsed.netloc}/robots.txt"
    rp = robotparser.RobotFileParser()
    try:
        rp.set_url(robots_url)
        rp.read()
        return rp.can_fetch(ua, url)
    except Exception:
        return True


def extract_images_from_soup(soup: BeautifulSoup, base_url: str):
    imgs = set()

    # <img> tags (src, data-src, data-original, srcset)
    for img in soup.find_all('img'):
        for attr in ('src', 'data-src', 'data-original'):
            val = img.get(attr)
            if val:
                parts = [p.strip() for p in val.split(',')] if ',' in val else [val]
                for p in parts:
                    url_part = p.split()[-1] if ' ' in p else p
                    url_part = url_part.strip().strip('\'"')
                    full = urljoin(base_url, url_part)
                    if IMG_EXT_RE.search(full) or URL_IN_TEXT_RE.search(full):
                        imgs.add(full)

        srcset = img.get('srcset')
        if srcset:
            for entry in srcset.split(','):
                url_candidate = entry.strip().split()[0]
                full = urljoin(base_url, url_candidate)
                if IMG_EXT_RE.search(full):
                    imgs.add(full)

    # <source> tags
    for s in soup.find_all('source'):
        src = s.get('src') or s.get('srcset')
        if src:
            for entry in (src.split(',') if ',' in src else [src]):
                url_candidate = entry.strip().split()[0]
                full = urljoin(base_url, url_candidate)
                if IMG_EXT_RE.search(full):
                    imgs.add(full)

    # meta tags (og:image, twitter:image)
    for meta in soup.find_all('meta'):
        if meta.get('property', '').lower() in ('og:image',) or meta.get('name', '').lower() in ('twitter:image',):
            content = meta.get('content')
            if content:
                imgs.add(urljoin(base_url, content))

    # inline style background-image
    for el in soup.find_all(style=True):
        style = el['style']
        for m in URL_IN_STYLE_RE.findall(style):
            candidate = m.strip(' \"\'')
            full = urljoin(base_url, candidate)
            if IMG_EXT_RE.search(full):
                imgs.add(full)

    # anchors pointing to images
    for a in soup.find_all('a', href=True):
        href = a['href']
        full = urljoin(base_url, href)
        if IMG_EXT_RE.search(full) or URL_IN_TEXT_RE.search(full):
            imgs.add(full)

    # plain text URLs in page
    text = soup.get_text()
    for m in URL_IN_TEXT_RE.findall(text):
        imgs.add(m)

    return imgs


def fetch_page(session: requests.Session, url: str, timeout: int = 10):
    resp = session.get(url, timeout=timeout)
    resp.raise_for_status()
    return resp.text


def scrape(start_url: str, max_links: int = 100, follow_pages: bool = False, delay: float = 0.5,
           user_agent: str = "Mozilla/5.0 (compatible; ImageScraper/1.0)") -> list:
    session = build_session(user_agent)
    found = []
    seen_pages = set()
    to_visit = [start_url]

    if not can_fetch(start_url, user_agent):
        print("robots.txt disallows fetching this URL. Aborting.")
        return []

    domain = urlparse(start_url).netloc

    while to_visit and len(found) < max_links:
        page = to_visit.pop(0)
        if page in seen_pages:
            continue
        seen_pages.add(page)

        try:
            html = fetch_page(session, page)
        except Exception as e:
            print(f"Failed to fetch {page}: {e}")
            continue

        soup = BeautifulSoup(html, 'html.parser')
        imgs = extract_images_from_soup(soup, page)

        for img in imgs:
            if len(found) >= max_links:
                break
            if img not in found:
                found.append(img)

        if follow_pages:
            for a in soup.find_all('a', href=True):
                href = urljoin(page, a['href'])
                parsed = urlparse(href)
                if parsed.netloc and domain in parsed.netloc and href not in seen_pages:
                    if IMG_EXT_RE.search(href):
                        continue
                    if any(k in href.lower() for k in ('image', 'gallery', 'photo', '/multimedia/', '/media/')):
                        to_visit.append(href)

        if delay:
            time.sleep(delay)

    return found


def sanitize_filename(url: str) -> str:
    path = urlparse(url).path
    name = os.path.basename(path)
    if not name or '.' not in name:
        # fallback to hash
        h = hashlib.sha1(url.encode('utf-8')).hexdigest()
        return f"image_{h}.jpg"
    # strip query strings
    name = name.split('?')[0]
    return name


def download_images(urls: list, dest_dir: str, session: requests.Session, timeout: int = 20):
    os.makedirs(dest_dir, exist_ok=True)
    downloaded = []
    for u in urls:
        try:
            resp = session.get(u, stream=True, timeout=timeout)
            resp.raise_for_status()
            fname = sanitize_filename(u)
            out_path = os.path.join(dest_dir, fname)
            # avoid overwriting by appending hash if exists
            if os.path.exists(out_path):
                h = hashlib.sha1(u.encode('utf-8')).hexdigest()[:8]
                base, ext = os.path.splitext(out_path)
                out_path = f"{base}_{h}{ext}"

            with open(out_path, 'wb') as f:
                for chunk in resp.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            downloaded.append(out_path)
            print(f"Downloaded: {out_path}")
        except Exception as e:
            print(f"Failed to download {u}: {e}")
    return downloaded


def main():
    p = argparse.ArgumentParser(description="Fetch image links (.jpg/.png) from a web page and optionally download them.")
    p.add_argument('url', help='Start URL to scrape')
    p.add_argument('--max', type=int, default=50, help='Maximum number of image links to collect')
    p.add_argument('--follow-pages', action='store_true', help='Follow gallery/item pages to find more images')
    p.add_argument('--delay', type=float, default=0.5, help='Delay between page requests (seconds)')
    p.add_argument('--user-agent', default='Mozilla/5.0 (compatible; ImageScraper/1.0)', help='User-Agent header')
    p.add_argument('--output', help='Output file to save links (one per line). If omitted, prints to stdout')
    p.add_argument('--download', action='store_true', help='Also download found images into ./downloads')
    p.add_argument('--dest', default='downloads', help='Destination folder when using --download')
    args = p.parse_args()

    print(f"Connecting to {args.url} and scraping images (max={args.max})...")
    imgs = scrape(args.url, max_links=args.max, follow_pages=args.follow_pages, delay=args.delay, user_agent=args.user_agent)

    if not imgs:
        print("No image links found.")
        return

    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            for u in imgs:
                f.write(u + "\n")
        print(f"Saved {len(imgs)} links to {args.output}")
    else:
        print(f"Found {len(imgs)} image links:\n" + "-"*40)
        for i, u in enumerate(imgs, 1):
            print(f"[{i}] {u}")

    if args.download:
        session = build_session(args.user_agent)
        print(f"\nStarting download of {len(imgs)} images into '{args.dest}' ...")
        downloaded = download_images(imgs, args.dest, session)
        print(f"Downloaded {len(downloaded)} files to {args.dest}")


if __name__ == '__main__':
    main()

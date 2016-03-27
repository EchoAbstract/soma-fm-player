import urllib2

from bs4 import BeautifulSoup
from collections import defaultdict


def fetch_html():
    resp = urllib2.urlopen("http://somafm.com/listen/")
    html = resp.read()
    return html


def make_soup(ingredients):
    return BeautifulSoup(ingredients, 'html.parser')


def get_stations(soup):
    stations = []
    for station in soup.find_all('h3'):
        if station.get('class') != None:
            break
        print("Found station: " + station.text)
        stations.append(station.text)
    return stations


def get_image_urls(soup, stations):
    root_url = "http://www.somafm.com"
    image_count = len(stations)
    images_urls = []
    for icon in soup.find_all('img'):
        if not icon["src"].endswith("LoneDJsquare400.jpg"):
            if image_count != 0:
                images_urls.append(root_url + icon["src"])
                image_count = image_count - 1
    return images_urls


preferred_playlist_order = ["130", "64", "256", "320", "192", "32", ""]


def get_playlist_shortname(pl):
    last_bit = pl.split("/")[-1]
    basename = last_bit.replace(".pls", "")
    
    for suffix in preferred_playlist_order:
        if basename.endswith(suffix):
            return basename.replace(suffix, "")

    
    

def get_playlist_urls(soup):
    root_url = "https://somafm.com"
    handled = defaultdict(bool)
    playlist_urls = []
    
    for link in soup.find_all("a"):
        if not link.get('href'):
            next

        url = link['href']        
        if url.endswith('.pls'):
            # Have we seen this yet?
            short_name = get_playlist_shortname(url)
            if not handled[short_name]:
                if not url.startswith(root_url):
                    url = root_url + url
                playlist_urls.append(url)
                handled[short_name] = True
    return playlist_urls


def download_images(imgs, out_dir):
    for img in imgs:
        filename = img.split("/")[-1]
        filename = out_dir + "/" + filename
        with open(filename, 'wb') as f:
            f.write(urllib2.urlopen(img).read())
        
        

if __name__ == "__main__":
    html = fetch_html()
    soup = make_soup(html)
    station_list = get_stations(soup)
    
    imgs = get_image_urls(soup, station_list)
    urls = get_playlist_urls(soup)
    
    download_images(imgs, "./img_tmp")

    for i in range(0, len(station_list)):
        icon_name = imgs[i].split("/")[-1]
        icon_name = icon_name.split(".")[0]
        prefix = '[StationInfo '
        prefix = prefix + 'stationInfoForStationNamed:@"' +station_list[i] + '" '
        prefix = prefix + 'withPlaylistLocation:@"' + urls[i] + '" '
        prefix = prefix + 'withShortKey:@""'
        prefix = prefix + 'withIconNamed:@"' + "rounded_" + icon_name + '" '
        prefix = prefix + 'atSortOrder:50],'

        print(prefix)
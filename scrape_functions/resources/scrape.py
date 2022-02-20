import requests
import validators
import requests
from bs4 import BeautifulSoup
import datetime

class Listing:
    
    def __init__(self, url):
        assert validators.url(url), "You did not provide a valid URL."
        self.url = url
        self.raw = requests.get(url)
        self.page = BeautifulSoup(self.raw.text, 'html5lib')
        

    def __repr__(self):
        return f'Listing at {self.url}'

    def __check_status(self):
        return False if len(self.page.select('.ExpiredListingContent-badge')) > 0 else True

    def __assert_get_text(self, selector, n, property_name, soft = False):
        if soft:
            # Scrape the page, but set this element to None.
            if self.page.select(selector) == []:
                return None
            else:
                if len(self.page.select(selector)) < n:
                    return None
            
        else:
            # Don't scrape the page if this element is missing
            assert self.page.select(selector), f"{property_name.capitalize()} element does not exist. Selector returns no elements."
            assert len(self.page.select(selector)) > n, f"{property_name.capitalize()} element does not exist. Selector doesn't have element {n}."
        
        return self.page.select(selector)[n].get_text()

    def __parse_title(self):
        # Title
        title = self.__assert_get_text('.Listing-title', 0, 'title')
        assert len(title) > 0, "The title of the listing is zero characters." 
        return title
    
    def __parse_price(self):
        price = self.__assert_get_text('.Listing-root .Listing-price', 0, 'price')
        if price == 'N.o.t.k.':
            price = None
        else:
            price = price.replace('€', '').replace(',','.')
            price = price.strip()
            price = float(price)
        return price
    
    def __parse_list_date(self):  
        list_date = self.__assert_get_text('.Stats-root .Stats-stat > .Stats-summary', 2, 'list date')
        list_date = list_date.replace('sinds', '')
        list_date = list_date.strip()
        if list_date[1] == ' ':
            # If first 9 days of the month, there is no leading zero for the day number.
            list_date = f'0{list_date}'
        
        list_day = list_date[:2]
        list_month = {
            'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04', 'mei': '05', 'jun': '06', \
            'jul': '07', 'aug': '08', 'sep': '09', 'okt': '10', 'nov': '11', 'dec': '12'
        }[list_date[3:6]]
        list_year = list_date[-9:-7]

        return f'20{list_year}-{list_month}-{list_day}'
    
    def __parse_stats(self):
        n_views = self.__assert_get_text('.Stats-root .Stats-stat > .Stats-summary', 0, 'number of views')
        n_hearts = self.__assert_get_text('.Stats-root .Stats-stat > .Stats-summary', 1, 'number of hearts')
        return n_views, n_hearts
    
    def __parse_delivery_info(self):
        delivery_methods = self.__assert_get_text('.ShippingInformation-deliveryLabel', 0, 'delivery methods', soft = True)
        if delivery_methods is not None:
            delivery_methods = delivery_methods.lower()
            method_pickup = 'ophalen' in delivery_methods
            method_send = 'verzenden' in delivery_methods
        else:
            method_pickup = None
            method_send = None
        send_price = self.__assert_get_text('.ShippingInformation-shipping', 0, 'shipping price', soft = True) 
        send_price = None if send_price == '' else send_price
        send_price = float(send_price.replace('€\xa0','').replace(',','.')) if send_price is not None else send_price
        return method_pickup, method_send, send_price
    
    def __scrape(self):
        if self.__check_status():
            print('Listing is active. Scraping.')
            self.title = self.__parse_title()
            self.price = self.__parse_price()
            self.n_views, self.n_hearts = self.__parse_stats()
            self.list_date = self.__parse_list_date()
            self.pickup, self.send, self.send_price = self.__parse_delivery_info()
            self.is_active = True
        else:
            self.title = self.price = self.n_views = self.n_hearts = self.list_date = self.pickup = self.send = self.send_price = None
            self.is_active = False
            print('Listing is inactive. Not scraping.')    
    pass

    def get_dict(self):
        self.__scrape()
        return {
            'scrape_time': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'title': self.title,
            'price': self.price,
            'n_views': self.n_views,
            'n_hearts': self.n_hearts,
            'list_date': self.list_date,
            'pickup': self.pickup,
            'send': self.send,
            'send_price': self.send_price,
            'is_active': self.is_active
        }

if __name__ == "__main__":
    url = 'https://www.2dehands.be/v/telecommunicatie/mobiele-telefoons-apple-iphone/m1797547157-iphone-12-pro-128gb'
    p = Listing(url)
    print(p.get_dict())

    url = 'https://www.2dehands.be/v/telecommunicatie/mobiele-telefoons-apple-iphone/a75770653-apple-iphone-11-red'
    p = Listing(url)
    print(p.get_dict())
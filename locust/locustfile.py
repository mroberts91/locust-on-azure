from locust import HttpUser, TaskSet, task, between
import random

class APICalls(TaskSet):    
    anhelo_urls = [
        "/",
        "/gracias",
        "/guia",
        "/formulario",
        "/nosotros",
        "/aseguradoras",
        "/privacidad",
        "/condiciones",
        "/newsletter-confirmation",
        "/planes",
        "/inicio-medicare",
    ]
    cp_urls = [
        "/",
        "/form?afid=12345&src=test",
        "/thank-you",
        "/price",
        "/not-available"
    ]
    headers = {
        "User-Agent":"Mozilla/5.0 tzt-loadtestbot (Windows NT 10.0; Win64; x64; rv:71.0) Gecko/20100101 Firefox/89.1",
    }

    @task(9)
    def get_anhelo(self):
        url = self.__get_url(self.anhelo_urls)
        # url = f"/anhelosalud{self.__get_url(self.anhelo_urls)}"
        
        if url is None:
            url = "/anhelosalud"

        self.client.get(url, headers=self.headers)

    # @task(1)
    # def get_cp(self):
    #     url =  f"/colonial-penn{self.__get_url(self.cp_urls)}"
        
    #     if url is None:
    #         url = "/colonial-penn"

    #     self.client.get(url, headers=self.headers)

    def __get_url(self, urls):
        return urls[random.randint(0, len(urls))]

class APIUser(HttpUser):
    tasks = [APICalls]
    wait_time = between(2, 3.5)
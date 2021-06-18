from locust import TaskSet, task, between
from locust.contrib.fasthttp import FastHttpUser
import random

class APICalls(TaskSet):    
    get_urls = [
        "/",
        "/gracias",
        "/guia",
        "/formulario",
        "/nosotros",
        "/aseguradoras",
        "/privacidad",
        "/condiciones",
        "/newsletter-confirmation",
        "/authors",
        "/authors/denira-borrero",
        "/authors/daniela-agurcia",
        "/authors/sofia-de-la-guardia",
        "/authors/sheyla-benitez",
        "/authors/ivan-ruiz",
        "/authors/lina-manchola",
        "/authors/jose-rodriguez",
        "/authors/emily-love",
        "/authors/jessica-martinez",
        "/authors/mery-andrea-lopez",
        "/planes",
        "/inicio-medicare"
    ]

    @task()
    def geturl(self):
        url = self.get_urls[random.randint(0, len(self.get_urls))]
        if url is None:
            url = "/"
        self.client.get(url)
    # @task()
    # def postpost(self):        
    #     self.client.post("/posts", {"title": "foo", "body": "bar", "userId": 1}, name="/posts")

class APIUser(FastHttpUser):
    tasks = [APICalls]
    wait_time = between(2, 3.5) # seconds
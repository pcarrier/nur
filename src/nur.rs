use io::{stderr, stdin, stdout};
use std::error::Error;
use std::io;
use std::io::{Read, Stderr, Stdin, Stdout, Write};

use http_cache_reqwest::{CACacheManager, Cache, CacheMode, HttpCache};
use reqwest::{Client, StatusCode};
use reqwest_middleware::{ClientBuilder, ClientWithMiddleware};
use rquickjs::{Context, Func, Runtime};
use url::Url;

pub(crate) struct Nur {
    url: Url,
    rt: Runtime,
    client: ClientWithMiddleware,
    stdin: Stdin,
    stdout: Stdout,
    stderr: Stderr,
}

impl Nur {
    pub(crate) fn new(url: Url) -> Result<Self, Box<dyn Error>> {
        let client = ClientBuilder::new(Client::new())
            .with(Cache(HttpCache {
                mode: CacheMode::Default,
                manager: CACacheManager {
                    path: dirs::cache_dir()
                        .and_then(|p|
                            p.join("tools.nur")
                                .into_os_string().into_string().ok())
                        .unwrap_or_else(|| ".tools.nur/cache".to_string())
                },
                options: None,
            }))
            .build();

        let rt = Runtime::new()?;

        Ok(Self {
            url,
            rt,
            client,
            stdin: stdin(),
            stdout: stdout(),
            stderr: stderr(),
        })
    }

    async fn fetch(&self, url: Url) -> Result<String, Box<dyn Error>> {
        let res = self.client.get(url)
            .send()
            .await?;
        if res.status() != StatusCode::OK {
            return Err(format!("fetch failed: {}", res.status()).into());
        }
        Ok(res.text().await?)
    }

    async fn fetch_js(&self, url: Url) -> Result<String, Box<dyn Error>> {
        if url.scheme() == "file" {
            return Ok(std::fs::read_to_string(url.path())?);
        }

        let mut decorated = url.clone();
        decorated.query_pairs_mut().append_pair("nur-get", "1");
        self.fetch(decorated).await
    }

    fn print(&mut self, msg: String) -> Result<(), Box<dyn Error>> {
        self.stdout.write(msg.as_bytes())?;
        self.stdout.flush()?;
        Ok(())
    }

    fn full_stdin(mut self) -> Result<String, Box<dyn Error>> {
        let mut str = String::new();
        self.stdin.read_to_string(&mut str)?;
        Ok(str)
    }

    pub(crate) async fn run(&mut self) -> Result<(), Box<dyn Error>> {
        let code = self.fetch_js(self.url.clone()).await?;
        let ctx = Context::full(&self.rt)?;
        ctx.with(move |ctx| -> Result<(), Box<dyn Error>> {
            let globals = ctx.globals();
            globals.set("print", Func::new("print", |v| self.print(v).unwrap()))?;
            globals.set("full_stdin", Func::new("full_stdin", || self.full_stdin().unwrap()))?;
            ctx.compile(self.url.to_string(), code)?;
            Ok(())
        })
    }
}

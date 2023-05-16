use std::{env, io};
use std::error::Error;
use std::io::Read;

use http_cache_reqwest::{CACacheManager, Cache, CacheMode, HttpCache};
use reqwest::Client;
use reqwest_middleware::ClientBuilder;
use rquickjs::{Context, Func, Runtime};
use url::{ParseError, Url};

#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

fn print(msg: String) {
    println!("{msg}");
}

fn full_stdin() -> String {
    let mut str = String::new();
    io::stdin().read_to_string(&mut str).unwrap();
    str
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let url = env::args().nth(1).and_then(|s| derive_url(s).ok())
        .unwrap_or(Url::parse("https://nur.tools/badurl").unwrap());

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

    let body = client.get(url.clone())
        .header("User-Agent", "nur")
        .send()
        .await?
        .text()
        .await?;

    let rt = Runtime::new()?;
    let ctx = Context::full(&rt)?;

    ctx.with(|ctx| -> Result<(), Box<dyn Error>> {
        let globals = ctx.globals();
        globals.set("print", Func::new("print", print))?;
        globals.set("full_stdin", Func::new("full_stdin", full_stdin))?;
        ctx.compile(url.to_string(), body)?;
        Ok(())
    })
}

fn derive_url(short: String) -> Result<Url, ParseError> {
    if short.starts_with("@") {
        return Url::parse("https://nur.tools")?.join(&short[1..]);
    }
    if short.starts_with("http://") || short.starts_with("https://") {
        return Url::parse(&short);
    }
    Url::parse(format!("https://{short}").as_str())
}
